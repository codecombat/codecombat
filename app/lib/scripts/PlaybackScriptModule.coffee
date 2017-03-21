ScriptModule = require './ScriptModule'

module.exports = class PlaybackScriptModule extends ScriptModule
  @neededFor: (noteGroup) ->
    return noteGroup.playback?

  startNotes: ->
    notes = []
    notes.push(@playingNote()) if @noteGroup.playback.playing?
    notes.push(@scrubNote()) if @noteGroup.playback.scrub?
    return notes

  endNotes: ->
    notes = []
    # TODO: Want scripts to end where the scrub should go, but this doesn't work
    # when scripts go somewhere then do something else. Figure out a different technique?
#    notes.push(@scrubNote(true)) if @noteGroup.playback.scrub?
    return notes

  skipNotes: ->
    notes = []
    notes.push(@playingNote()) if @noteGroup.playback.playing?
    notes.push(@scrubNote(true)) if @noteGroup.playback.scrub?
    return notes

  playingNote: ->
    note =
      channel: 'level:set-playing'
      event: {playing: @noteGroup.playback.playing}
    return note

  scrubNote: (instant=false) ->
    scrub = @noteGroup.playback.scrub
    note =
      channel: 'level:set-time'
      event:
        frameOffset: scrub.frameOffset or 2
        scrubDuration: if instant then 0 else scrub.duration
    note.event.time = scrub.toTime if scrub.toTime?
    note.event.ratio = scrub.toRatio if scrub.toRatio?
    return note
