/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DOMScriptModule;
const ScriptModule = require('./ScriptModule');

module.exports = (DOMScriptModule = class DOMScriptModule extends ScriptModule {
  static neededFor(noteGroup) {
    return (noteGroup.dom != null);
  }

  startNotes() {
    const notes = [];
    if (this.noteGroup.dom.highlight != null) { notes.push(this.highlightNote()); }
    if (this.noteGroup.dom.lock != null) { notes.push(this.lockNote()); }
    if (this.noteGroup.dom.focus != null) { notes.push(this.focusNote()); }
    if (this.noteGroup.dom.showVictory) { notes.push(this.showVictoryNote()); }
    if (this.noteGroup.dom.letterbox != null) { notes.push(this.letterboxNote()); }
    return notes;
  }

  endNotes() {
    const notes = [];
    if (this.noteGroup.dom.highlight != null) { notes.push({'channel': 'level:end-highlight-dom'}); }
    if (this.noteGroup.dom.lock != null) { notes.push({'channel': 'level:enable-controls'}); }
    return notes;
  }

  skipNotes() {
    const notes = [];
    if (this.noteGroup.dom.showVictory != null) { notes.push(this.showVictoryNote(false)); }
    if (this.noteGroup.dom.letterbox != null) { notes.push(this.letterboxNote()); }
    return notes;
  }

  highlightNote() {
    const {
      dom
    } = this.noteGroup;
    const note = {
      channel: 'level:highlight-dom',
      event: {
        selector: dom.highlight.target,
        delay: dom.highlight.delay,
        sides: dom.highlight.sides,
        offset: dom.highlight.offset,
        rotation: dom.highlight.rotation
      }
    };
    note.event = _.pick(note.event, value => !_.isUndefined(value));
    this.maybeApplyDelayToNote(note);
    return note;
  }

  focusNote() {
    const note = {
      channel: 'level:focus-dom',
      event: {
        selector: this.noteGroup.dom.focus
      }
    };
    return note;
  }

  showVictoryNote(showModal) {
    const e = {};
    e.showModal = [true, 'Done Button And Modal'].includes(this.noteGroup.dom.showVictory);
    if (showModal != null) { e.showModal = showModal; }
    const note = {
      channel: 'level:show-victory',
      event: e
    };
    return note;
  }

  lockNote() {
    const event = {};
    const {
      lock
    } = this.noteGroup.dom;
    if (_.isArray(lock)) { event.controls = lock; }  // array: subset of controls
    const channel = lock ? 'level:disable-controls' : 'level:enable-controls';
    return {channel, event};
  }

  letterboxNote() {
    return {channel: 'level:set-letterbox', event: {on: this.noteGroup.dom.letterbox}};
  }
});
