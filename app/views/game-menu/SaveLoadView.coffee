CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/save-load-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'

module.exports = class SaveLoadView extends CocoView
  id: 'save-load-view'
  className: 'tab-pane'
  template: template

  getRenderData: (context={}) ->
    context = super(context)
    context

  afterRender: ->
    super()
