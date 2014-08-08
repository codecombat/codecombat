CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/options-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'

module.exports = class OptionsView extends CocoView
  id: 'options-view'
  className: 'tab-pane'
  template: template

  getRenderData: (context={}) ->
    context = super(context)
    context

  afterRender: ->
    super()
