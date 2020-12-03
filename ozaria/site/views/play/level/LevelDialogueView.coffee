require('ozaria/site/styles/play/level/level-dialogue-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'ozaria/site/templates/play/level/level-dialogue-view'

module.exports = class LevelDialogueView extends CocoView
  id: 'level-dialogue-view'
  template: template
