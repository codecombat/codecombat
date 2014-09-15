SpriteBuilder = require 'lib/sprites/SpriteBuilder'

module.exports = class WebGLLayer extends createjs.SpriteContainer
  
  actionRenderState: null
  needToRerender: false
  toRenderBundles: null
  willRender: false
  resolutionFactor: SPRITE_RESOLUTION_FACTOR
  defaultActions: ['idle', 'die', 'move', 'move_back', 'move_side', 'move_fore', 'attack']
  
  constructor: ->
    super(arguments...)
    @actionRenderState = {}
    @toRenderBundles = []
    @initialize(arguments...)
    
  setDefaultActions: (@defaultActions) ->
    
  renderGroupingKey: (thangType, grouping, colorConfig) ->
    key = thangType.get('slug')
    if colorConfig?.team
      key += "(#{colorConfig.team.hue},#{colorConfig.team.saturation},#{colorConfig.team.lightness})"
    key += '.'+grouping if grouping
    key
    
  addCocoSprite: (cocoSprite) ->
    # build the animations for it
    if cocoSprite.thangType.get('raster')
      @upsertActionToRender(cocoSprite.thangType)
    else
      for action in _.values(cocoSprite.thangType.getActions())
        continue unless action.name in @defaultActions
        @upsertActionToRender(cocoSprite.thangType, action.name, cocoSprite.options.colorConfig)
      
  upsertActionToRender: (thangType, actionName, colorConfig) ->
    groupKey = @renderGroupingKey(thangType, actionName, colorConfig)
    return if @actionRenderState[groupKey] isnt undefined
    @actionRenderState[groupKey] = 'need-to-render'
    @toRenderBundles.push({thangType: thangType, actionName: actionName, colorConfig: colorConfig})
    return if @willRender
#    @willRender = _.defer => @renderNewSpriteSheet()
    
  renderNewSpriteSheet: ->
    @willRender = false
    builder = new createjs.SpriteSheetBuilder()
    groups = _.groupBy(@toRenderBundles, ((bundle) -> @renderGroupingKey(bundle.thangType, '', bundle.colorConfig)), @)
    for bundleGrouping in _.values(groups)
      thangType = bundleGrouping[0].thangType
      colorConfig = bundleGrouping[0].colorConfig
      actionNames = (bundle.actionName for bundle in bundleGrouping)
      args = [thangType, colorConfig, actionNames, builder]
      if thangType.get('raw')
        if thangType.get('renderStrategy') is 'container'
          @renderContainers(args...)
        else
          @renderSpriteSheet(args...)
      else
        @renderRasterImage(thangType, builder)
    builder.build()
        
  renderContainers: (thangType, colorConfig, actionNames, spriteSheetBuilder) ->
    containersToRender = {}
    for actionName in actionNames
      action = _.find(thangType.getActions(), {name: actionName})
      if action.container
        containersToRender[action.container] = true
      else if action.animation
        animationContainers = thangType.get('raw').animations[action.animation].containers
        containersToRender[container.gn] = true for container in animationContainers
    
    spriteBuilder = new SpriteBuilder(thangType, {colorConfig: colorConfig})
    for containerGlobalName in _.keys(containersToRender)
      containerKey = @renderGroupingKey(thangType, containerGlobalName, colorConfig)
      container = spriteBuilder.buildContainerFromStore(containerGlobalName)
      frame = spriteSheetBuilder.addFrame(container)
      spriteSheetBuilder.addAnimation(containerKey, [frame], false)

      
  renderSpriteSheet: (thangType, colorConfig, actionNames, spriteSheetBuilder) ->
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
          
        next = true
        next = action.goesTo if action.goesTo
        next = false if action.loops is false

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
    
  renderRasterImage: (thangType, spriteSheetBuilder) ->
    unless thangType.rasterImage
      console.error("Cannot render the WebGLLayer SpriteSheet until the raster image for <#{thangType.get('name')}> is loaded.")
    
    bm = new createjs.Bitmap(thangType.rasterImage[0])
    scale = thangType.get('scale') or 1
    frame = spriteSheetBuilder.addFrame(bm, null, scale)
    spriteSheetBuilder.addAnimation(@renderGroupingKey(thangType), [frame], false)
      
#  renderForSprite: (cocoSprite) ->
#    rawData = cocoSprite.thangType.get('raw')
#    groupKey = @renderGroupingKey(cocoSprite.thangType, cocoSprite.options.colorConfig)
#    spriteBuilder = new SpriteBuilder(cocoSprite.thangType, cocoSprite.options)
#    for animation in raw.animations ? []
#      for shape in shapes
#        shape = @spriteBuilder.buildShapeFromStore(shape.gn)
#        key = groupKey = ':' + shape.gn
#        frame = @spriteBuilder.addFrame(groupKey)
