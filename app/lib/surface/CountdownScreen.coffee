CocoClass = require 'core/CocoClass'
createjs = require 'lib/createjs-parts'

module.exports = class CountdownScreen extends CocoClass
  subscriptions:
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'

  constructor: (options) ->
    super()
    options ?= {}
    @camera = options.camera
    @layer = options.layer
    @showsCountdown = options.showsCountdown
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @build()

  destroy: ->
    clearInterval @countdownInterval if @countdownInterval
    super()

  onCastingBegins: (e) -> @show() unless e.preload
  onCastingEnds: (e) -> @hide()

  toString: -> '<CountdownScreen>'

  build: ->
    @dimLayer = new createjs.Container()
    @dimLayer.mouseEnabled = @dimLayer.mouseChildren = false
    @dimLayer.addChild @dimScreen = new createjs.Shape()
    @dimScreen.graphics.beginFill('rgba(0,0,0,0.5)').rect 0, 0, @camera.canvasWidth, @camera.canvasHeight
    @dimLayer.alpha = 0
    @dimLayer.addChild @makeCountdownText()

  makeCountdownText: ->
    size = Math.ceil @camera.canvasHeight / 2
    text = new createjs.Text '3...', "#{size}px Open Sans Condensed", '#F7B42C'
    text.shadow = new createjs.Shadow '#000', Math.ceil(@camera.canvasHeight / 300), Math.ceil(@camera.canvasHeight / 300), Math.ceil(@camera.canvasHeight / 120)
    text.textAlign = 'center'
    text.textBaseline = 'middle'
    text.x = @camera.canvasWidth / 2
    text.y = @camera.canvasHeight / 2
    @text = text
    return text

  show: ->
    return if @showing
    createjs.Tween.removeTweens @dimLayer
    if @showsCountdown
      @dimLayer.alpha = 0
      @showing = true
      createjs.Tween.get(@dimLayer).to({alpha: 1}, 500)
      @secondsRemaining = 3
      @countdownInterval = setInterval @decrementCountdown, 1000
      @updateText()
      @layer.addChild @dimLayer
    else
      @endCountdown()

  hide: (duration=500) ->
    return unless @showing
    @showing = false
    createjs.Tween.removeTweens @dimLayer
    createjs.Tween.get(@dimLayer).to({alpha: 0}, duration).call => @layer.removeChild @dimLayer unless @destroyed

  decrementCountdown: =>
    return if @destroyed
    --@secondsRemaining
    @updateText()
    unless @secondsRemaining
      @endCountdown()

  updateText: ->
    @text.text = if @secondsRemaining then "#{@secondsRemaining}..." else '0!'

  endCountdown: ->
    console.log 'should actually start in 1s'
    clearInterval @countdownInterval if @countdownInterval
    @countdownInterval = null
    @hide()

  onRealTimePlaybackStarted: (e) ->
    @show()

  onRealTimePlaybackEnded: (e) ->
    clearInterval @countdownInterval if @countdownInterval
    @countdownInterval = null
    @hide Math.max(500, 1000 * (@secondsRemaining or 0))
