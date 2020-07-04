import nico
import nico/vec
import nico/gui
import fileexplorer
import strformat, tables, strutils,os
import shape
import math
export shape

type
  States = enum
    caDrawing,caEditing,caNothing, caLoadPalette, caLoadNvg

var
  selColor = 1
  selTool = skPoly
  shapes : Nvg
  currentState = caNothing
  drawingSteps = 0
  currentShape = 0
  showColour = false

const
  toolSprites : Table[ShapeKind,int]= { skPoly : 1,
  skQuad : 5,
  skLine : 2,
  skBezier : 3,
  skCircle : 4,
  skRect : 0}.toTable()
  toolNames: Table[ShapeKind, string]= {skPoly : "Polygon",
  skQuad : "Quad",
  skLine : "Line",
  skBezier : "Bezier",
  skCircle : "Circle",
  skRect : "Rect"}.toTable()

proc mouse(): (int,int)= (nico.mouse()[0] + cameraX, nico.mouse()[1] + cameraY)

proc gameInit() =
  #setPalette(loadPaletteFromGPL("palette.gpl"))
  loadFont(0, "font.png")
  loadSpriteSheet(0,"sprites.png",16,16)

proc isDrawing():bool = currentState == caDrawing

proc toolGui()=
  var
    x: Pint = screenWidth - (toolSprites.len) * 20 + cameraX
    y: Pint = screenHeight - 20 + cameraY
    w: Pint = (toolSprites.len + 1) * 19
    h: Pint = 20
  G.beginArea(x,y,w,h, gLeftToRight,true, false)
  for x in ShapeKind:
    setColor(4)
    G.area.cursorY -= 1
    if(G.button("",18,19) and currentState != caDrawing):
      selTool = x
    G.area.cursorX -= 19
    G.area.cursorY += 1
    G.ssprite(toolSprites[x],16,16,1,1)
  G.endArea()

proc shapeGui()=
  if(currentState != caEditing): return
  var
    x: Pint = cameraX
    y: Pint = screenHeight - 80 + cameraY
    w: Pint = 80
    h: Pint = 80
    shape = shapes[currentShape]
  G.beginArea(x,y,w,h, gTopToBottom, true, false)
  #G.label(toolNames[shape.kind])
  case shape.kind:
  of skCircle:
    discard G.drag("X", shape.pos.x, int32.low, int32.high, 1f)
    discard G.drag("Y", shape.pos.y, int32.low, int32.high, 1f)
    discard G.drag("Radius", shape.radius, 0, int32.high, 1)
  of skLine:
    discard G.drag("X1", shape.pos.x, int32.low, int32.high, 1f)
    discard G.drag("Y1", shape.pos.y, int32.low, int32.high, 1f)
    discard G.drag("X2", shape.point2.x, int32.low, int32.high, 1f)
    discard G.drag("Y2", shape.point2.y, int32.low, int32.high, 1f)
  of skPoly:
    discard G.drag("X", shape.pos.x, int32.low, int32.high, 1f)
    discard G.drag("Y", shape.pos.y, int32.low, int32.high, 1f)
    discard G.drag("Radius", shape.width, int32.low, int32.high, 1f)
    discard G.drag("Sides", shape.sides, 3, 32, 1f)
    discard G.drag("Rot", shape.rot, float32.low, float32.high, PI/180f)
  of skQuad:
    discard G.drag("X1", shape.pos.x, int32.low, int32.high, 1f)
    discard G.drag("Y1", shape.pos.y, int32.low, int32.high, 1f)
    discard G.drag("X2", shape.p2.x, int32.low, int32.high, 1f)
    discard G.drag("Y2", shape.p2.y, int32.low, int32.high, 1f)
    discard G.drag("X3", shape.p3.x, int32.low, int32.high, 1f)
    discard G.drag("Y3", shape.p3.y, int32.low, int32.high, 1f)
    discard G.drag("X4", shape.p4.x, int32.low, int32.high, 1f)
    discard G.drag("Y4", shape.p4.y, int32.low, int32.high, 1f)
  of skRect:
    discard G.drag("X", shape.pos.x, int32.low, int32.high, 1f)
    discard G.drag("Y", shape.pos.y, int32.low, int32.high, 1f)
    discard G.drag("Width", shape.rWidth, 0, int32.high, 1f)
    discard G.drag("Height", shape.rHeight, 0, int32.high, 1f)
  else: discard

  shapes[currentShape] = shape
  G.endArea()

proc colorGui()=
  var
    x:Pint = cameraX
    y:Pint = cameraY
    w:Pint = 120
    perRow = 11
    h:Pint = 20 + (getPalette().size.div(perRow) + 1) * 12

  if(G.beginWindow("Color", x, y, w, h, showColour)):
    let 
      fillColour = G.colorSets[gDefault].fill
      hoverColour = G.colorSets[gDefault].fillHover
    for i in 0..<getPalette().size:
      if(i.mod(w/perRow - 1) == 0):
        if(i > 0): G.endArea()
        G.beginHorizontal(12)

      G.colorSets[gDefault].fill = i
      G.colorSets[gDefault].fillHover = i
      if(G.button(" ",10,10)):
        selColor = i
        if(currentState != caNothing): shapes[currentShape].color = i

    G.colorSets[gDefault].fill = fillColour
    G.colorSets[gDefault].fillHover = hoverColour
    G.endArea()
    G.endArea()

proc shapeLayers()=
  var
    x: Pint = screenWidth - 40 + cameraX
    y: Pint = screenHeight - 150 + cameraY
    w: Pint = 40
    h: Pint = 130
  G.beginArea(x,y,w,h, gTopToBottom,true, false)
  for x in 0..<shapes.len:
    if(G.button(toolNames[shapes[x].kind], (x != currentShape), K_t)):
      currentState = caEditing
      currentShape = x
  G.endArea()

proc loadPalette(path : string)=
  if(path.splitFile.ext != ".gpl"): 
    echo "Not a proper pallete"
  else:
    loadPaletteFromGPL(path.relativePath(assetPath)).setPalette
    currentState = caNothing

proc fileGui()=
  G.beginArea(180 + cameraX, cameraY, 19 * 4, 24, gLeftToRight, true)
  if(G.button("",18,18)):
    echo "save"
  G.area.cursorX -= 19
  G.area.cursorY += 1
  G.sprite(6)
  G.area.cursorY -= 1
  if(G.button("",18,18)):
    currentState = caLoadNvg
  G.area.cursorX -= 19
  G.area.cursorY += 1
  G.sprite(7)
  G.area.cursorY -= 1
  if(G.button("",18,18)):
    currentState = caLoadPalette
  G.area.cursorX -= 19
  G.area.cursorY += 1
  G.sprite(8)
  G.endArea()

proc gameGui()=
  toolGui()
  shapeLayers()
  shapeGui()
  colorGui()
  fileGui()
  if(currentState == caLoadPalette):
    let file = fileexplorer("Choose Palette")
    if(not file.isEmptyOrWhitespace):
      loadPalette(file)
  elif(currentState == caLoadNvg):
    let file = fileexplorer("Choose Nvg")
    if(not file.isEmptyOrWhitespace):
      let temp = loadNvg(file,false)
      if(temp.len > 0): 
        shapes = temp
        currentShape = temp.len
      currentState = caNothing

proc gameUpdate(dt: float32) = 
  let overUI = (G.hoverElement > 0)
  G.update(gameGui, dt)
  
  if(mousebtn(1)):
    setCamera(cameraX - mouserel()[0].int32, cameraY - mouserel()[1].int32)

  let mouse = mouse()

  if(mousebtn(2)):
    case currentState:
    of caDrawing:
      currentState = caNothing
      shapes.del(shapes.high)
    of caEditing:
      currentState = caNothing
      currentShape = shapes.len
    else: discard

  if(isDrawing() and shapes[currentShape].kind == skPoly):
    shapes[currentShape].sides += mousewheel()
    shapes[currentShape].sides = clamp(shapes[currentShape].sides,3,32)

  if(currentState == caEditing):
    if(btnpr(pcUp) and currentShape > 0 ):
      let temp = shapes[currentShape]
      shapes[currentShape] = shapes[currentShape - 1]
      shapes[currentShape - 1] = temp
      dec currentShape
    if(btnpr(pcDown) and currentShape < shapes.high):
      let temp = shapes[currentShape]
      shapes[currentShape] = shapes[currentShape + 1]
      shapes[currentShape + 1] = temp
      inc currentShape

  if(key(K_s)): shapes.saveNvg("test.nvg")
  if(key(K_p)): currentState = caLoadNvg
  if(key(K_MINUS)): 
    shapes.setLen(0)
    currentShape = 0
  if(key(K_EQUALS)):
    loadPalettePico8().setPalette()

  if(mousebtnpr(0,100) and not overUI):
    case currentState:
    of caNothing:
      var used = true
      case selTool:
      of skLine:
        shapes.add(Shape(kind : skLine, pos : vec2i(mouse[0], mouse[1]),color : selColor))
      of skCircle:
        shapes.add(Shape(kind : skCircle, pos : vec2i(mouse[0], mouse[1]), color : selColor))
      of skQuad:
        shapes.add(Shape(kind : skQuad, pos : vec2i(mouse[0], mouse[1]), color : selColor))
      of skPoly:
        shapes.add(Shape(kind : skPoly, pos : vec2i(mouse[0], mouse[1]), color : selColor))
      of skRect:
        shapes.add(Shape(kind : skRect, pos : vec2i(mouse[0], mouse[1]), color : selColor))
      else: used = false
      if(used):
        drawingSteps = 0
        currentState = caDrawing
    of caDrawing:
      var shapeDone = false
      case shapes[currentShape].kind:
      of skLine:
        shapes[currentShape].point2 = vec2i(mouse[0],mouse[1])
        shapeDone = true
      of skCircle:
        shapes[currentShape].radius = sqrt(pow(abs((shapes[currentShape].pos.x - mouse[0]).float32),2) + pow(abs((shapes[currentShape].pos.y - mouse[1]).float32),2))
        shapeDone = true
      of skPoly:
        shapes[currentShape].width = sqrt(pow(abs((shapes[currentShape].pos.x - mouse[0]).float32),2) + pow(abs((shapes[currentShape].pos.y - mouse[1]).float32),2))
        shapes[currentShape].rot = arctan2((mouse[1] - shapes[currentShape].pos.y).float32, (mouse[0] - shapes[currentShape].pos.x).float32)
        shapeDone = true
      of skQuad:
        case drawingSteps:
        of 0: shapes[currentShape].p2 = vec2i(mouse[0],mouse[1])
        of 1: shapes[currentShape].p3 = vec2i(mouse[0],mouse[1])
        of 2:
          shapes[currentShape].p4 = vec2i(mouse[0],mouse[1])
          shapeDone = true
        else: discard
        inc drawingSteps
      of skRect:
        shapes[currentShape].rWidth = abs(mouse()[0].float32 - shapes[currentShape].pos.x)
        shapes[currentShape].rHeight = abs(mouse()[1].float32 - shapes[currentShape].pos.y)
        shapes[currentShape].rRot = arctan2((mouse()[1].float32 - shapes[currentShape].pos.y).float32, (mouse()[0].float32 - shapes[currentShape].pos.x).float32)
        shapeDone = true
      else: discard
      if(shapeDone):
        currentState = caNothing
        inc currentShape
    of caEditing:
      currentState = caNothing
      currentShape = shapes.len
    else: discard

proc drawDrawingShape(x : Shape)=
  setColor(x.color)
  let mouse = mouse()
  case x.kind:
  of skLine:
    circfill(x.pos.x,x.pos.y,2)
    line(x.pos.x,x.pos.y,mouse[0],mouse[1])
  of skCircle:
    let dist = sqrt(pow(abs((shapes[currentShape].pos.x - mouse[0].float32).float32),2) + pow(abs((shapes[currentShape].pos.y - mouse[1].float32).float32),2))
    circfill(x.pos.x,x.pos.y,2)
    circ(x.pos.x,x.pos.y, dist)
  of skQuad:
    circfill(x.pos.x,x.pos.y,2)
    if(drawingSteps == 0):
      line(x.pos.x,x.pos.y,mouse[0],mouse[1])
    if(drawingSteps >= 1):
      circfill(x.p2.x,x.p2.y,2)
      line(x.pos.x,x.pos.y,x.p2.x,x.p2.y)
      if(drawingSteps == 1): line(x.p2.x,x.p2.y,mouse[0],mouse[1])
    if(drawingSteps >= 2):
      circfill(x.p3.x,x.p3.y,2)
      line(x.p2.x,x.p2.y,x.p3.x,x.p3.y)
      line(x.p3.x,x.p3.y,mouse[0],mouse[1])
      line(x.pos.x,x.pos.y,mouse[0],mouse[1])
  of skPoly:
    let
      theta = arctan2((mouse[1].float32 - x.pos.y).float32, (mouse[0].float32 - x.pos.x).float32)
      width = dist(x.pos.vec2f,vec2f(mouse[0],mouse[1]))
      point = rotate(vec2f(width,0),theta)
      rot = TAU / x.sides.float32
    circfill(x.pos.x,x.pos.y,2)
    for p in 0..<x.sides:
      let
        this = rotate(point, rot * p.float32).vec2i + x.pos
        next = rotate(point,rot * (p + 1).float32).vec2i + x.pos
      line(this.x, this.y, next.x, next.y)
  of skRect:
    let
      mag = dist(shapes[currentShape].pos.vec2f, vec2f(mouse()[0],mouse()[1]))
      theta = arctan2((mouse()[1].float32 - x.pos.y).float32, (mouse()[0].float32 - x.pos.x).float32)
      width = abs(cos(theta) * mag).int32
      height = abs(sin(theta) * mag).int32
      a = vec2i(width, height) + x.pos
      b = vec2i(-width, height) + x.pos
      c = vec2i(-width, -height) + x.pos
      d = vec2i(width, -height) + x.pos
    lineDashed(a.x,a.y,b.x,b.y)
    lineDashed(b.x,b.y,c.x,c.y)
    lineDashed(c.x,c.y,d.x,d.y)
    lineDashed(d.x,d.y,a.x,a.y)
    lineDashed(x.pos.x, x.pos.y, mouse()[0], mouse()[1])

  else: discard

proc drawEditingShape(x : Shape)=
  setColor(x.color)
  case x.kind:
  of skLine:
    circfill(x.pos.x,x.pos.y, 3)
    circfill(x.point2.x, x.point2.y, 3)
    lineDashed(x.pos.x,x.pos.y,x.point2.x,x.point2.y)
  of skCircle:
    circ(x.pos.x,x.pos.y,x.radius)
  of skQuad:
    circfill(x.pos.x,x.pos.y,3)
    circfill(x.p2.x,x.p2.y,3)
    circfill(x.p3.x,x.p3.y,3)
    circfill(x.p4.x,x.p4.y,3)
    lineDashed(x.pos.x,x.pos.y,x.p2.x,x.p2.y)
    lineDashed(x.p2.x,x.p2.y,x.p3.x,x.p3.y)
    lineDashed(x.p3.x,x.p3.y,x.p4.x,x.p4.y)
    lineDashed(x.p4.x,x.p4.y,x.pos.x,x.pos.y)
  of skPoly:
    let
      point = rotate(vec2f(x.width,0),x.rot)
      rot = TAU / x.sides.float32
    for p in 0..<x.sides:
      let
        this = rotate(point, rot * p.float32).vec2i + x.pos
        next = rotate(point,rot * (p + 1).float32).vec2i + x.pos
      lineDashed(this.x,this.y,next.x,next.y)
      circfill(this.x,this.y,3)
  of skRect:
    let
      a = vec2i(x.rWidth, x.rHeight) + x.pos
      b = vec2i(-x.rWidth, x.rHeight) + x.pos
      c = vec2i(-x.rWidth, -x.rHeight) + x.pos
      d = vec2i(x.rWidth, -x.rHeight) + x.pos
      
    lineDashed(a.x,a.y,b.x,b.y)
    lineDashed(b.x,b.y,c.x,c.y)
    lineDashed(c.x,c.y,d.x,d.y)
    lineDashed(d.x,d.y,a.x,a.y)
  else: discard

proc drawShapes()=
  for i,x in shapes:
    if(i != currentShape or currentState == caNothing):
      x.drawShape
  if(currentState in {caEditing, caDrawing}):
    shapes[currentShape].color.setColor()
    case currentState:
    of caDrawing:
      shapes[currentShape].drawDrawingShape
    of caEditing:
      shapes[currentShape].drawEditingShape
    else: discard

proc gameDraw() =
  cls()
  drawShapes()
  G.draw(gameGui)

nico.init("myOrg", "myApp")
nico.createWindow("myApp", 256, 256, 2, false)
nico.run(gameInit, gameUpdate, gameDraw)