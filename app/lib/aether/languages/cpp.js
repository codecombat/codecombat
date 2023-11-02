/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CPP;
const Language = require('./language');
const parserHolder = {};

module.exports = (CPP = (function() {
  CPP = class CPP extends Language {
    static initClass() {
      this.prototype.name = 'C++';
      this.prototype.id = 'cpp';
      this.prototype.parserID = 'cpp';
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
  CPP.initClass();
  return CPP;
})());
