import nico
import nico/gui
import os, sequtils
var
    x: Pint = cameraX
    y: Pint = cameraY
    w: Pint = screenWidth
    h: Pint = screenHeight 
    show = true
    currentPath = ""
    page = 0
    pageCount = 0
    toDisplay = 0
    paths : seq[tuple[kind: PathComponent, path: string]]

proc recalcSpace()=
    h = clamp(h,64,int32.high)
    toDisplay = h.div(16) - 3
    pageCount = paths.len.div(toDisplay)
    if(page >= pageCount): page = pageCount

proc changeDir(newDir : string)=
    page = 0
    currentPath = newDir
    paths = toSeq(walkDir(currentPath))
    recalcSpace()

proc fileExplorer*(title : string) : string=
    x = cameraX
    y = cameraY
    if(G.beginWindow(title,x,y,w,h,show)):
        G.beginVertical(h)
        G.beginHorizontal(16)
        if(G.button("..")): changeDir(splitPath(currentPath).head)
        G.endArea()
        for i in 0..toDisplay:
            if(i + page * toDisplay >= paths.len):break
            let file = paths[i + page * toDisplay]
            if(G.area.cursorY + 32 >= h + y): break
            G.beginHorizontal(16)
            if(G.button(file.path.splitPath.tail)):
                if(file.kind == pcDir): changeDir(file.path)
                else: result = file.path
            G.endArea()
        
        if(pageCount > 0):
            G.area.cursorY = y + h - 20
            G.hExpand = true
            discard G.slider("Page", page, 0, pageCount, w - 10, 16)
            G.hExpand = false

        G.endArea()
        G.endArea()
        recalcSpace()

changeDir(absolutePath("./"))