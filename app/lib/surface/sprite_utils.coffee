PROG_BAR_WIDTH = 20
PROG_BAR_HEIGHT = 2

module.exports.createProgressBar = createProgressBar = (color, y, width=PROG_BAR_WIDTH, height=PROG_BAR_HEIGHT) ->
  g = new createjs.Graphics()
  g.setStrokeStyle(1)
  g.beginFill(createjs.Graphics.getRGB(color...))
  g.drawRoundRect(0, -1, width, height, height)

  s = new createjs.Shape(g)
  s.x = -width / 2
  s.y = y
  s.z = 100
  s.width = width
  s.height = height
  return s
