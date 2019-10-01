SpriteBuilder = require('./SpriteBuilder')
ThangType = require('models/ThangType')
CocoClass = require('core/CocoClass')
createjs = require 'lib/createjs-parts'


class SpriteExporter extends CocoClass
  '''
  To be used by the ThangTypeEditView to export ThangTypes to single sprite sheets which can be uploaded to
  GridFS and used in gameplay, avoiding rendering vector images.

  Code has been copied and reworked and simplified from LayerAdapter. Some shared code has been refactored into
  ThangType, but more work could be done to rethink and reorganize Sprite rendering.
  '''

  constructor: (thangType, options) ->
    @thangType = thangType
    options ?= {}
    @colorConfig = options.colorConfig or {}
    @resolutionFactor = options.resolutionFactor or 1
    @actionNames = options.actionNames or (action.name for action in @thangType.getDefaultActions())
    @spriteType = options.spriteType or @thangType.get('spriteType') or 'segmented'
    super()

  build: ->
    spriteSheetBuilder = new createjs.SpriteSheetBuilder()
    if @spriteType is 'segmented'
      @renderSegmentedThangType(spriteSheetBuilder)
    else
      @renderSingularThangType(spriteSheetBuilder)
    try
      spriteSheetBuilder.buildAsync()
    catch e
      @resolutionFactor *= 0.9
      return @build()
    spriteSheetBuilder.on 'complete', @onBuildSpriteSheetComplete, @, true, spriteSheetBuilder
    @asyncBuilder = spriteSheetBuilder

  renderSegmentedThangType: (spriteSheetBuilder) ->
    containersToRender = @thangType.getContainersForActions(@actionNames)
    spriteBuilder = new SpriteBuilder(@thangType, {colorConfig: @colorConfig})
    for containerGlobalName in containersToRender
      container = spriteBuilder.buildContainerFromStore(containerGlobalName)
      frame = spriteSheetBuilder.addFrame(container, null, @resolutionFactor * (@thangType.get('scale') or 1))
      spriteSheetBuilder.addAnimation(containerGlobalName, [frame], false)

  renderSingularThangType: (spriteSheetBuilder) ->
    actionObjects = _.values(@thangType.getActions())
    animationActions = []
    for a in actionObjects
      continue unless a.animation
      continue unless a.name in @actionNames
      animationActions.push(a)

    spriteBuilder = new SpriteBuilder(@thangType, {colorConfig: @colorConfig})

    animationGroups = _.groupBy animationActions, (action) -> action.animation
    for animationName, actions of animationGroups
      scale = actions[0].scale or @thangType.get('scale') or 1
      mc = spriteBuilder.buildMovieClip(animationName, null, null, null, {'temp':0})
      spriteSheetBuilder.addMovieClip(mc, null, scale * @resolutionFactor)
      frames = spriteSheetBuilder._animations['temp'].frames
      framesMap = _.zipObject _.range(frames.length), frames
      for action in actions
        if action.frames
          frames = (framesMap[parseInt(frame)] for frame in action.frames.split(','))
        else
          frames = _.sortBy(_.values(framesMap))
        next = @thangType.nextForAction(action)
        spriteSheetBuilder.addAnimation(action.name, frames, next)

    containerActions = []
    for a in actionObjects
      continue unless a.container
      continue unless a.name in @actionNames
      containerActions.push(a)

    containerGroups = _.groupBy containerActions, (action) -> action.container
    for containerName, actions of containerGroups
      container = spriteBuilder.buildContainerFromStore(containerName)
      scale = actions[0].scale or @thangType.get('scale') or 1
      frame = spriteSheetBuilder.addFrame(container, null, scale * @resolutionFactor)
      for action in actions
        spriteSheetBuilder.addAnimation(action.name, [frame], false)

  onBuildSpriteSheetComplete: (e, builder) ->
    if builder.spriteSheet._images.length > 1
      total = 0
      # get a rough estimate of how much smaller the spritesheet needs to be
      for image, index in builder.spriteSheet._images
        total += image.height / builder.maxHeight
      @resolutionFactor /= (Math.max(1.1, Math.sqrt(total)))
      @_renderNewSpriteSheet(e.async)
      return

    @trigger 'build', { spriteSheet: builder.spriteSheet }



module.exports = SpriteExporter
