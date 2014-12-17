ScriptModule = require './ScriptModule'

module.exports = class DOMScriptModule extends ScriptModule
  @neededFor: (noteGroup) ->
    return noteGroup.dom?

  startNotes: ->
    notes = []
    notes.push(@highlightNote()) if @noteGroup.dom.highlight?
    notes.push(@lockNote()) if @noteGroup.dom.lock?
    notes.push(@focusNote()) if @noteGroup.dom.focus?
    notes.push(@showVictoryNote()) if @noteGroup.dom.showVictory
    notes.push(@letterboxNote()) if @noteGroup.dom.letterbox?
    return notes

  endNotes: ->
    notes = []
    notes.push({'channel': 'level:end-highlight-dom'}) if @noteGroup.dom.highlight?
    notes.push({'channel': 'level:enable-controls'}) if @noteGroup.dom.lock?
    return notes

  skipNotes: ->
    notes = []
    notes.push(@showVictoryNote(false)) if @noteGroup.dom.showVictory?
    notes.push(@letterboxNote()) if @noteGroup.dom.letterbox?
    notes

  highlightNote: ->
    dom = @noteGroup.dom
    note =
      channel: 'level:highlight-dom'
      event:
        selector: dom.highlight.target
        delay: dom.highlight.delay
        sides: dom.highlight.sides
        offset: dom.highlight.offset
        rotation: dom.highlight.rotation
    note.event = _.pick note.event, (value) -> not _.isUndefined value
    @maybeApplyDelayToNote note
    note

  focusNote: ->
    note =
      channel: 'level:focus-dom'
      event:
        selector: @noteGroup.dom.focus
    note

  showVictoryNote: (showModal) ->
    e = {}
    e.showModal = @noteGroup.dom.showVictory in [true, 'Done Button And Modal']
    e.showModal = showModal if showModal?
    note =
      channel: 'level:show-victory'
      event: e
    note

  lockNote: ->
    event = {}
    lock = @noteGroup.dom.lock
    event.controls = lock if _.isArray lock  # array: subset of controls
    channel = if lock then 'level:disable-controls' else 'level:enable-controls'
    return {channel: channel, event: event}

  letterboxNote: ->
    return {channel: 'level:set-letterbox', event: {on: @noteGroup.dom.letterbox}}
