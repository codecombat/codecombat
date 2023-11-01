// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CoffeeScript, left, left1;
const _ = (left = (left1 = (typeof window !== 'undefined' && window !== null ? window._ : undefined) != null ? (typeof window !== 'undefined' && window !== null ? window._ : undefined) : (typeof self !== 'undefined' && self !== null ? self._ : undefined)) != null ? left1 : (typeof global !== 'undefined' && global !== null ? global._ : undefined)) != null ? left : require('lodash');  // rely on lodash existing, since it busts CodeCombat to browserify it--TODO

const Language = require('./language');

module.exports = (CoffeeScript = (function() {
  CoffeeScript = class CoffeeScript extends Language {
    static initClass() {
      this.prototype.name = 'CoffeeScript';
      this.prototype.id = 'coffeescript';
      this.prototype.parserID = 'csredux';
      this.prototype.thisValue ='@';
      this.prototype.thisValueAccess ='@';
      this.prototype.heroValueAccess ='hero.';
      this.prototype.wrappedCodeIndentLen = 4;
    }

    constructor() {
      super(...arguments);
    }

    usesFunctionWrapping() { return false; }
  };
  CoffeeScript.initClass();
  return CoffeeScript;
})());
