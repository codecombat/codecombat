CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/item-view'

module.exports = class ItemView extends CocoView
  className: 'item-view'
  
  template: template
  
  initialize: (options) ->
    super(arguments...)
    @item = options.item
    @includes = options.includes or {}

  getRenderData: ->
    c = super()
    c.item = @item
    c.includes = @includes
    c
    
  afterRender: ->
    @$el.data('item-id', @item.id)
