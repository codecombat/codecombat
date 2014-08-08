CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/multiplayer-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'

module.exports = class MultiplayerView extends CocoView
  id: 'multiplayer-view'
  className: 'tab-pane'
  template: template

  getRenderData: (context={}) ->
    context = super(context)
    context

  afterRender: ->
    super()
