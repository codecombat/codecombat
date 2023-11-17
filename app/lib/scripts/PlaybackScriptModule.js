// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PlaybackScriptModule;
const ScriptModule = require('./ScriptModule');

module.exports = (PlaybackScriptModule = class PlaybackScriptModule extends ScriptModule {
  static neededFor(noteGroup) {
    return (noteGroup.playback != null);
  }

  startNotes() {
    const notes = [];
    if (this.noteGroup.playback.playing != null) { notes.push(this.playingNote()); }
    if (this.noteGroup.playback.scrub != null) { notes.push(this.scrubNote()); }
    return notes;
  }

  endNotes() {
    const notes = [];
    // TODO: Want scripts to end where the scrub should go, but this doesn't work
    // when scripts go somewhere then do something else. Figure out a different technique?
//    notes.push(@scrubNote(true)) if @noteGroup.playback.scrub?
    return notes;
  }

  skipNotes() {
    const notes = [];
    if (this.noteGroup.playback.playing != null) { notes.push(this.playingNote()); }
    if (this.noteGroup.playback.scrub != null) { notes.push(this.scrubNote(true)); }
    return notes;
  }

  playingNote() {
    const note = {
      channel: 'level:set-playing',
      event: {playing: this.noteGroup.playback.playing}
    };
    return note;
  }

  scrubNote(instant) {
    if (instant == null) { instant = false; }
    const {
      scrub
    } = this.noteGroup.playback;
    const note = {
      channel: 'level:set-time',
      event: {
        frameOffset: scrub.frameOffset || 2,
        scrubDuration: instant ? 0 : scrub.duration
      }
    };
    if (scrub.toTime != null) { note.event.time = scrub.toTime; }
    if (scrub.toRatio != null) { note.event.ratio = scrub.toRatio; }
    return note;
  }
});
