// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SoundScriptModule;
const ScriptModule = require('./ScriptModule');
const utils = require('core/utils');

const currentMusic = null;
const standingBy = null;

const {me} = require('core/auth');
const store = require('app/core/store');

module.exports = (SoundScriptModule = class SoundScriptModule extends ScriptModule {
  static neededFor(noteGroup) {
    return (noteGroup.sound != null);
  }

  startNotes() {
    const notes = [];
    if (this.noteGroup.sound.suppressSelectionSounds != null) { notes.push(this.addSuppressSelectionSoundsNote()); }
    if (utils.isOzaria) {
      if ((this.noteGroup.sound.music != null) && (this.noteGroup.sound.music.file != null)) { notes.push(this.addMusicNote()); }
    } else {
      if (this.noteGroup.sound.music != null) { notes.push(this.addMusicNote()); }
    }
    return notes;
  }

  endNotes() {
    const notes = [];

    // End notes are fired when the sound script module stops (during level cleanup and during
    // level restart).  These two audio notes should be fired during level end so that any level
    // audio that is playing is stopped and cleaned up.  Unfortunately, during a level restart the
    // start notes of the second level load are fired before the end notes of the first level.
    // This race condition leads to the audio being completely stopped on a level restart.  The
    // notes are left here for reference and should be enabled when the race condition for end notes
    // is resolved.
    //
    // TODO uncomment this code when level endNote race condition is resolved
    //
    // notes.push({
    //   vuex: true
    //   channel: 'audio/fadeAndStopTrack'
    //   event: {
    //     track: 'background'
    //     to: 0
    //     duration: 200
    //   }
    // })
    //
    // notes.push({
    //   vuex: true
    //   channel: 'audio/fadeAndStopTrack'
    //   event: {
    //     track: 'soundEffects'
    //     to: 0
    //     duration: 200
    //   }
    // })

    return notes;
  }

  skipNotes() {
    return this.startNotes();
  }

  addSuppressSelectionSoundsNote() {
    const note = {
      channel: 'level:suppress-selection-sounds',
      event: {suppress: this.noteGroup.sound.suppressSelectionSounds}
    };
    return note;
  }

  addMusicNote() {
    let note;
    if (utils.isOzaria) {
      note = {
        vuex: true,
        channel: 'audio/playSound',
        event: {
          track: 'background',
          // Unique key prevents background music from replaying during a level restart.  This is
          // an alternative to firing end notes from this module, which currently has a race condition
          // during restarts.  See endNote method for more details.
          unique: `level/soundScriptModule/background/${this.noteGroup.sound.music.file}`,
          src: [ `/file${this.noteGroup.sound.music.file}.ogg`, `/file${this.noteGroup.sound.music.file}.mp3` ],
          loop: true,
          volume: 0.25
        }
      };
    } else { // CodeCombat
      note = {
        channel: 'music-player:play-music',
        event: this.noteGroup.sound.music
      };
    }

    return note;
  }
});
