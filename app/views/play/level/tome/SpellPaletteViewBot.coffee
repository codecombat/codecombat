SpellPaletteView = require './SpellPaletteView'

module.exports = class SpellPaletteViewBot extends SpellPaletteView
  id: 'spell-palette-view-bot'
  template: require 'app/templates/play/level/tome/spell-palette-view-bot'
  position: 'bot'
