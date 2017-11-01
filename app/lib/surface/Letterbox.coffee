createjs = require 'lib/createjs-parts'

module.exports = class Letterbox extends createjs.Container
  subscriptions:
    'level:set-letterbox': 'onSetLetterbox'

  constructor: (options) ->
    super()
    @initialize()
    @canvasWidth = options.canvasWidth
    @canvasHeight = options.canvasHeight
    console.error 'Letterbox needs canvasWidth/Height.' unless @canvasWidth and @canvasHeight
    @build()
    Backbone.Mediator.subscribe(channel, @[func], @) for channel, func of @subscriptions

  build: ->
    @mouseEnabled = @mouseChildren = false
    @matteHeight = 0.10 * @canvasHeight
    @upperMatte = new createjs.Shape()
    @upperMatte.graphics.beginFill('black').rect(0, 0, @canvasWidth, @matteHeight)
    @lowerMatte = @upperMatte.clone()
    @upperMatte.x = @lowerMatte.x = 0
    @upperMatte.y = -@matteHeight
    @lowerMatte.y = @canvasHeight
    @addChild @upperMatte, @lowerMatte

  onSetLetterbox: (e) ->
    T = createjs.Tween
    T.removeTweens @upperMatte
    T.removeTweens @lowerMatte
    upperY = if e.on then 0 else -@matteHeight
    lowerY = if e.on then @canvasHeight - @matteHeight else @canvasHeight
    interval = 700
    ease = createjs.Ease.cubicOut
    T.get(@upperMatte).to({y: upperY}, interval, ease)
    T.get(@lowerMatte).to({y: lowerY}, interval, ease)

  destroy: ->
    Backbone.Mediator.unsubscribe(channel, @[func], @) for channel, func of @subscriptions
