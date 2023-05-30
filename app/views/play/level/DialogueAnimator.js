/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DialogueAnimator;
const utils = require('core/utils');

module.exports = (DialogueAnimator = (function() {
  DialogueAnimator = class DialogueAnimator {
    static initClass() {
      this.prototype.jqueryElement = null;
      this.prototype.childrenToAdd = null;
      this.prototype.charsToAdd = null;
      this.prototype.childAnimator = null;
    }

    constructor(html, jqueryElement) {
      this.jqueryElement = jqueryElement;
      if (__guard__(me.get('aceConfig'), x => x.screenReaderMode) && utils.isOzaria) {
        // Render instantly when in screen reader mode; don't animate anything.
        this.jqueryElement.html(html);
        return;
      }
      const d = $('<div></div>').html(html);
      this.childrenToAdd = _.map(d[0].childNodes, e => e);
      this.t0 = new Date();
      this.charsAdded = 0;
      this.charsPerSecond = 27;
    }

    tick() {
      if (!this.charsToAdd && !this.childAnimator) {
        this.addNextElement();
      }

      if (this.charsToAdd) {
        this.addSingleChar();
        return;
      }

      if (this.childAnimator) {
        this.childAnimator.tick();
        if (this.childAnimator.done()) {
          return this.childAnimator = null;
        }
      }
    }

    addNextElement() {
      if (!this.childrenToAdd.length) { return; }
      const nextElem = this.childrenToAdd[0];
      this.childrenToAdd = this.childrenToAdd.slice(1);
      if (nextElem.nodeName === '#text') {
        return this.charsToAdd = nextElem.nodeValue;
      } else {
        const value = nextElem.innerHTML;
        const newElem = $(nextElem).html('');
        this.jqueryElement.append(newElem);
        if (value) {
          if (this.childAnimator) { this.charsAdded += this.childAnimator.getCharsAdded(); }
          return this.childAnimator = new DialogueAnimator(value, newElem);
        }
      }
    }

    addSingleChar() {
      const elapsed = (new Date()) - this.t0;
      const nAdded = this.getCharsAdded();
      const nToHaveBeenAdded = Math.round((this.charsPerSecond * elapsed) / 1000);
      const nToAdd = Math.min(nToHaveBeenAdded - nAdded, this.charsToAdd.length);
      this.jqueryElement.html(this.jqueryElement.html() + this.charsToAdd.slice(0, nToAdd));
      this.charsToAdd = this.charsToAdd.slice(nToAdd);
      if (this.charsToAdd.length === 0) {
        this.charsToAdd = null;
      }
      return this.charsAdded += nToAdd;
    }

    getCharsAdded() {
      return this.charsAdded + ((this.childAnimator != null ? this.childAnimator.charsAdded : undefined) != null ? (this.childAnimator != null ? this.childAnimator.charsAdded : undefined) : 0);
    }

    done() {
      if ((this.childrenToAdd != null ? this.childrenToAdd.length : undefined) > 0) { return false; }
      if (this.charsToAdd) { return false; }
      if (this.childAnimator) { return false; }
      return true;
    }
  };
  DialogueAnimator.initClass();
  return DialogueAnimator;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}