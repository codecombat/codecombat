PAST_PATH_ALPHA = 0.75
PAST_PATH_WIDTH = 5
FUTURE_PATH_ALPHA = 0.4
FUTURE_PATH_WIDTH = 2

Camera = require './Camera'
CocoClass = require 'lib/CocoClass'

module.exports = class TrailMaster extends CocoClass
  paths: null # dictionary of thang ids to containers for their paths
  pathDisplayObject: null
  world: null
  
  constructor: (@camera, @layerAdapter) ->
    super()
    @tweenedSprites = []
    @listenTo @layerAdapter, 'new-spritesheet', -> @generatePaths(@world, @thang)

  generatePaths: (@world, @thang) ->
    return if @generatingPaths
    @generatingPaths = true
    @cleanUp()
    @createGraphics()
    @pathDisplayObject = new createjs.SpriteContainer(@layerAdapter.spriteSheet)
    @pathDisplayObject.mouseEnabled = @pathDisplayObject.mouseChildren = false
    @pathDisplayObject.addChild @createFuturePath()
#    @pathDisplayObject.addChild @createPastPath() # Just made the animated path the full path... do we want to have past and future look different again?
    @pathDisplayObject.addChild @createTargets()
    @generatingPaths = false
    return @pathDisplayObject
    
  cleanUp: ->
    createjs.Tween.removeTweens(sprite) for sprite in @tweenedSprites
    @tweenedSprites = []

  createGraphics: ->
    color = @colorForThang(@thang.team, PAST_PATH_ALPHA)
    @targetDotKey = @cachePathDot(10, color)
    @pastDotKey = @cachePathDot(PAST_PATH_WIDTH, color)
    @futureDotKey = @cachePathDot(FUTURE_PATH_WIDTH, @colorForThang(@thang.team, FUTURE_PATH_ALPHA))
    
  cachePathDot: (width, color) ->
    key = "path-dot-#{width}-#{color}"
    color = createjs.Graphics.getRGB(color...)
    unless key in @layerAdapter.spriteSheet.getAnimations()
      circle = new createjs.Shape()
      radius = width/2
      circle.graphics.setStrokeStyle(1).beginFill(color).beginStroke('#000000').drawCircle(0, 0, radius)
      @layerAdapter.addCustomGraphic(key, circle, [-radius*1.5, -radius*1.5, radius*3, radius*3])
    return key

  colorForThang: (team, alpha=1.0) ->
    rgb = [0, 255, 0]
    rgb = [255, 0, 0] if team is 'humans'
    rgb = [0, 0, 255] if team is 'ogres'
    rgb.push(alpha)
    return rgb
      
  createPastPath: ->
    return unless points = @world.pointsForThang @thang.id, @camera
    params = { interval: 8, frameKey: @pastDotKey }
    return @createPath(points, params)

  createFuturePath: ->
    return unless points = @world.pointsForThang @thang.id, @camera
    interval = Math.max(1, parseInt(@world.frameRate / 4))
    params = { interval: interval, animate: true, frameKey: @futureDotKey }
    return @createPath(points, params)

  createTargets: ->
    return unless @thang.allTargets
    container = new createjs.SpriteContainer(@layerAdapter.spriteSheet)
    for x, i in @thang.allTargets by 2
      y = @thang.allTargets[i + 1]
      sup = @camera.worldToSurface x: x, y: y
      sprite = new createjs.Sprite(@layerAdapter.spriteSheet)
      sprite.scaleX = sprite.scaleY = 1 / @layerAdapter.resolutionFactor
      sprite.gotoAndStop(@targetDotKey)
      sprite.x = sup.x
      sprite.y = sup.y
      container.addChild(sprite)
    return container
  
  createPath: (points, options={}) ->
    options = options or {}
    interval = options.interval or 8
    key = options.frameKey or @pastDotKey
    container = new createjs.SpriteContainer(@layerAdapter.spriteSheet)
      
    for x, i in points by interval * 2
      y = points[i + 1]
      sprite = new createjs.Sprite(@layerAdapter.spriteSheet)
      sprite.scaleX = sprite.scaleY = 1 / @layerAdapter.resolutionFactor
      sprite.gotoAndStop(key)
      sprite.x = x
      sprite.y = y
      container.addChild(sprite)
      if lastSprite and options.animate
        createjs.Tween.get(lastSprite, {loop: true}).to({x:x, y:y}, 1000)
        @tweenedSprites.push lastSprite
      lastSprite = sprite
      
    @logged = true
    container
  
  destroy: ->
    @cleanUp()
    super()
