import ../src/shape
import nico, math

var 
    nvg: Nvg
    scale:float32 = 0.5 

proc init() =
  setCamera(0, 0)
  nvg = loadNvg("Test.nvg",true,scale)

proc update(dt: Pfloat) = 
    if(key(K_MINUS)):
        scale -= dt
        nvg = loadNvg("Test.nvg",true,scale)
    if(key(K_EQUALS)):
        scale += dt
        nvg = loadNvg("Test.nvg",true,scale)



proc draw() =
  cls()
  nvg.drawNvg(mouse()[0],mouse()[1])


nico.init("Nico","Overlap")

nico.createWindow("nico",128,128,4,false)

loadFont(0,"font.png")
setFont(0)
fixedSize(true)
integerScale(true)

nico.run(init,update,draw)