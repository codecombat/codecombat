PROG_BAR_WIDTH = 20
PROG_BAR_HEIGHT = 2
PROG_BAR_SCALE = 2.5
EDGE_SIZE = 0.3

module.exports.createProgressBar = createProgressBar = (color, offset, width=PROG_BAR_WIDTH, height=PROG_BAR_HEIGHT) ->
  g = new createjs.Graphics()
  g.setStrokeStyle(1)

  sWidth = width * PROG_BAR_SCALE
  sHeight = height * PROG_BAR_SCALE
  sEdge = EDGE_SIZE * PROG_BAR_SCALE

  g.beginFill(createjs.Graphics.getRGB(0, 0, 0))
  g.drawRect(0, -sHeight/2, sWidth, sHeight, sHeight)
  g.beginFill(createjs.Graphics.getRGB(color...))
  g.drawRoundRect(sEdge, sEdge - sHeight/2, sWidth-sEdge*2, sHeight-sEdge*2, sHeight-sEdge*2)

  s = new createjs.Shape(g)
  s.z = 100
  s.baseScale = PROG_BAR_SCALE
  s.scaleX = 1 / PROG_BAR_SCALE
  s.scaleY = 1 / PROG_BAR_SCALE
  s.width = width
  s.height = height
  s.regX = (-offset.x + width / 2) * PROG_BAR_SCALE
  s.regY = (-offset.y) * PROG_BAR_SCALE
  return s
