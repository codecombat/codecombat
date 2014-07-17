CocoClass = require 'lib/CocoClass'

module.exports = class PlaybackOverScreen extends CocoClass
  constructor: (options) ->
    super()
    options ?= {}
    @camera = options.camera
    @layer = options.layer
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @build()

  toString: -> '<PlaybackOverScreen>'

  build: ->
    @dimLayer = new createjs.Container()
    @dimLayer.mouseEnabled = @dimLayer.mouseChildren = false
    @dimLayer.layerIndex = -12
    @dimLayer.addChild @dimScreen = new createjs.Shape()
    @dimScreen.graphics.beginFill('rgba(0,0,0,0.4)').rect 0, 0, @camera.canvasWidth, @camera.canvasHeight
    @dimLayer.cache 0, 0, @camera.canvasWidth, @camera.canvasHeight
    @dimLayer.alpha = 0
    @layer.addChild @dimLayer

  show: ->
    return if @showing
    @showing = true

    @dimLayer.alpha = 0
    createjs.Tween.removeTweens @dimLayer
    createjs.Tween.get(@dimLayer).to({alpha: 1}, 500)

  hide: ->
    return unless @showing
    @showing = false

    createjs.Tween.removeTweens @dimLayer
    createjs.Tween.get(@dimLayer).to({alpha: 0}, 500)
