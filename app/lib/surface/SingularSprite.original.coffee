SpriteBuilder = require 'lib/sprites/SpriteBuilder'
createjs = require 'lib/createjs-parts'

floors = ['Dungeon Floor', 'Indoor Floor', 'Grass', 'Grass01', 'Grass02', 'Grass03', 'Grass04', 'Grass05', 'Goal Trigger', 'Obstacle', 'Sand 01', 'Sand 02', 'Sand 03', 'Sand 04', 'Sand 05', 'Sand 06', 'Talus 1', 'Talus 2', 'Talus 3', 'Talus 4', 'Talus 5', 'Talus 6', 'Firn 1', 'Firn 2', 'Firn 3', 'Firn 4', 'Firn 5', 'Firn 6', 'Ice Rink 1', 'Ice Rink 2', 'Ice Rink 3', 'Firn Cliff', 'VR Floor', 'Classroom Floor']

cliffs = ['Dungeon Pit', 'Grass Cliffs']

module.exports = class SingularSprite extends createjs.Sprite
  childMovieClips: null

  constructor: (@spriteSheet, @thangType, @spriteSheetPrefix, @resolutionFactor=SPRITE_RESOLUTION_FACTOR) ->
    super(@spriteSheet)

  destroy: ->
    @removeAllEventListeners()

  gotoAndPlay: (actionName) -> @goto(actionName, false)
  gotoAndStop: (actionName) -> @goto(actionName, true)
  _gotoAndPlay: createjs.Sprite.prototype.gotoAndPlay
  _gotoAndStop: createjs.Sprite.prototype.gotoAndStop

  goto: (actionName, @paused=true) ->
    @actionNotSupported = false

    action = @thangType.getActions()[actionName]
    randomStart = _.string.startsWith(actionName, 'move')
    reg = action.positions?.registration or @thangType.get('positions')?.registration or {x:0, y:0}

    if action.animation
      @framerate = (action.framerate ? 20) * (action.speed ? 1)

      func = if @paused then '_gotoAndStop' else '_gotoAndPlay'
      animationName = @spriteSheetPrefix + actionName
      @[func](animationName)
      if @currentFrame is 0 or @usePlaceholders
        @_gotoAndStop(0)
        @notifyActionNeedsRender(action)
        bounds = @thangType.get('raw')?.animations?[action.animation]?.bounds # checking for just-prerendered-spritesheet thangs
        bounds ?= [0, 0, 1, 1]
        actionScale = (action.scale ? @thangType.get('scale') ? 1)
        @scaleX = actionScale * bounds[2] / (SPRITE_PLACEHOLDER_WIDTH * @resolutionFactor)
        @scaleY = actionScale * bounds[3] / (SPRITE_PLACEHOLDER_WIDTH * @resolutionFactor)
        @regX = (SPRITE_PLACEHOLDER_WIDTH * @resolutionFactor) * ((-reg.x - bounds[0]) / bounds[2])
        @regY = (SPRITE_PLACEHOLDER_WIDTH * @resolutionFactor) * ((-reg.y - bounds[1]) / bounds[3])
      else
        scale = @resolutionFactor * (action.scale ? @thangType.get('scale') ? 1)
        @regX = -reg.x * scale
        @regY = -reg.y * scale
        @scaleX = @scaleY = 1 / @resolutionFactor
        @framerate = action.framerate or 20
        if randomStart and frames = @spriteSheet.getAnimation(animationName)?.frames
          @currentAnimationFrame = Math.floor(Math.random() * frames.length)

    if action.container
      animationName = @spriteSheetPrefix + actionName
      @_gotoAndStop(animationName)
      if @currentFrame is 0 or @usePlaceholders
        @_gotoAndStop(0)
        @notifyActionNeedsRender(action)
        bounds = @thangType.get('raw').containers[action.container].b
        actionScale = (action.scale ? @thangType.get('scale') ? 1)
        @scaleX = actionScale * bounds[2] / (SPRITE_PLACEHOLDER_WIDTH * @resolutionFactor)
        @scaleY = actionScale * bounds[3] / (SPRITE_PLACEHOLDER_WIDTH * @resolutionFactor)
        @regX = (SPRITE_PLACEHOLDER_WIDTH * @resolutionFactor) * ((-reg.x - bounds[0]) / bounds[2])
        @regY = (SPRITE_PLACEHOLDER_WIDTH * @resolutionFactor) * ((-reg.y - bounds[1]) / bounds[3])
      else
        scale = @resolutionFactor * (action.scale ? @thangType.get('scale') ? 1)
        @regX = -reg.x * scale
        @regY = -reg.y * scale
        @scaleX = @scaleY = 1 / @resolutionFactor

    @scaleX *= -1 if action.flipX
    @scaleY *= -1 if action.flipY
    @baseScaleX = @scaleX
    @baseScaleY = @scaleY
    if @camera and @thangType.get('name') in floors
      @baseScaleY *= @camera.y2x
    else if @camera and @thangType.get('name') in cliffs
      if actionName is 'idle_side'
        @baseScaleX *= @camera.x2y# / 0.85
        @baseScaleY *= @camera.y2x * 0.85
      else
        @baseScaleY *= @camera.y2x / 0.85
    @currentAnimation = actionName
    return

  notifyActionNeedsRender: (action) ->
    @lank?.trigger('action-needs-render', @lank, action)
