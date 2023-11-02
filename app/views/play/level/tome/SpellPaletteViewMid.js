/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpellPaletteViewMid;
const SpellPaletteView = require('./SpellPaletteView');

module.exports = (SpellPaletteViewMid = (function() {
  SpellPaletteViewMid = class SpellPaletteViewMid extends SpellPaletteView {
    static initClass() {
      this.prototype.id = 'spell-palette-view-mid';
      this.prototype.template = require('app/templates/play/level/tome/spell-palette-view-mid');
      this.prototype.position = 'mid';
    }
  };
  SpellPaletteViewMid.initClass();
  return SpellPaletteViewMid;
})());

