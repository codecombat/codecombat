CocoClass = require 'core/CocoClass'

module.exports = class ScriptModule extends CocoClass

  scrubbingTime = 0
  movementTime = 0

  constructor: (@noteGroup) ->
    super()
    if not @noteGroup.prepared
      @analyzeNoteGroup(@noteGroup)
      @noteGroup.notes ?= []
      @noteGroup.prepared = true

  # subclass should overwrite these

  @neededFor: -> false
  startNotes: -> []
  endNotes: -> []
  skipNotes: -> @endNotes()

  # common logic

  analyzeNoteGroup: ->
    # some notes need to happen after others. Calculate the delays
    @movementTime = @calculateMovementMax(@noteGroup)
    @scrubbingTime = @noteGroup.playback?.scrub?.duration or 0

  calculateMovementMax: ->
    sums = {}
    for sprite in @noteGroup.sprites
      continue unless sprite.move?
      sums[sprite.id] ?= 0
      sums[sprite.id] += sprite.move.duration
    sums = (sums[k] for k of sums)
    Math.max(0, sums...)

  maybeApplyDelayToNote: (note) ->
    note.delay = (@scrubbingTime + @movementTime) or 0
