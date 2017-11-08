CocoClass = require 'core/CocoClass'
createjs = require 'lib/createjs-parts'

module.exports = class Dimmer extends CocoClass
  subscriptions:
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'sprite:highlight-sprites': 'onHighlightSprites'
    'sprite:speech-updated': 'onSpriteSpeechUpdated'
    'surface:frame-changed': 'onFrameChanged'
    'camera:zoom-updated': 'onZoomUpdated'

  constructor: (options) ->
    super()
    options ?= {}
    @camera = options.camera
    @layer = options.layer
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @build()
    @updateDimMask = _.throttle @updateDimMask, 10
    @highlightedThangIDs = []
    @sprites = {}

  toString: -> '<Dimmer>'

  build: ->
    @dimLayer = new createjs.Container()
    @dimLayer.mouseEnabled = @dimLayer.mouseChildren = false
    @dimLayer.addChild @dimScreen = new createjs.Shape()
    @dimLayer.addChild @dimMask = new createjs.Shape()
    @dimScreen.graphics.beginFill('rgba(0,0,0,0.5)').rect 0, 0, @camera.canvasWidth, @camera.canvasHeight
    @dimMask.compositeOperation = 'destination-out'
    @dimLayer.cache 0, 0, @camera.canvasWidth, @camera.canvasHeight

  onDisableControls: (e) ->
    return if @on or (e.controls and not ('surface' in e.controls))
    @dim()

  onEnableControls: (e) ->
    return if not @on or (e.controls and not ('surface' in e.controls))
    @undim()

  onSpriteSpeechUpdated: (e) -> @updateDimMask() if @on
  onFrameChanged: (e) -> @updateDimMask() if @on
  onZoomUpdated: (e) -> @updateDimMask() if @on
  onHighlightSprites: (e) ->
    @highlightedThangIDs = e.thangIDs ? []
    @updateDimMask() if @on

  setSprites: (@sprites) ->

  dim: ->
    @on = true
    @layer.addChild @dimLayer
    @layer.updateLayerOrder()
    sprite.setDimmed true for thangID, sprite of @sprites
    @updateDimMask()

  undim: ->
    @on = false
    @layer.removeChild @dimLayer
    sprite.setDimmed false for thangID, sprite of @sprites

  updateDimMask: =>
    @dimMask.graphics.clear()
    for thangID, sprite of @sprites
      continue unless (thangID in @highlightedThangIDs) or sprite.isTalking?()
      sup = x: sprite.sprite.x, y: sprite.sprite.y
      cap = @camera.surfaceToCanvas sup
      r = 50 * @camera.zoom  # TODO: find better way to get the radius based on the sprite's size
      @dimMask.graphics.beginRadialGradientFill(['rgba(0,0,0,1)', 'rgba(0,0,0,0)'], [0.5, 1], cap.x, cap.y, 0, cap.x, cap.y, r).drawCircle(cap.x, cap.y, r)

    @dimLayer.updateCache 0, 0, @camera.canvasWidth, @camera.canvasHeight
