/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpellPaletteViewBot;
import SpellPaletteView from './SpellPaletteView';

export default SpellPaletteViewBot = (function() {
  SpellPaletteViewBot = class SpellPaletteViewBot extends SpellPaletteView {
    static initClass() {
      this.prototype.id = 'spell-palette-view-bot';
      this.prototype.template = require('app/templates/play/level/tome/spell-palette-view-bot');
      this.prototype.position = 'bot';
    }
  };
  SpellPaletteViewBot.initClass();
  return SpellPaletteViewBot;
})();
