PAST_PATH_ALPHA = 0.75
PAST_PATH_WIDTH = 5
FUTURE_PATH_ALPHA = 0.75
FUTURE_PATH_WIDTH = 4
TARGET_ALPHA = 1
TARGET_WIDTH = 10
FUTURE_PATH_INTERVAL_DIVISOR = 4
PAST_PATH_INTERVAL_DIVISOR = 2
PET_PATH_COLOR_LIGHT = [216, 180, 254]  # CodeCombat Junior trail gradient: path start
PET_PATH_COLOR_DARK = [123, 31, 162]  # CodeCombat Junior trail gradient: path end
PET_PATH_COLOR_STEPS = 8  # max distinct dot colors along the gradient (spritesheet cache bound)
TEAM_COLORS =
  codecombat:
    neutral: [0, 255, 0]
    humans: [255, 0, 0]
    ogres: [0, 0, 255]
  ozaria:
    neutral: [79, 202, 82]
    humans: [69, 170, 255]
    ogres: [255, 0, 0]

Camera = require './Camera'
CocoClass = require 'core/CocoClass'
createjs = require 'lib/createjs-parts'
utils = require 'core/utils'

module.exports = class TrailMaster extends CocoClass
  world: null

  constructor: (@camera, @layerAdapter, @level) ->
    super()
    @tweenedSprites = []
    @tweens = []

  generatePaths: (@world, @thang) ->
    return if @generatingPaths
    @generatingPaths = true
    @createGraphics()
    pathDisplayObject = new createjs.Container(@layerAdapter.spriteSheet)
    pathDisplayObject.mouseEnabled = pathDisplayObject.mouseChildren = false
    pathDisplayObject.addChild @createFuturePath()
#    pathDisplayObject.addChild @createPastPath() # Just made the animated path the full path... do we want to have past and future look different again?
    pathDisplayObject.addChild @createTargets()
    @generatingPaths = false
    return pathDisplayObject

  cleanUp: ->
    createjs.Tween.removeTweens(sprite) for sprite in @tweenedSprites
    @tweenedSprites = []
    @tweens = []

  createGraphics: ->
    @targetDotKey = @cachePathDot(TARGET_WIDTH, @colorForThang(@thang.team, TARGET_ALPHA), [0, 0, 0, 1])
    @pastDotKey = @cachePathDot(PAST_PATH_WIDTH, @colorForThang(@thang.team, PAST_PATH_ALPHA), [0, 0, 0, 1])
    @futureDotKey = @cachePathDot(FUTURE_PATH_WIDTH, [255, 255, 255, FUTURE_PATH_ALPHA], @colorForThang(@thang.team, 1))
    if @useJuniorGradient()
      # Register every gradient bucket before any dot sprite exists: a first-seen graphic
      # rebuilds the layer spritesheet, destroying the sheet already-created sprites reference
      for step in [0...PET_PATH_COLOR_STEPS]
        color = @petColorAt(step / (PET_PATH_COLOR_STEPS - 1))
        @cachePathDot(TARGET_WIDTH, [color..., TARGET_ALPHA], [0, 0, 0, 1])
        @cachePathDot(FUTURE_PATH_WIDTH, [255, 255, 255, FUTURE_PATH_ALPHA], [color..., 1])

  cachePathDot: (width, fillColor, strokeColor) ->
    key = "path-dot-#{width}-#{fillColor}-#{strokeColor}"
    fillColor = createjs.Graphics.getRGB(fillColor...)
    strokeColor = createjs.Graphics.getRGB(strokeColor...)
    unless key in @layerAdapter.spriteSheet.animations
      circle = new createjs.Shape()
      radius = width/2
      circle.graphics.setStrokeStyle(width/5).beginFill(fillColor).beginStroke(strokeColor).drawCircle(0, 0, radius)
      @layerAdapter.addCustomGraphic(key, circle, [-radius*1.5, -radius*1.5, radius*3, radius*3])
    return key

  colorForThang: (team, alpha=1.0) ->
    palette = if utils.isCodeCombat then TEAM_COLORS.codecombat else TEAM_COLORS.ozaria
    rgb = palette[team] ? palette.neutral
    rgb = PET_PATH_COLOR_DARK if team is 'humans' and utils.isJuniorLevel @level
    return [rgb..., alpha]

  useJuniorGradient: ->
    @thang.team is 'humans' and utils.isJuniorLevel @level

  # Quantized lerp light->dark: at most PET_PATH_COLOR_STEPS distinct colors get cached as dot graphics
  petColorAt: (t) ->
    t = Math.round(t * (PET_PATH_COLOR_STEPS - 1)) / (PET_PATH_COLOR_STEPS - 1)
    for c, j in PET_PATH_COLOR_LIGHT
      Math.round(c + (PET_PATH_COLOR_DARK[j] - c) * t)

  createPastPath: ->
    return unless points = @world.pointsForThang @thang.id, @camera
    interval = Math.max(1, parseInt(@world.frameRate / PAST_PATH_INTERVAL_DIVISOR))
    params = { interval: interval, frameKey: @pastDotKey }
    return @createPath(points, params)

  createFuturePath: ->
    return unless points = @world.pointsForThang @thang.id, @camera
    interval = Math.max(1, parseInt(@world.frameRate / FUTURE_PATH_INTERVAL_DIVISOR))
    params = { interval: interval, animate: true, frameKey: @futureDotKey }
    params.gradientStroke = @useJuniorGradient()
    return @createPath(points, params)

  createTargets: ->
    return unless @thang.allTargets
    container = new createjs.Container(@layerAdapter.spriteSheet)
    numTargets = @thang.allTargets.length / 2
    for x, i in @thang.allTargets by 2
      y = @thang.allTargets[i + 1]
      sup = @camera.worldToSurface x: x, y: y
      sprite = new createjs.Sprite(@layerAdapter.spriteSheet)
      sprite.scaleX = sprite.scaleY = 1 / @layerAdapter.resolutionFactor
      sprite.scaleY *= @camera.y2x
      if @useJuniorGradient()
        t = if numTargets > 1 then (i / 2) / (numTargets - 1) else 0
        graphicsKey = @cachePathDot(TARGET_WIDTH, [@petColorAt(t)..., TARGET_ALPHA], [0, 0, 0, 1])
      else
        graphicsKey = @targetDotKey
      sprite.gotoAndStop(graphicsKey)
      sprite.x = sup.x
      sprite.y = sup.y
      container.addChild(sprite)
    return container

  createPath: (points, options={}) ->
    options = options or {}
    interval = options.interval or 8
    key = options.frameKey or @pastDotKey
    container = new createjs.Container(@layerAdapter.spriteSheet)

    numDots = Math.ceil(points.length / (interval * 2))
    dotIndex = 0
    for x, i in points by interval * 2
      y = points[i + 1]
      if options.gradientStroke
        t = if numDots > 1 then dotIndex / (numDots - 1) else 0
        key = @cachePathDot(FUTURE_PATH_WIDTH, [255, 255, 255, FUTURE_PATH_ALPHA], [@petColorAt(t)..., 1])
      dotIndex++
      sprite = new createjs.Sprite(@layerAdapter.spriteSheet)
      sprite.scaleX = sprite.scaleY = 1 / @layerAdapter.resolutionFactor
      sprite.scaleY *= @camera.y2x
      sprite.gotoAndStop(key)
      sprite.x = x
      sprite.y = y
      container.addChild(sprite)
      if lastSprite and options.animate
        tween = createjs.Tween.get(lastSprite, {loop: true}).to({x:x, y:y}, 1000)
        @tweenedSprites.push lastSprite
        @tweens.push tween
      lastSprite = sprite

    @logged = true
    container

  play: ->
    tween.paused = false for tween in @tweens

  stop: ->
    tween.paused = true for tween in @tweens

  destroy: ->
    @cleanUp()
    super()
