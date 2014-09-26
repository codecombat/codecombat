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
CocoClass = require 'lib/CocoClass'
SegmentedSprite = require './SegmentedSprite'
SingularSprite = require './SingularSprite'

NEVER_RENDER_ANYTHING = false # set to true to test placeholders

module.exports = LayerAdapter = class LayerAdapter extends CocoClass
  
  # Intermediary between a Surface Stage and a top-level static normal Container or hot-swapped WebGL SpriteContainer.
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
  defaultActions: ['idle', 'die', 'move', 'move', 'attack']
  numThingsLoading: 0
  cocoSprites: null
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
      @container = new createjs.SpriteContainer(@spriteSheet)
      @actionRenderState = {}
      @toRenderBundles = []
      @cocoSprites = []
      @initializing = false

    else
      @container = new createjs.Container()

  toString: -> "<Layer #{@layerPriority}: #{@name}>"

  #- Layer ordering
    
  updateLayerOrder: ->
    @container.sortChildren @layerOrderComparator

  layerOrderComparator: (a, b) ->
    # Optimize
    alp = a.layerPriority or 0
    blp = b.layerPriority or 0
    return alp - blp if alp isnt blp
    # TODO: remove this z stuff
    az = a.z or 1000
    bz = b.z or 1000
    if aSprite = a.sprite
      if aThang = aSprite.thang
        aPos = aThang.pos
        if aThang.health < 0
          --az
    if bSprite = b.sprite
      if bThang = bSprite.thang
        bPos = bThang.pos
        if bThang.health < 0
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
          child.scaleX *= change
          child.scaleY *= change

  #- Container-like child functions

  addChild: (children...) ->
    @container.addChild children...
    if @transformStyle is LayerAdapter.TRANSFORM_SURFACE_TEXT
      for child in children
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
        
  addCocoSprite: (cocoSprite) ->
    # TODO: Move this into the production DB rather than setting it dynamically.
    if cocoSprite.thangType?.get('name') is 'Highlight'
      cocoSprite.thangType.set('spriteType', 'segmented')
    cocoSprite.options.resolutionFactor = @resolutionFactor
    if cocoSprite.layer
      console.warn 'CocoSprite being re-added to a layer?'
    
    cocoSprite.layer = @
    @listenTo(cocoSprite, 'action-needs-render', @onActionNeedsRender)
    @cocoSprites.push cocoSprite
    @loadThangType(cocoSprite.thangType)
    @addDefaultActionsToRender(cocoSprite)
    @setImageObjectToCocoSprite(cocoSprite)
    @updateLayerOrder()
    cocoSprite.addHealthBar()

  removeCocoSprite: (cocoSprite) ->
    @stopListening(cocoSprite)
    @container.removeChild cocoSprite.imageObject
    @cocoSprites = _.without @cocoSprites, cocoSprite

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

  somethingLoaded: (thangType) ->
    @numThingsLoading--
    @loadThangType(thangType) # might need to load the raster image object
    for cocoSprite in @cocoSprites
      if cocoSprite.thangType is thangType
        @addDefaultActionsToRender(cocoSprite)
    @renderNewSpriteSheet()

  #- Adding to the list of things we need to render
    
  onActionNeedsRender: (cocoSprite, action) ->
    @upsertActionToRender(cocoSprite.thangType, action.name, cocoSprite.options.colorConfig)

  addDefaultActionsToRender: (cocoSprite) ->
    needToRender = false
    if cocoSprite.thangType.get('raster')
      @upsertActionToRender(cocoSprite.thangType)
    else
      for action in _.values(cocoSprite.thangType.getActions())
        continue unless _.any @defaultActions, (prefix) -> action.name.startsWith(prefix)
        @upsertActionToRender(cocoSprite.thangType, action.name, cocoSprite.options.colorConfig)

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
    async ?= @buildAsync
    builder = new createjs.SpriteSheetBuilder()
    groups = _.groupBy(@toRenderBundles, ((bundle) -> @renderGroupingKey(bundle.thangType, '', bundle.colorConfig)), @)

    # The first frame is always the 'loading', ie placeholder, image.
    placeholder = @createPlaceholder()
    dimension = @resolutionFactor * SPRITE_PLACEHOLDER_WIDTH
    placeholder.setBounds(0, 0, dimension, dimension)
    builder.addFrame(placeholder)
    
    # Add custom graphics
    extantGraphics = if @spriteSheet?.resolutionFactor is @resolutionFactor then @spriteSheet.getAnimations() else []
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
      if thangType.get('raw')
        if (thangType.get('spriteType') or @defaultSpriteType) is 'segmented'
          @renderSegmentedThangType(args...)
        else
          @renderSingularThangType(args...)
      else
        @renderRasterThangType(thangType, builder)
        
    if async
      builder.buildAsync()
      builder.on 'complete', @onBuildSpriteSheetComplete, @, true, builder
    else
      sheet = builder.build()
      @onBuildSpriteSheetComplete({async:async}, builder)
      return sheet
      
  onBuildSpriteSheetComplete: (e, builder) ->
    return if @initializing
    
    if builder.spriteSheet._images.length > 1
      @resolutionFactor *= 0.9
      console.debug('Sprite sheet is too large... re-rendering at', @resolutionFactor.toFixed(2))
      @_renderNewSpriteSheet(e.async)
      return
    
    @spriteSheet = builder.spriteSheet
    @spriteSheet.resolutionFactor = @resolutionFactor
    oldLayer = @container 
    @container = new createjs.SpriteContainer(@spriteSheet)
    for cocoSprite in @cocoSprites
      console.log 'zombie sprite found on layer', @name if cocoSprite.destroyed
      continue if cocoSprite.destroyed
      @setImageObjectToCocoSprite(cocoSprite)
    for prop in ['scaleX', 'scaleY', 'regX', 'regY']
      @container[prop] = oldLayer[prop]
    if parent = oldLayer.parent
      index = parent.getChildIndex(oldLayer)
      parent.removeChildAt(index)
      parent.addChildAt(@container, index)
    @camera?.updateZoom(true)
    @updateLayerOrder()
    for cocoSprite in @cocoSprites
      cocoSprite.options.resolutionFactor = @resolutionFactor
      cocoSprite.updateScale()
      cocoSprite.updateRotation()
    @trigger 'new-spritesheet'

  #- Placeholder
    
  createPlaceholder: ->
    # TODO: Experiment with this. Perhaps have rectangles if default layer is obstacle or floor, 
    # and different colors for different layers.
    g = new createjs.Graphics()
    g.setStrokeStyle(5)
    g.beginStroke(createjs.Graphics.getRGB(64,64,64))
    g.beginFill(createjs.Graphics.getRGB(64,64,64,0.7))
    radius = @resolutionFactor * SPRITE_PLACEHOLDER_WIDTH / 2
    g.drawCircle(radius, radius, radius)
    new createjs.Shape(g)
    
  #- Rendering containers for segmented thang types

  renderSegmentedThangType: (thangType, colorConfig, actionNames, spriteSheetBuilder) ->
    containersToRender = {}
    for actionName in actionNames
      action = _.find(thangType.getActions(), {name: actionName})
      if action.container
        containersToRender[action.container] = true
      else if action.animation
        animationContainers = @getContainersForAnimation(thangType, action.animation)
        containersToRender[container.gn] = true for container in animationContainers
    
    spriteBuilder = new SpriteBuilder(thangType, {colorConfig: colorConfig})
    for containerGlobalName in _.keys(containersToRender)
      containerKey = @renderGroupingKey(thangType, containerGlobalName, colorConfig)
      if @spriteSheet?.resolutionFactor is @resolutionFactor and containerKey in @spriteSheet.getAnimations()
        container = new createjs.Sprite(@spriteSheet)
        container.gotoAndStop(containerKey)
        frame = spriteSheetBuilder.addFrame(container)
      else
        container = spriteBuilder.buildContainerFromStore(containerGlobalName)
        frame = spriteSheetBuilder.addFrame(container, null, @resolutionFactor * (thangType.get('scale') or 1))
      spriteSheetBuilder.addAnimation(containerKey, [frame], false)

  getContainersForAnimation: (thangType, animation) ->
    containers = thangType.get('raw').animations[animation].containers
    for animation in thangType.get('raw').animations[animation].animations
      containers = containers.concat(@getContainersForAnimation(thangType, animation.gn))
    return containers
    
  #- Rendering sprite sheets for singular thang types
      
  renderSingularThangType: (thangType, colorConfig, actionNames, spriteSheetBuilder) ->
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
      if @spriteSheet?.resolutionFactor is @resolutionFactor and _.all(actionKeys, (key) => key in @spriteSheet.getAnimations())
        framesNeeded = _.uniq(_.flatten((@spriteSheet.getAnimation(key)).frames for key in actionKeys))
        framesMap = {}
        for frame in framesNeeded
          sprite = new createjs.Sprite(@spriteSheet)
          sprite.gotoAndStop(frame)
          framesMap[frame] = spriteSheetBuilder.addFrame(sprite)
        for key, index in actionKeys
          action = actions[index]
          frames = (framesMap[f] for f in @spriteSheet.getAnimation(key).frames)
          next = @nextForAction(action)
          spriteSheetBuilder.addAnimation(key, frames, next)
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
          frames = _.values(framesMap).sort()
        next = @nextForAction(action)
        spriteSheetBuilder.addAnimation(name, frames, next) 
        
    containerActions = []
    for a in actionObjects
      continue unless a.container
      continue unless a.name in actionNames
      containerActions.push(a)
    
    containerGroups = _.groupBy containerActions, (action) -> action.container
    for containerName, actions of containerGroups
      container = spriteBuilder.buildContainerFromStore(containerName)
      scale = actions[0].scale or thangType.get('scale') or 1
      frame = spriteSheetBuilder.addFrame(container, null, scale * @resolutionFactor)
      for action in actions
        name = @renderGroupingKey(thangType, action.name, colorConfig)
        spriteSheetBuilder.addAnimation(name, [frame], false)      
    
  nextForAction: (action) ->
    next = true
    next = action.goesTo if action.goesTo
    next = false if action.loops is false
    return next
    
  #- Rendering frames for raster thang types
        
  renderRasterThangType: (thangType, spriteSheetBuilder) ->
    unless thangType.rasterImage
      console.error("Cannot render the LayerAdapter SpriteSheet until the raster image for <#{thangType.get('name')}> is loaded.")
    
    bm = new createjs.Bitmap(thangType.rasterImage[0])
    scale = thangType.get('scale') or 1
    frame = spriteSheetBuilder.addFrame(bm, null, scale)
    spriteSheetBuilder.addAnimation(@renderGroupingKey(thangType), [frame], false)
    
  #- Distributing new Segmented/Singular/RasterSprites to CocoSprites

  setImageObjectToCocoSprite: (cocoSprite) ->
    if not cocoSprite.thangType.isFullyLoaded()
      # just give a placeholder
      sprite = new createjs.Sprite(@spriteSheet)
      sprite.gotoAndStop(0)
      sprite.placeholder = true
      sprite.regX = @resolutionFactor * SPRITE_PLACEHOLDER_WIDTH / 2
      sprite.regY = @resolutionFactor * SPRITE_PLACEHOLDER_WIDTH
      sprite.baseScaleX = sprite.baseScaleY = sprite.scaleX = sprite.scaleY = 10 / (@resolutionFactor * SPRITE_PLACEHOLDER_WIDTH)
    
    else if cocoSprite.thangType.get('raster')
      sprite = new createjs.Sprite(@spriteSheet)
      scale = cocoSprite.thangType.get('scale') or 1
      reg = cocoSprite.getOffset 'registration'
      sprite.regX = -reg.x * scale
      sprite.regY = -reg.y * scale
      sprite.gotoAndStop(@renderGroupingKey(cocoSprite.thangType))
      sprite.baseScaleX = sprite.baseScaleY = 1
      
    else
      SpriteClass = if (cocoSprite.thangType.get('spriteType') or @defaultSpriteType) is 'segmented' then SegmentedSprite else SingularSprite
      prefix = @renderGroupingKey(cocoSprite.thangType, null, cocoSprite.options.colorConfig) + '.'
      sprite = new SpriteClass(@spriteSheet, cocoSprite.thangType, prefix, @resolutionFactor)

    sprite.sprite = cocoSprite
    sprite.camera = @camera
    sprite.layerPriority = cocoSprite.thang?.layerPriority ? cocoSprite.thangType.get 'layerPriority'
    sprite.name = cocoSprite.thang?.spriteName or cocoSprite.thangType.get 'name'
    cocoSprite.setImageObject(sprite)
    cocoSprite.update(true)
    @container.addChild(sprite)

  renderGroupingKey: (thangType, grouping, colorConfig) ->
    key = thangType.get('slug')
    if colorConfig?.team
      key += "(#{colorConfig.team.hue},#{colorConfig.team.saturation},#{colorConfig.team.lightness})"
    key += '.'+grouping if grouping
    key

  destroy: ->
    child.destroy?() for child in @container.children
    super()