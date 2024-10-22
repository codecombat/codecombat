createjs = require 'lib/createjs-parts'

module.exports.createProgressBar = createProgressBar = (color, ticks, maxTicks) ->
  g = new createjs.Graphics()

  unless maxTicks
    # Simple rectangular bar style
    WIDTH = 20
    HEIGHT = 2
    EDGE = 0.3
    TICK_WIDTH = 2
    g.setStrokeStyle(1)
    g.beginFill(createjs.Graphics.getRGB(0, 0, 0))
    g.drawRect(0, -HEIGHT/2, WIDTH, HEIGHT, HEIGHT)
    g.beginFill(createjs.Graphics.getRGB(color...))
    g.drawRoundRect(EDGE, EDGE - HEIGHT/2, WIDTH-EDGE*2, HEIGHT-EDGE*2, HEIGHT-EDGE*2)
  else if not ticks
    # Draw no bar if health is 0
  else
    # Dimensions and settings
    # Scale width from 12 (1 health) to 34 (10+ health)
    WIDTH = 8 + 4 * Math.min(maxTicks, 3) + 2 * Math.max(0, Math.min(maxTicks - 3, 7))
    HEIGHT = 6
    STROKE_WIDTH = 1
    TICK_WIDTH = 1
    EDGE = STROKE_WIDTH / 2  # Adjust EDGE to be half the stroke width

    # Calculate dimensions
    pieceWidth = (WIDTH - (maxTicks - 1) * TICK_WIDTH) / maxTicks
    radius = HEIGHT / 2

    # Draw background
    g.setStrokeStyle(STROKE_WIDTH)
    g.beginStroke(createjs.Graphics.getRGB(59, 39, 34, 1))
    g.beginFill(createjs.Graphics.getRGB(28, 14, 83, 0.4))

    # Draw background shape with precise curvature
    g.moveTo(radius, -HEIGHT/2)
    g.lineTo(WIDTH - radius, -HEIGHT/2)
    g.arc(WIDTH - radius, 0, radius, -Math.PI/2, Math.PI/2, false)
    g.lineTo(radius, HEIGHT/2)
    g.arc(radius, 0, radius, Math.PI/2, -Math.PI/2, false)
    g.closePath()
    g.endStroke()

    # Draw filled pieces
    if ticks > 0
      g.setStrokeStyle(0)  # No stroke for filled pieces
      g.beginFill(createjs.Graphics.getRGB(color...))

      filledWidth = Math.min(ticks * (pieceWidth + TICK_WIDTH) - TICK_WIDTH, WIDTH - STROKE_WIDTH)

      # Calculate the inset for the progress bar
      inset = EDGE

      # Left cap (outset)
      g.moveTo(radius, -HEIGHT/2 + inset)
      g.arcTo(inset, -HEIGHT/2 + inset, inset, 0, radius - inset)
      g.arcTo(inset, HEIGHT/2 - inset, radius, HEIGHT/2 - inset, radius - inset)
      g.lineTo(filledWidth, HEIGHT/2 - inset)

      # Right cap (full outset if full, straight line if not)
      if ticks == maxTicks
        g.lineTo(WIDTH - radius, HEIGHT/2 - inset)
        g.arc(WIDTH - radius, 0, radius - inset, Math.PI/2, -Math.PI/2, true)
        g.lineTo(inset, -HEIGHT/2 + inset)
      else
        g.lineTo(filledWidth, -HEIGHT/2 + inset)

      g.closePath()

    # Add vertical tick marks
    g.setStrokeStyle(TICK_WIDTH)
    g.beginStroke(createjs.Graphics.getRGB(147, 129, 107, 1))
    for i in [1...maxTicks]
      tickX = i * (pieceWidth + TICK_WIDTH) - TICK_WIDTH/2
      g.moveTo(tickX, -HEIGHT/2 - 5)
      g.lineTo(tickX, HEIGHT/2 + 5)

  s = new createjs.Shape(g)
  s.z = 100
  s.bounds = [0, -HEIGHT/2, WIDTH, HEIGHT]
  return s
