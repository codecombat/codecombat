CocoClass = require 'lib/CocoClass'

module.exports = class CastingScreen extends CocoClass
  subscriptions:
    'tome:cast-spells': 'onCastingBegins'
    'god:new-world-created': 'onCastingEnds'
    'god:world-load-progress-changed': 'onWorldLoadProgressChanged'

  constructor: (options) ->
    super()
    options ?= {}
    @camera = options.camera
    @layer = options.layer
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @build()

  onCastingBegins: (e) -> @show() unless e.preload
  onCastingEnds: (e) -> @hide()

  toString: -> '<CastingScreen>'

  build: ->
    @dimLayer = new createjs.Container()
    @dimLayer.mouseEnabled = @dimLayer.mouseChildren = false
    @dimLayer.layerIndex = -11
    @dimLayer.addChild @dimScreen = new createjs.Shape()
    @dimScreen.graphics.beginFill('rgba(0,0,0,0.5)').rect 0, 0, @camera.canvasWidth, @camera.canvasHeight
    @dimLayer.alpha = 0
    @layer.addChild @dimLayer
    @dimLayer.addChild @makeProgressBar()
    @dimLayer.addChild @makeCastingText()

  onWorldLoadProgressChanged: (e) ->
    if new Date().getTime() - @t0 > 500
      createjs.Tween.removeTweens @progressBar
      createjs.Tween.get(@progressBar).to({scaleX: e.progress}, 200)

  makeProgressBar: ->
    BAR_PIXEL_HEIGHT = 3
    BAR_PCT_WIDTH = .75
    pixelWidth = parseInt(@camera.canvasWidth * BAR_PCT_WIDTH)
    pixelMargin = (@camera.canvasWidth - (@camera.canvasWidth * BAR_PCT_WIDTH)) / 2
    barY = 3 * (@camera.canvasHeight / 5)

    g = new createjs.Graphics()
    g.beginFill(createjs.Graphics.getRGB(255, 255, 255))
    g.drawRoundRect(0, 0, pixelWidth, BAR_PIXEL_HEIGHT, 3)
    @progressBar = new createjs.Shape(g)
    @progressBar.x = pixelMargin
    @progressBar.y = barY
    @progressBar.scaleX = 0
    @dimLayer.addChild(@progressBar)

  makeCastingText: ->
    size = @camera.canvasHeight / 15
    text = new createjs.Text('Casting', "#{size}px cursive", '#aaaaaa')
    text.regX = text.getMeasuredWidth() / 2
    text.regY = text.getMeasuredHeight() / 2
    text.x = @camera.canvasWidth / 2
    text.y = @camera.canvasHeight / 2
    @text = text
    return text

  show: ->
    return if @showing
    @showing = true
    @t0 = new Date().getTime()

    @progressBar.scaleX = 0
    @dimLayer.alpha = 0
    createjs.Tween.removeTweens @dimLayer
    createjs.Tween.get(@dimLayer).to({alpha: 1}, 500)

  hide: ->
    return unless @showing
    @showing = false

    createjs.Tween.removeTweens @progressBar
    createjs.Tween.removeTweens @dimLayer
    createjs.Tween.get(@dimLayer).to({alpha: 0}, 500)
