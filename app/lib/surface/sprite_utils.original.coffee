createjs = require 'lib/createjs-parts'

WIDTH = 20
HEIGHT = 2
EDGE = 0.3

module.exports.createProgressBar = createProgressBar = (color) ->
  g = new createjs.Graphics()
  g.setStrokeStyle(1)
  g.beginFill(createjs.Graphics.getRGB(0, 0, 0))
  g.drawRect(0, -HEIGHT/2, WIDTH, HEIGHT, HEIGHT)
  g.beginFill(createjs.Graphics.getRGB(color...))
  g.drawRoundRect(EDGE, EDGE - HEIGHT/2, WIDTH-EDGE*2, HEIGHT-EDGE*2, HEIGHT-EDGE*2)
  s = new createjs.Shape(g)
  s.z = 100
  s.bounds = [0, -HEIGHT/2, WIDTH, HEIGHT]
  return s
