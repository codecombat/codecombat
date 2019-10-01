createjs = require 'lib/createjs-parts'

module.exports.hitTest = (stage, bounds) ->
  tests = hits = 0
  for x in _.range(bounds.x, bounds.x + bounds.width, 5)
    for y in _.range(bounds.y, bounds.y + bounds.height, 5)
      tests += 1
      objects = stage.getObjectsUnderPoint(x, y)
      hasSprite = _.any objects, (o) -> o instanceof createjs.Sprite
      hasShape = _.any objects, (o) -> o instanceof createjs.Shape
      hits += 1 if (hasSprite and hasShape) or not (hasSprite or hasShape)
      g = new createjs.Graphics()
      if hasSprite and hasShape
        g.beginFill(createjs.Graphics.getRGB(64,64,255,0.7))
      else if not (hasSprite or hasShape)
        g.beginFill(createjs.Graphics.getRGB(64,64,64,0.7))
      else
        g.beginFill(createjs.Graphics.getRGB(255,64,64,0.7))
      g.drawCircle(0, 0, 2)
      s = new createjs.Shape(g)
      s.x = x
      s.y = y
      stage.addChild(s)
  return hits/tests

