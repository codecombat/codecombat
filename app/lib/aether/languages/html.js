// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HTML, left, left1;
const _ = (left = (left1 = (typeof window !== 'undefined' && window !== null ? window._ : undefined) != null ? (typeof window !== 'undefined' && window !== null ? window._ : undefined) : (typeof self !== 'undefined' && self !== null ? self._ : undefined)) != null ? left1 : (typeof global !== 'undefined' && global !== null ? global._ : undefined)) != null ? left : require('lodash');  // rely on lodash existing, since it busts CodeCombat to browserify it--TODO

import Language from './language';

export default HTML = (function() {
  HTML = class HTML extends Language {
    static initClass() {
      this.prototype.name = 'HTML';
      this.prototype.id = 'html';
      this.prototype.parserID = 'html';
    }

    constructor() {
      super(...arguments);
    }

    hasChangedASTs(a, b) {
      return a.replace(/\s/g) !== b.replace(/\s/g);
    }

    usesFunctionWrapping() { return false; }

    // TODO: think about what this stub should do, really.
    parse(code, aether) {
      return code;
    }

    replaceLoops(rawCode) {
      return [rawCode, []];
    }
  };
  HTML.initClass();
  return HTML;
})();
