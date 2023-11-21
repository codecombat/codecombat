ScriptModule = require './ScriptModule'

module.exports = class SurfaceScriptModule extends ScriptModule
  @neededFor: (noteGroup) ->
    return noteGroup.surface?

  startNotes: ->
    notes = []
    notes.push(@surfaceCameraNote()) if @noteGroup.surface.focus?
    notes.push(@surfaceHighlightNote()) if @noteGroup.surface.highlight?
    notes.push(@surfaceLockSelectNote()) if @noteGroup.surface.lockSelect?
    return notes

  endNotes: ->
    notes = []
    notes.push({channel:'sprite:highlight-sprites', event: {thangIDs: []}}) if @noteGroup.surface.highlight?
    notes.push(@surfaceCameraNote(true)) if @noteGroup.surface.focus?
    notes.push(@surfaceLockSelectNote()) if @noteGroup.surface.lockSelect?
    return notes

  skipNotes: ->
    notes = []
    notes.push(@surfaceCameraNote(true)) if @noteGroup.surface.focus?
    notes.push(@surfaceLockSelectNote()) if @noteGroup.surface.lockSelect?
    return notes

  surfaceCameraNote: (instant=false) ->
    focus = @noteGroup.surface.focus
    e = {}
    e.pos = focus.target if _.isPlainObject focus.target
    e.thangID = focus.target if _.isString focus.target
    e.zoom = focus.zoom or 2.0  # TODO: test only doing this if e.pos, e.thangID, or focus.zoom?
    e.duration = if focus.duration? then focus.duration else 1500
    e.duration = 0 if instant
    e.bounds = focus.bounds if focus.bounds?
    return { channel: 'camera:set-camera', event: e }

  surfaceHighlightNote: ->
    highlight = @noteGroup.surface.highlight
    note =
      channel: 'sprite:highlight-sprites'
      event:
        thangIDs: highlight.targets
        delay: highlight.delay
    @maybeApplyDelayToNote note, @noteGroup
    return note

  surfaceLockSelectNote: ->
    return { channel: 'level:lock-select', event: {lock: @noteGroup.surface.lockSelect} }
