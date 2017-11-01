createjs = require 'lib/createjs-parts'

module.exports = class DebugDisplay extends createjs.Container
  layerPriority: 20
  subscriptions:
    'level:set-debug': 'onSetDebug'

  constructor: (options) ->
    super()
    @initialize()
    @canvasWidth = options.canvasWidth
    @canvasHeight = options.canvasHeight
    console.error 'DebugDisplay needs canvasWidth/Height.' unless @canvasWidth and @canvasHeight
    @build()
    @onSetDebug debug: true
    Backbone.Mediator.subscribe(channel, @[func], @) for channel, func of @subscriptions

  destroy: ->
    Backbone.Mediator.unsubscribe(channel, @[func], @) for channel, func of @subscriptions

  onSetDebug: (e) ->
    return if e.debug is @on
    @visible = @on = e.debug
    @fps = null
    @framesRenderedThisSecond = 0
    @lastFrameSecondStart = Date.now()

  build: ->
    @mouseEnabled = @mouseChildren = false
    @addChild @frameText = new createjs.Text '...', '20px Arial', '#FFF'
    @frameText.name = 'frame text'
    @frameText.x = @canvasWidth - 50
    @frameText.y = @canvasHeight - 25
    @frameText.alpha = 0.5

  updateFrame: (currentFrame) ->
    return unless @on
    ++@framesRenderedThisSecond
    time = Date.now()
    diff = (time - @lastFrameSecondStart) / 1000
    if diff > 1
      @fps = Math.round @framesRenderedThisSecond / diff
      @lastFrameSecondStart = time
      @framesRenderedThisSecond = 0

    @frameText.text = Math.round(currentFrame) + (if @fps? then ' - ' + @fps + ' fps' else '')
    @frameText.x = @canvasWidth - @frameText.getMeasuredWidth() - 10
