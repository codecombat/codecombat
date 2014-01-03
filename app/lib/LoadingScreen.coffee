CocoClass = require 'lib/CocoClass'

module.exports = class LoadingScreen extends CocoClass
  progress: 0
  
  constructor: (canvas) ->
    super()
    @width = canvas.width
    @height = canvas.height
    @stage = new createjs.Stage(canvas)

  subscriptions:
    'level-loader:progress-changed': 'onLevelLoaderProgressChanged'

  show: ->
    @stage.removeChild(@screen) if @screen
    @screen = @makeScreen()
    @stage.addChild(@screen)
    @updateProgressBar()

  hide: ->
    @stage.removeChild(@screen) if @screen
    @screen = null

  makeScreen: ->
    c = new createjs.Container()
    c.addChild(@makeLoadBackground())
    c.addChild(@makeLoadText())
    c.addChild(@makeProgressBar())
    @makeLoadLogo(c)
    c

  makeLoadBackground: ->
    g = new createjs.Graphics()
    g.beginFill(createjs.Graphics.getRGB(30,30,60))
    g.drawRoundRect(0, 0, @width, @height, 0.0)
    s = new createjs.Shape(g)
    s.y = 0
    s.x = 0
    s

  makeLoadLogo: (container) ->
    logoImage = new Image()
    $(logoImage).load =>
      @logo = new createjs.Bitmap logoImage
      @logo.x = @width / 2 - logoImage.width / 2
      @logo.y = 40
      container.addChild @logo
    logoImage.src = "/images/loading_image.png"

  makeLoadText: ->
    size = @height / 10
    text = new createjs.Text("LOADING", "#{size}px Monospace", "#ff7700")
    text.regX = text.getMeasuredWidth() / 2
    text.regY = text.getMeasuredHeight() / 2
    text.x = @width / 2
    text.y = @height / 2
    @text = text
    return text

  makeProgressBar: ->
    BAR_PIXEL_HEIGHT = 20
    BAR_PCT_WIDTH = .75
    pixelWidth = parseInt(@width * BAR_PCT_WIDTH)
    pixelMargin = (@width - (@width * BAR_PCT_WIDTH)) / 2
    barY = 2 * (@height / 3)

    c = new createjs.Container()
    c.x = pixelMargin
    c.y = barY

    g = new createjs.Graphics()
    g.beginFill(createjs.Graphics.getRGB(255,0,0))
    g.drawRoundRect(0,0,pixelWidth, BAR_PIXEL_HEIGHT, 5)
    @progressBar = new createjs.Shape(g)
    c.addChild(@progressBar)

    g = new createjs.Graphics()
    g.setStrokeStyle(2)
    g.beginStroke(createjs.Graphics.getRGB(230,230,230))
    g.drawRoundRect(0,0,pixelWidth, BAR_PIXEL_HEIGHT, 5)
    c.addChild(new createjs.Shape(g))
    c

  onLevelLoaderProgressChanged: (e) ->
    @progress = e.progress
    @updateProgressBar()

  updateProgressBar: ->
    newProg = parseInt((@progress or 0) * 100)
    newProg = ' '+newProg while newProg.length < 4
    @lastProg = newProg
    @text.text = "BUILDING" if @progress is 1
    @progressBar.scaleX = @progress
    @stage.update()
  
  destroy: ->
    @stage.canvas = null
    super() 