// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ScriptModule;
const CocoClass = require('core/CocoClass');

module.exports = (ScriptModule = (function() {
  let scrubbingTime = undefined;
  let movementTime = undefined;
  ScriptModule = class ScriptModule extends CocoClass {
    static initClass() {

      scrubbingTime = 0;
      movementTime = 0;
    }

    constructor(noteGroup) {
      super();
      this.noteGroup = noteGroup;
      if (!this.noteGroup.prepared) {
        this.analyzeNoteGroup(this.noteGroup);
        if (this.noteGroup.notes == null) { this.noteGroup.notes = []; }
        this.noteGroup.prepared = true;
      }
    }

    // subclass should overwrite these

    static neededFor() { return false; }
    startNotes() { return []; }
    endNotes() { return []; }
    skipNotes() { return this.endNotes(); }

    // common logic

    analyzeNoteGroup() {
      // some notes need to happen after others. Calculate the delays
      this.movementTime = this.calculateMovementMax(this.noteGroup);
      return this.scrubbingTime = __guard__(this.noteGroup.playback != null ? this.noteGroup.playback.scrub : undefined, x => x.duration) || 0;
    }

    calculateMovementMax() {
      let sums = {};
      for (var sprite of Array.from(this.noteGroup.sprites)) {
        if (sprite.move == null) { continue; }
        if (sums[sprite.id] == null) { sums[sprite.id] = 0; }
        sums[sprite.id] += sprite.move.duration;
      }
      sums = ((() => {
        const result = [];
        for (var k in sums) {
          result.push(sums[k]);
        }
        return result;
      })());
      return Math.max(0, ...Array.from(sums));
    }

    maybeApplyDelayToNote(note) {
      return note.delay = (this.scrubbingTime + this.movementTime) || 0;
    }
  };
  ScriptModule.initClass();
  return ScriptModule;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}