CocoClass = require 'core/CocoClass'
RealTimeCollection = require 'collections/RealTimeCollection'

module.exports = class WaitingScreen extends CocoClass
  subscriptions:
    'playback:real-time-playback-waiting': 'onRealTimePlaybackWaiting'
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'real-time-multiplayer:player-status': 'onRealTimeMultiplayerPlayerStatus'

  constructor: (options) ->
    super()
    options ?= {}
    @camera = options.camera
    @layer = options.layer
    @waitingText = options.text or 'Waiting...'
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @build()

  onCastingBegins: (e) -> @show() unless e.preload
  onCastingEnds: (e) -> @hide()

  toString: -> '<WaitingScreen>'

  build: ->
    @dimLayer = new createjs.Container()
    @dimLayer.mouseEnabled = @dimLayer.mouseChildren = false
    @dimLayer.addChild @dimScreen = new createjs.Shape()
    @dimScreen.graphics.beginFill('rgba(0,0,0,0.5)').rect 0, 0, @camera.canvasWidth, @camera.canvasHeight
    @dimLayer.alpha = 0
    @dimLayer.addChild @makeWaitingText()

  makeWaitingText: ->
    size = Math.ceil @camera.canvasHeight / 8
    text = new createjs.Text @waitingText, "#{size}px Open Sans Condensed", '#F7B42C'
    text.shadow = new createjs.Shadow '#000', Math.ceil(@camera.canvasHeight / 300), Math.ceil(@camera.canvasHeight / 300), Math.ceil(@camera.canvasHeight / 120)
    text.textAlign = 'center'
    text.textBaseline = 'middle'
    text.x = @camera.canvasWidth / 2
    text.y = @camera.canvasHeight / 2
    @text = text
    return text

  show: ->
    return if @showing
    @showing = true
    @dimLayer.alpha = 0
    createjs.Tween.removeTweens @dimLayer
    createjs.Tween.get(@dimLayer).to({alpha: 1}, 500)
    @layer.addChild @dimLayer

  hide: ->
    return unless @showing
    @showing = false
    createjs.Tween.removeTweens @dimLayer
    createjs.Tween.get(@dimLayer).to({alpha: 0}, 500).call => @layer.removeChild @dimLayer unless @destroyed

  onRealTimeMultiplayerPlayerStatus: (e) -> @text.text = e.status

  onRealTimePlaybackWaiting: (e) -> @show()

  onRealTimePlaybackStarted: (e) -> @hide()

  onRealTimePlaybackEnded: (e) -> @hide()
