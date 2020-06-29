###
  * SpriteStage (WebGL Canvas)
  ** Land texture
  ** Ground-based selection/target marks, range radii
  ** Walls/obstacles
  ** Paths and target pieces (and ghosts?)
  ** Normal Thangs, bots, wizards (z-indexing based on World-determined sprite.thang.pos.z/y, mainly, instead of sprite-map-determined sprite.z, which we rename to... something)
  ** Above-thang marks (blood, highlight) and health bars

  * Stage (Regular Canvas)
  ** Camera border
  ** surfaceTextLayer (speech, names)
  ** screenLayer
  *** Letterbox
  **** Letterbox top and bottom
  *** FPS display, maybe grid axis labels, coordinate hover

  ** Grid lines--somewhere--we will figure it out, do not really need it at first
###

SpriteBuilder = require 'lib/sprites/SpriteBuilder'
CocoClass = require 'core/CocoClass'
SegmentedSprite = require './SegmentedSprite'
SingularSprite = require './SingularSprite'
ThangType = require 'models/ThangType'
createjs = require 'lib/createjs-parts'
utils = require 'core/utils'

NEVER_RENDER_ANYTHING = false # set to true to test placeholders

module.exports = LayerAdapter = class LayerAdapter extends CocoClass

  # Intermediary between a Surface Stage and a top-level static normal Container (used to also do hot-swapped WebGL SpriteContainer).
  # It handles zooming in different ways and, if webGL, creating and assigning spriteSheets.

  @TRANSFORM_SURFACE: 'surface'  # Layer moves/scales/zooms with the Surface of the World
  @TRANSFORM_SURFACE_TEXT: 'surface_text'  # Layer moves with the Surface but is size-independent
  @TRANSFORM_SCREEN: 'screen'  # Layer stays fixed to the screen

  # WebGL properties
  actionRenderState: null
  needToRerender: false
  toRenderBundles: null
  willRender: false
  buildAutomatically: true
  buildAsync: true
  resolutionFactor: SPRITE_RESOLUTION_FACTOR
  numThingsLoading: 0
  lanks: null
  spriteSheet: null
  container: null
  customGraphics: null

  subscriptions:
    'camera:zoom-updated': 'onZoomUpdated'

  constructor: (options) ->
    super()
    options ?= {}
    @name = options.name ? 'Unnamed'
    @defaultSpriteType = if @name is 'Default' then 'segmented' else 'singular'
    @customGraphics = {}
    @layerPriority = options.layerPriority ? 0
    @transformStyle = options.transform ? LayerAdapter.TRANSFORM_SURFACE
    @camera = options.camera
    @updateLayerOrder = _.throttle @updateLayerOrder, 1000 / 30  # Don't call multiple times in one frame; 30 FPS is probably good enough

    @webGL = !!options.webGL
    if @webGL
      @initializing = true
      @spriteSheet = @_renderNewSpriteSheet(false) # builds an empty spritesheet
      @container = new createjs.Container(@spriteSheet)
      @actionRenderState = {}
      @toRenderBundles = []
      @lanks = []
      @initializing = false

    else
      @container = new createjs.Container()

  toString: -> "<Layer #{@layerPriority}: #{@name}>"

  #- Layer ordering

  updateLayerOrder: ->
    return if @destroyed
    @container.sortChildren @layerOrderComparator

  layerOrderComparator: (a, b) ->
    # Optimize
    alp = a.layerPriority or 0
    blp = b.layerPriority or 0
    return alp - blp if alp isnt blp
    # TODO: remove this z stuff
    az = a.z or 1000
    bz = b.z or 1000
    if aLank = a.lank
      if aThang = aLank.thang
        aPos = aThang.pos
        if aThang.health < 0 and aThang.pos.z <= aThang.depth / 2
          # Nice for not being knee deep in the dead, just not nice for ogres flying behind trees when exploded
          --az
    if bLank = b.lank
      if bThang = bLank.thang
        bPos = bThang.pos
        if bThang.health < 0 and bThang.pos.z <= bThang.depth / 2
          --bz
    if az is bz
      return 0 unless aPos and bPos
      return (bPos.y - aPos.y) or (bPos.x - aPos.x)
    return az - bz

  #- Zoom updating

  onZoomUpdated: (e) ->
    return unless e.camera is @camera
    if @transformStyle in [LayerAdapter.TRANSFORM_SURFACE, LayerAdapter.TRANSFORM_SURFACE_TEXT]
      change = @container.scaleX / e.zoom
      @container.scaleX = @container.scaleY = e.zoom
      if @webGL
        @container.scaleX *= @camera.canvasScaleFactorX
        @container.scaleY *= @camera.canvasScaleFactorY
      @container.regX = e.surfaceViewport.x
      @container.regY = e.surfaceViewport.y
      if @transformStyle is LayerAdapter.TRANSFORM_SURFACE_TEXT
        for child in @container.children
          continue if child.skipScaling
          child.scaleX *= change
          child.scaleY *= change

  #- Container-like child functions

  addChild: (children...) ->
    @container.addChild children...
    if @transformStyle is LayerAdapter.TRANSFORM_SURFACE_TEXT
      for child in children
        continue if child.skipScaling
        child.scaleX /= @container.scaleX
        child.scaleY /= @container.scaleY

  removeChild: (children...) ->
    @container.removeChild children...
    # TODO: Do we actually need to scale children that were removed?
    if @transformStyle is LayerAdapter.TRANSFORM_SURFACE_TEXT
      for child in children
        child.scaleX *= @container.scaleX
        child.scaleY *= @container.scaleY

  #- Adding, removing children for WebGL layers.

  addLank: (lank) ->
    lank.options.resolutionFactor = @resolutionFactor
    lank.layer = @
    @listenTo(lank, 'action-needs-render', @onActionNeedsRender)
    @lanks.push lank
    lank.thangType.initPrerenderedSpriteSheets() unless utils.getQueryVariable 'jitSpritesheets'
    prerenderedSpriteSheet = lank.thangType.getPrerenderedSpriteSheet(lank.options.colorConfig, @defaultSpriteType)
    prerenderedSpriteSheet?.markToLoad()
    @loadThangType(lank.thangType)
    @addDefaultActionsToRender(lank)
    @setSpriteToLank(lank)
    @updateLayerOrder()
    lank.addHealthBar()

  removeLank: (lank) ->
    @stopListening(lank)
    lank.layer = null
    @container.removeChild lank.sprite
    @lanks = _.without @lanks, lank

  #- Loading network resources dynamically

  loadThangType: (thangType) ->
    if not thangType.isFullyLoaded()
      thangType.setProjection null
      thangType.fetch() unless thangType.loading
      @numThingsLoading++
      @listenToOnce(thangType, 'sync', @somethingLoaded)
    else if thangType.get('raster') and not thangType.loadedRaster
      thangType.loadRasterImage()
      @listenToOnce(thangType, 'raster-image-loaded', @somethingLoaded)
      @numThingsLoading++
    else if prerenderedSpriteSheet = thangType.getPrerenderedSpriteSheetToLoad()
      startedLoading = prerenderedSpriteSheet.loadImage()
      return if not startedLoading
      @listenToOnce(prerenderedSpriteSheet, 'image-loaded', -> @somethingLoaded(thangType))
      @numThingsLoading++

  somethingLoaded: (thangType) ->
    @numThingsLoading--
    @loadThangType(thangType) # might need to load the raster image object
    for lank in @lanks
      if lank.thangType is thangType
        @addDefaultActionsToRender(lank)
    @renderNewSpriteSheet()

  #- Adding to the list of things we need to render

  onActionNeedsRender: (lank, action) ->
    @upsertActionToRender(lank.thangType, action.name, lank.options.colorConfig)

  addDefaultActionsToRender: (lank) ->
    needToRender = false
    if lank.thangType.get('raster')
      @upsertActionToRender(lank.thangType)
    else
      for action in _.values(lank.thangType.getActions())
        continue unless _.any ThangType.defaultActions, (prefix) -> _.string.startsWith(action.name, prefix)
        @upsertActionToRender(lank.thangType, action.name, lank.options.colorConfig)

  upsertActionToRender: (thangType, actionName, colorConfig) ->
    groupKey = @renderGroupingKey(thangType, actionName, colorConfig)
    return false if @actionRenderState[groupKey] isnt undefined
    @actionRenderState[groupKey] = 'need-to-render'
    @toRenderBundles.push({thangType: thangType, actionName: actionName, colorConfig: colorConfig})
    return true if @willRender or not @buildAutomatically
    @willRender = _.defer => @renderNewSpriteSheet()
    return true

  addCustomGraphic: (key, graphic, bounds) ->
    return false if @customGraphics[key]
    @customGraphics[key] = { graphic: graphic, bounds: new createjs.Rectangle(bounds...) }
    return true if @willRender or not @buildAutomatically
    @_renderNewSpriteSheet(false)

  #- Rendering sprite sheets

  renderNewSpriteSheet: ->
    @willRender = false
    return if @numThingsLoading
    @_renderNewSpriteSheet()

  _renderNewSpriteSheet: (async) ->
    @asyncBuilder.stopAsync() if @asyncBuilder
    @asyncBuilder = null

    async ?= @buildAsync
    builder = new createjs.SpriteSheetBuilder()
    groups = _.groupBy(@toRenderBundles, ((bundle) -> @renderGroupingKey(bundle.thangType, '', bundle.colorConfig)), @)

    # The first frame is always the 'loading', ie placeholder, image.
    placeholder = @createPlaceholder()
    dimension = @resolutionFactor * SPRITE_PLACEHOLDER_WIDTH
    placeholder.setBounds(0, 0, dimension, dimension)
    builder.addFrame(placeholder)

    # Add custom graphics
    extantGraphics = if @spriteSheet?.resolutionFactor is @resolutionFactor then @spriteSheet.animations else []
    for key, graphic of @customGraphics
      if key in extantGraphics
        graphic = new createjs.Sprite(@spriteSheet)
        graphic.gotoAndStop(key)
        frame = builder.addFrame(graphic)
      else
        frame = builder.addFrame(graphic.graphic, graphic.bounds, @resolutionFactor)
      builder.addAnimation(key, [frame], false)

    # Render ThangTypes
    groups = {} if NEVER_RENDER_ANYTHING
    for bundleGrouping in _.values(groups)
      thangType = bundleGrouping[0].thangType
      colorConfig = bundleGrouping[0].colorConfig
      actionNames = (bundle.actionName for bundle in bundleGrouping)
      args = [thangType, colorConfig, actionNames, builder]
      if thangType.get('raw') or thangType.get('prerenderedSpriteSheetData')
        if (thangType.get('spriteType') or @defaultSpriteType) is 'segmented'
          @renderSegmentedThangType(args...)
        else
          @renderSingularThangType(args...)
      else
        @renderRasterThangType(thangType, builder)

    if async
      try
        builder.buildAsync()
      catch e
        @resolutionFactor *= 0.9
        return @_renderNewSpriteSheet(async)
      builder.on 'complete', @onBuildSpriteSheetComplete, @, true, builder
      @asyncBuilder = builder
    else
      try
        sheet = builder.build()
      catch e
        @resolutionFactor *= 0.9
        return @_renderNewSpriteSheet(async)
      @onBuildSpriteSheetComplete({async:async}, builder)
      return sheet

  onBuildSpriteSheetComplete: (e, builder) ->
    return if @initializing or @destroyed
    @asyncBuilder = null

    @spriteSheet = builder.spriteSheet
    @spriteSheet.resolutionFactor = @resolutionFactor
    oldLayer = @container
    @container = new createjs.Container(@spriteSheet)
    for lank in @lanks
      console.log 'zombie sprite found on layer', @name if lank.destroyed
      continue if lank.destroyed
      @setSpriteToLank(lank)
    for prop in ['scaleX', 'scaleY', 'regX', 'regY']
      @container[prop] = oldLayer[prop]
    if parent = oldLayer.parent
      index = parent.getChildIndex(oldLayer)
      parent.removeChildAt(index)
      parent.addChildAt(@container, index)
    @camera?.updateZoom(true)
    @updateLayerOrder()
    for lank in @lanks
      lank.options.resolutionFactor = @resolutionFactor
      lank.updateScale()
      lank.updateRotation()
    @trigger 'new-spritesheet'

  resetSpriteSheet: ->
    @removeLank(lank) for lank in @lanks.slice(0)
    @toRenderBundles = []
    @actionRenderState = {}
    @initializing = true
    @spriteSheet = @_renderNewSpriteSheet(false) # builds an empty spritesheet
    @initializing = false

  #- Placeholder

  createPlaceholder: ->
    # TODO: Experiment with this. Perhaps have rectangles if default layer is obstacle or floor,
    # and different colors for different layers.
    g = new createjs.Graphics()
    g.setStrokeStyle(5)
    color = {
      'Land': [0, 50, 0]
      'Ground': [230, 230, 230]
      'Obstacle': [20, 70, 20]
      'Path': [200, 100, 200]
      'Default': [64, 64, 64]
      'Floating': [100, 100, 200]
    }[@name] or [0, 0, 0]
    g.beginStroke(createjs.Graphics.getRGB(color...))
    color.push 0.7
    g.beginFill(createjs.Graphics.getRGB(color...))
    width = @resolutionFactor * SPRITE_PLACEHOLDER_WIDTH
    bounds = [0, 0, width, width]
    if @name in ['Default', 'Ground', 'Floating', 'Path']
      g.drawEllipse(bounds...)
    else
      g.drawRect(bounds...)
    new createjs.Shape(g)

  #- Rendering containers for segmented thang types

  renderSegmentedThangType: (thangType, colorConfig, actionNames, spriteSheetBuilder) ->
    prerenderedSpriteSheet = thangType.getPrerenderedSpriteSheet(colorConfig, 'segmented')
    if prerenderedSpriteSheet and not prerenderedSpriteSheet.loadedImage
      return
    else if prerenderedSpriteSheet
      animations = prerenderedSpriteSheet.spriteSheet._animations
      renderedActions = _.zipObject(animations, _.times(animations.length, -> true))
    containersToRender = thangType.getContainersForActions(actionNames)
    #console.log 'render segmented', thangType.get('name'), actionNames, colorConfig, 'because we do not have prerendered sprite sheet?', prerenderedSpriteSheet
    spriteBuilder = new SpriteBuilder(thangType, {colorConfig: colorConfig})
    for containerGlobalName in containersToRender
      containerKey = @renderGroupingKey(thangType, containerGlobalName, colorConfig)
      if @spriteSheet?.resolutionFactor is @resolutionFactor and containerKey in @spriteSheet.animations
        container = new createjs.Sprite(@spriteSheet)
        container.gotoAndStop(containerKey)
        frame = spriteSheetBuilder.addFrame(container)
      else if prerenderedSpriteSheet and renderedActions[containerGlobalName]
        container = new createjs.Sprite(prerenderedSpriteSheet.spriteSheet)
        container.gotoAndStop(containerGlobalName)
        scale = @resolutionFactor / (prerenderedSpriteSheet.get('resolutionFactor') or 1)
        frame = spriteSheetBuilder.addFrame(container, null, scale)
      else
        container = spriteBuilder.buildContainerFromStore(containerGlobalName)
        frame = spriteSheetBuilder.addFrame(container, null, @resolutionFactor * (thangType.get('scale') or 1))
      spriteSheetBuilder.addAnimation(containerKey, [frame], false)


  #- Rendering sprite sheets for singular thang types

  renderSingularThangType: (thangType, colorConfig, actionNames, spriteSheetBuilder) ->
    prerenderedSpriteSheet = thangType.getPrerenderedSpriteSheet(colorConfig, 'singular')
    prerenderedFramesMap = {}
    if prerenderedSpriteSheet
      if not prerenderedSpriteSheet.loadedImage
        return
      scale = @resolutionFactor / (prerenderedSpriteSheet.get('resolutionFactor') or 1)
      for frame, i in prerenderedSpriteSheet.spriteSheet._frames
        sprite = new createjs.Sprite(prerenderedSpriteSheet.spriteSheet)
        sprite.gotoAndStop(i)
        prerenderedFramesMap[i] = spriteSheetBuilder.addFrame(sprite, null, scale)
    #else
    #  console.log '    Rerendering singular thang type', thangType.get('name'), thangType.get('spriteType'), colorConfig, actionNames

    actionObjects = _.values(thangType.getActions())
    animationActions = []
    for a in actionObjects
      continue unless a.animation
      continue unless a.name in actionNames
      animationActions.push(a)

    spriteBuilder = new SpriteBuilder(thangType, {colorConfig: colorConfig})

    animationGroups = _.groupBy animationActions, (action) -> action.animation
    for animationName, actions of animationGroups
      renderAll = _.any actions, (action) -> action.frames is undefined
      scale = actions[0].scale or thangType.get('scale') or 1

      actionKeys = (@renderGroupingKey(thangType, action.name, colorConfig) for action in actions)
      if @spriteSheet?.resolutionFactor is @resolutionFactor and _.all(actionKeys, (key) => key in @spriteSheet.animations)
        framesNeeded = _.uniq(_.flatten((@spriteSheet.getAnimation(key)).frames for key in actionKeys))
        framesMap = {}
        for frame in framesNeeded
          sprite = new createjs.Sprite(@spriteSheet)
          sprite.gotoAndStop(frame)
          framesMap[frame] = spriteSheetBuilder.addFrame(sprite)
        for key, index in actionKeys
          action = actions[index]
          frames = (framesMap[f] for f in @spriteSheet.getAnimation(key).frames)
          next = thangType.nextForAction(action)
          spriteSheetBuilder.addAnimation(key, frames, next)
        continue

      if prerenderedSpriteSheet
        for action in actions
          name = @renderGroupingKey(thangType, action.name, colorConfig)
          prerenderedFrames = prerenderedSpriteSheet.get('animations')?[action.name]?.frames
          continue if not prerenderedFrames
          frames = (prerenderedFramesMap[frame] for frame in prerenderedFrames)
          next = thangType.nextForAction(action)
          spriteSheetBuilder.addAnimation(name, frames, next)
        continue

      mc = spriteBuilder.buildMovieClip(animationName, null, null, null, {'temp':0})

      if renderAll
        res = spriteSheetBuilder.addMovieClip(mc, null, scale * @resolutionFactor)
        frames = spriteSheetBuilder._animations['temp'].frames
        framesMap = _.zipObject _.range(frames.length), frames
      else
        framesMap = {}
        framesToRender = _.uniq(_.flatten((a.frames.split(',') for a in actions)))
        for frame in framesToRender
          frame = parseInt(frame)
          f = _.bind(mc.gotoAndStop, mc, frame)
          framesMap[frame] = spriteSheetBuilder.addFrame(mc, null, scale * @resolutionFactor, f)

      for action in actions
        name = @renderGroupingKey(thangType, action.name, colorConfig)

        if action.frames
          frames = (framesMap[parseInt(frame)] for frame in action.frames.split(','))
        else
          frames = _.sortBy(_.values(framesMap))
        next = thangType.nextForAction(action)
        spriteSheetBuilder.addAnimation(name, frames, next)

    containerActions = []
    for a in actionObjects
      continue unless a.container
      continue unless a.name in actionNames
      containerActions.push(a)

    containerGroups = _.groupBy containerActions, (action) -> action.container
    for containerName, actions of containerGroups
      if prerenderedSpriteSheet
        for action in actions
          name = @renderGroupingKey(thangType, action.name, colorConfig)
          prerenderedFrames = prerenderedSpriteSheet.get('animations')?[action.name]?.frames
          continue if not prerenderedFrames
          frame = prerenderedFramesMap[prerenderedFrames[0]]
          spriteSheetBuilder.addAnimation(name, [frame], false)
        continue
      container = spriteBuilder.buildContainerFromStore(containerName)
      scale = actions[0].scale or thangType.get('scale') or 1
      frame = spriteSheetBuilder.addFrame(container, null, scale * @resolutionFactor)
      for action in actions
        name = @renderGroupingKey(thangType, action.name, colorConfig)
        spriteSheetBuilder.addAnimation(name, [frame], false)

  #- Rendering frames for raster thang types

  renderRasterThangType: (thangType, spriteSheetBuilder) ->
    unless thangType.rasterImage
      console.error("Cannot render the LayerAdapter SpriteSheet until the raster image for <#{thangType.get('name')}> is loaded.")

    # hack for IE9, otherwise width/height are not set
    $img = $(thangType.rasterImage[0])
    $('body').append($img)

    bm = new createjs.Bitmap(thangType.rasterImage[0])
    scale = thangType.get('scale') or 1
    frame = spriteSheetBuilder.addFrame(bm, null, scale)
    spriteSheetBuilder.addAnimation(@renderGroupingKey(thangType), [frame], false)
    $img.remove()

  #- Distributing new Segmented/Singular/RasterSprites to Lanks

  setSpriteToLank: (lank) ->
    if not lank.thangType.isFullyLoaded()
      # just give a placeholder
      sprite = new createjs.Sprite(@spriteSheet)
      sprite.gotoAndStop(0)
      sprite.placeholder = true
      sprite.regX = @resolutionFactor * SPRITE_PLACEHOLDER_WIDTH / 2
      sprite.regY = @resolutionFactor * SPRITE_PLACEHOLDER_WIDTH
      sprite.baseScaleX = sprite.baseScaleY = sprite.scaleX = sprite.scaleY = 10 / (@resolutionFactor * SPRITE_PLACEHOLDER_WIDTH)

    else if lank.thangType.get('raster')
      sprite = new createjs.Sprite(@spriteSheet)
      scale = lank.thangType.get('scale') or 1
      reg = lank.getOffset 'registration'
      sprite.regX = -reg.x * scale
      sprite.regY = -reg.y * scale
      sprite.gotoAndStop(@renderGroupingKey(lank.thangType))
      sprite.baseScaleX = sprite.baseScaleY = 1

    else
      SpriteClass = if (lank.thangType.get('spriteType') or @defaultSpriteType) is 'segmented' then SegmentedSprite else SingularSprite
      prefix = @renderGroupingKey(lank.thangType, null, lank.options.colorConfig) + '.'
      sprite = new SpriteClass(@spriteSheet, lank.thangType, prefix, @resolutionFactor)

    sprite.lank = lank
    sprite.camera = @camera
    sprite.layerPriority = lank.thang?.layerPriority ? lank.thangType.get 'layerPriority'
    sprite.name = lank.thang?.spriteName or lank.thangType.get 'name'
    lank.setSprite(sprite)
    lank.update(true)
    @container.addChild(sprite)
    lank.updateScale true if lank.thangType.get 'matchWorldDimensions'  # Otherwise it's at the wrong scale for some reason.

  renderGroupingKey: (thangType, grouping, colorConfig) ->
    key = thangType.get('slug')
    for colorKey, colorValue of colorConfig ? {}
      key += "(#{colorKey}:#{colorValue.hue},#{colorValue.saturation},#{colorValue.lightness})"
    key += '.'+grouping if grouping
    key

  destroy: ->
    child.destroy?() for child in @container.children
    @asyncBuilder.stopAsync() if @asyncBuilder
    super()
