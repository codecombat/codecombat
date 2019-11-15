ScriptModule = require './ScriptModule'

currentMusic = null
standingBy = null

store = require 'app/core/store'

module.exports = class SoundScriptModule extends ScriptModule
  @neededFor: (noteGroup) ->
    return noteGroup.sound?

  startNotes: ->
    notes = []
    notes.push(@addSuppressSelectionSoundsNote()) if @noteGroup.sound.suppressSelectionSounds?
    notes.push(@addMusicNote()) if @noteGroup.sound.music? and @noteGroup.sound.music.file?
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
      vuex: true
      channel: 'audio/playSound'
      event: {
        track: 'background'
        src: [ "/file/#{@noteGroup.sound.music.file}.ogg", "/file/#{@noteGroup.sound.music.file}.mp3" ]
        loop: true
      }

    return note
