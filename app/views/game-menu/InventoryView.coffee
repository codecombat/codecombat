CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/inventory-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'

module.exports = class InventoryView extends CocoView
  id: 'inventory-view'
  className: 'tab-pane'
  template: template

  getRenderData: (context={}) ->
    context = super(context)
    context

  afterRender: ->
    super()
