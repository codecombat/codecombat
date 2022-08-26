ScriptModule = require './ScriptModule'

currentMusic = null
standingBy = null

{me} = require('core/auth')

module.exports = class SoundScriptModule extends ScriptModule
  @neededFor: (noteGroup) ->
    return noteGroup.sound?

  startNotes: ->
    notes = []
    notes.push(@addSuppressSelectionSoundsNote()) if @noteGroup.sound.suppressSelectionSounds?
    notes.push(@addMusicNote()) if @noteGroup.sound.music?
    return notes

  endNotes: ->
    return []

  skipNotes: ->
    return @startNotes()

  addSuppressSelectionSoundsNote: ->
    note =
      channel: 'level:suppress-selection-sounds'
      event: {suppress: @noteGroup.sound.suppressSelectionSounds}
    return note

  addMusicNote: ->
    note =
      channel: 'music-player:play-music'
      event: @noteGroup.sound.music
    return note
