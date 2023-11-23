createjs = require 'lib/createjs-parts'

Dropper = class Dropper
  lostFrames: 0.0
  dropCounter: 0

  constructor: ->
    @listener = (e) => @tick(e)

  tick: ->
    unless @tickedOnce
      @tickedOnce = true  # Can't get measured FPS on the 0th frame.
      return

    --@dropCounter if @dropCounter > 0

    # Track number of frames we've lost since the last tick.
    fps = createjs.Ticker.framerate
    actual = createjs.Ticker.getMeasuredFPS(1)
    @lostFrames += (fps - actual) / fps

    # If lostFrames > 1, drop that number for the next tick.
    @dropCounter += parseInt @lostFrames
    @lostFrames = @lostFrames % 1

  drop: ->
    return @dropCounter > 0

module.exports = new Dropper()
