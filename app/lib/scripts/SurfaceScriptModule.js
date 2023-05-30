// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SurfaceScriptModule;
import ScriptModule from './ScriptModule';

export default SurfaceScriptModule = class SurfaceScriptModule extends ScriptModule {
  static neededFor(noteGroup) {
    return (noteGroup.surface != null);
  }

  startNotes() {
    const notes = [];
    if (this.noteGroup.surface.focus != null) { notes.push(this.surfaceCameraNote()); }
    if (this.noteGroup.surface.highlight != null) { notes.push(this.surfaceHighlightNote()); }
    if (this.noteGroup.surface.lockSelect != null) { notes.push(this.surfaceLockSelectNote()); }
    return notes;
  }

  endNotes() {
    const notes = [];
    if (this.noteGroup.surface.highlight != null) { notes.push({channel:'sprite:highlight-sprites', event: {thangIDs: []}}); }
    if (this.noteGroup.surface.focus != null) { notes.push(this.surfaceCameraNote(true)); }
    if (this.noteGroup.surface.lockSelect != null) { notes.push(this.surfaceLockSelectNote()); }
    return notes;
  }

  skipNotes() {
    const notes = [];
    if (this.noteGroup.surface.focus != null) { notes.push(this.surfaceCameraNote(true)); }
    if (this.noteGroup.surface.lockSelect != null) { notes.push(this.surfaceLockSelectNote()); }
    return notes;
  }

  surfaceCameraNote(instant) {
    if (instant == null) { instant = false; }
    const {
      focus
    } = this.noteGroup.surface;
    const e = {};
    if (_.isPlainObject(focus.target)) { e.pos = focus.target; }
    if (_.isString(focus.target)) { e.thangID = focus.target; }
    e.zoom = focus.zoom || 2.0;  // TODO: test only doing this if e.pos, e.thangID, or focus.zoom?
    e.duration = (focus.duration != null) ? focus.duration : 1500;
    if (instant) { e.duration = 0; }
    if (focus.bounds != null) { e.bounds = focus.bounds; }
    return { channel: 'camera:set-camera', event: e };
  }

  surfaceHighlightNote() {
    const {
      highlight
    } = this.noteGroup.surface;
    const note = {
      channel: 'sprite:highlight-sprites',
      event: {
        thangIDs: highlight.targets,
        delay: highlight.delay
      }
    };
    this.maybeApplyDelayToNote(note, this.noteGroup);
    return note;
  }

  surfaceLockSelectNote() {
    return { channel: 'level:lock-select', event: {lock: this.noteGroup.surface.lockSelect} };
  }
};
