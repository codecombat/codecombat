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
    notes = []

    # End notes are fired when the sound script module stops (during level cleanup and during
    # level restart).  These two audio notes should be fired during level end so that any level
    # audio that is playing is stopped and cleaned up.  Unfortunately, during a level restart the
    # start notes of the second level load are fired before the end notes of the first level.
    # This race condition leads to the audio being completely stopped on a level restart.  The
    # notes are left here for reference and should be enabled when the race condition for end notes
    # is resolved.
    #
    # TODO uncomment this code when level endNote race condition is resolved
    #
    # notes.push({
    #   vuex: true
    #   channel: 'audio/fadeAndStopTrack'
    #   event: {
    #     track: 'background'
    #     to: 0
    #     duration: 200
    #   }
    # })
    #
    # notes.push({
    #   vuex: true
    #   channel: 'audio/fadeAndStopTrack'
    #   event: {
    #     track: 'soundEffects'
    #     to: 0
    #     duration: 200
    #   }
    # })

    return notes

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
        # Unique key prevents background music from replaying during a level restart.  This is
        # an alternative to firing end notes from this module, which currently has a race condition
        # during restarts.  See endNote method for more details.
        unique: "level/soundScriptModule/background/#{@noteGroup.sound.music.file}"
        src: [ "/file#{@noteGroup.sound.music.file}.ogg", "/file#{@noteGroup.sound.music.file}.mp3" ]
        loop: true,
        volume: 0.25
      }

    return note
