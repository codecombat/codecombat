createjs = require 'lib/createjs-parts'

module.exports = class CameraBorder extends createjs.Container
  layerPriority: 100

  subscriptions: {}

  constructor: (options) ->
    super()
    @initialize()
    @mouseEnabled = @mouseChildren = false
    @updateBounds options.bounds
    Backbone.Mediator.subscribe(channel, @[func], @) for channel, func of @subscriptions

  destroy: ->
    Backbone.Mediator.unsubscribe(channel, @[func], @) for channel, func of @subscriptions

  updateBounds: (bounds) ->
    return if _.isEqual bounds, @bounds
    @bounds = bounds
    if @border
      @removeChild @border
      @border = null
    return unless @bounds
    @addChild @border = new createjs.Shape()
    width = 20
    i = width
    while i
      opacity = 3 * (1 - (i/width)) / width
      @border.graphics.setStrokeStyle(i, 'round').beginStroke("rgba(0,0,0,#{opacity})").drawRect(bounds.x, bounds.y, bounds.width, bounds.height)
      i -= 1
    @border.cache bounds.x, bounds.y, bounds.width, bounds.height
