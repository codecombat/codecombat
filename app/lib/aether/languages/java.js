// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Java;
import Language from './language';
const parserHolder = {};

export default Java = (function() {
  Java = class Java extends Language {
    static initClass() {
      this.prototype.name = 'Java';
      this.prototype.id = 'java';
      this.prototype.parserID = 'jaba';
    }

    constructor() {
      super(...arguments);
    }

    hasChangedASTs(a, b) { return true; }
    usesFunctionWrapping() { return false; }

    obviouslyCannotTranspile(rawCode) {
      return false;
    }
  };
  Java.initClass();
  return Java;
})();

