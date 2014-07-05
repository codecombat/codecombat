Dropper = class Dropper
  lost_frames: 0.0
  drop_counter: 0

  constructor: ->
    @listener = (e) => @tick(e)

  tick: ->
    unless @tickedOnce
      @tickedOnce = true  # Can't get measured FPS on the 0th frame
      return

    # decrement drop counter
    @drop_counter -= 1 if @drop_counter > 0

    # track number of frames we've lost since the last tick
    fps = createjs.Ticker.getFPS()
    actual = createjs.Ticker.getMeasuredFPS(1)
    @lost_frames += (fps - actual) / fps

    # if lost_frames > 1, drop that number for the next tick
    @drop_counter += parseInt(@lost_frames)
    @lost_frames = @lost_frames % 1

  drop: ->
    return @drop_counter > 0

module.exports = new Dropper()
