import nico/vec
import nico
import json
import os

proc `*`(a : int32, b: float32):int32 = (a.float32 * b).int32
proc `*=`(a : var int32, b: float32)= a = (a.float32 * b).int32

type
  ShapeKind* = enum
    skPoly,
    skQuad,
    skLine,
    skBezier,
    skCircle,
    skRect
  
  Shape* = object
    pos* : Vec2i
    color* : int32
    case kind* : ShapeKind
    of skPoly:
      sides*: int32
      width*: int32
      rot*: float32
    of skQuad:
      p2*,p3*,p4* : Vec2i
    of skLine:
      point2* : Vec2i
    of skBezier:
      b*,c*,d*: Vec2i
    of skCircle:
      radius* : int32
    of skRect:
      rWidth* ,rHeight*: int32
      rRot*: float32
  Nvg* = seq[Shape]

proc drawShape*(s : Shape, x, y: int32 = 0, rot : float32 = 0)=
  var pos = vec2i(x,y)
  setColor(s.color)
  case s.kind:
  of skLine:
    let
        newP1 = s.pos.vec2f.rotate(rot).vec2i + pos
        newP2 = s.point2.vec2f.rotate(rot).vec2i + pos
    line(newP1.x, newP1.y, newP2.x, newP2.y)
  of skCircle:
    let point = rotate(s.pos.vec2f,rot).vec2i + pos
    circfill(point.x, point.y,s.radius)
  of skQuad:
    let 
      a = rotate(s.pos.vec2f, rot).vec2i + pos
      b = rotate(s.p2.vec2f, rot).vec2i + pos
      c = rotate(s.p3.vec2f, rot).vec2i + pos
      d = rotate(s.p4.vec2f, rot).vec2i + pos
    quadfill(a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y)
  of skPoly:
    let
      point = rotate(vec2f(s.width,0),s.rot + rot)
      pRot = TAU / s.sides.float32 + rot
    for p in 0..<s.sides:
      let
        this = rotate(point, pRot * p.float32).vec2i + s.pos + pos
        next = rotate(point, pRot * (p + 1).float32).vec2i + s.pos + pos
      trifill(this.x,this.y,next.x,next.y,s.pos.x + x,s.pos.y + y)
  of skRect:
    let
      a = vec2f(s.rWidth, s.rHeight).rotate(rot).vec2i + s.pos + pos
      b = vec2f(-s.rWidth, s.rHeight).rotate(rot).vec2i + s.pos + pos
      c = vec2f(-s.rWidth, -s.rHeight).rotate(rot).vec2i + s.pos + pos
      d = vec2f(s.rWidth, -s.rHeight).rotate(rot).vec2i + s.pos + pos
    quadfill(a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y)
  else: discard

proc drawNvg*(nvg : Nvg,x, y: int32 = 0, rot : float32 = 0)=
  for shape in nvg: shape.drawShape(x,y,rot)

proc loadNvg*(name : string, relative = true, scale: float32 = 1) : Nvg=
  let path = if(relative) : assetPath & "/" & name else: name
  

  if(not fileExists(path)): 
    echo name, " Doesnt Exist"
    return#Fail gracefully like a tosser
  
  if(path.splitFile.ext != ".nvg"): 
    echo "Is not a .nvg"
    return

  let 
    file = open(path, fmRead)
    parsed = file.readAll().parseJson()
  file.close()
  result = parsed.to(Nvg)
  if(scale != 1):
    for shape in result.mitems:
      for name, field in shape.fieldPairs:
        when field is not ShapeKind: 
          when field is Vec2i: field = vec2i(field.x * scale, field.y * scale)
          elif(name != "color" and name != "sides" and name != "rot" and name != "rRot"):
            field *= scale

proc saveNvg*(nvg : Nvg, name : string, relative = true)=
  let
    path = if(relative) : assetPath & "/" & name else: name
    file = open(path, fmWrite)
    jsonData = %*nvg
  file.write(jsonData)
  file.close()