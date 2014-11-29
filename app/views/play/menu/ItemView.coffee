CocoView = require 'views/core/CocoView'
template = require 'templates/play/menu/item-view'

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
    if @includes.props or @includes.stats
      {props, stats} = @item.getFrontFacingStats()
      c.props = props
      c.stats = stats
    c

  afterRender: ->
    @$el.data('item-id', @item.id)
