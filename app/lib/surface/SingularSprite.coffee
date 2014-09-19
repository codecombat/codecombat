SpriteBuilder = require 'lib/sprites/SpriteBuilder'

module.exports = class WebGLSprite extends createjs.Sprite
  childMovieClips: null
  
  constructor: (@spriteSheet, @thangType, @spriteSheetPrefix, @resolutionFactor=SPRITE_RESOLUTION_FACTOR) ->
    @initialize(@spriteSheet)
    
  destroy: -> 
    @removeAllEventListeners()
  
  gotoAndPlay: (actionName) -> @goto(actionName, false)
  gotoAndStop: (actionName) -> @goto(actionName, true)
  _gotoAndPlay: createjs.Sprite.prototype.gotoAndPlay
  _gotoAndStop: createjs.Sprite.prototype.gotoAndStop
  
  goto: (actionName, @paused=true) ->
    @actionNotSupported = false
    
    action = @thangType.getActions()[actionName]
    randomStart = actionName.startsWith('move')
    reg = action.positions?.registration or @thangType.get('positions')?.registration or {x:0, y:0}

    if action.animation
      @framerate = (action.framerate ? 20) * (action.speed ? 1)
      
      scale = @resolutionFactor * (action.scale ? @thangType.get('scale') ? 1)
      @regX = -reg.x * scale
      @regY = -reg.y * scale
      func = if @paused then '_gotoAndStop' else '_gotoAndPlay'
      animationName = @spriteSheetPrefix + actionName
      @[func](animationName)
      if @currentFrame is 0
        @stop()
        @regX = -reg.x
        @regY = -reg.y
        @notifyActionNeedsRender(action)
        bounds = @thangType.get('raw').animations[action.animation].bounds
        @x = bounds[0]
        @y = bounds[1]
        @scaleX = bounds[2] / (SPRITE_PLACEHOLDER_RADIUS * @resolutionFactor * 2)
        @scaleY = bounds[3] / (SPRITE_PLACEHOLDER_RADIUS * @resolutionFactor * 2)
        return
        
      @framerate = action.framerate or 20
      if randomStart and frames = @spriteSheet.getAnimation(animationName)?.frames
        @currentAnimationFrame = Math.floor(Math.random() * frames.length)

    if action.container
      scale = @resolutionFactor * (action.scale ? @thangType.get('scale') ? 1)

      @regX = -reg.x * scale
      @regY = -reg.y * scale
      animationName = @spriteSheetPrefix + actionName
      @_gotoAndStop(animationName)
      if @currentFrame is 0
        @notifyActionNeedsRender(action)
        bounds = @thangType.get('raw').containers[action.container].b
        @x = bounds[0]
        @y = bounds[1]
        @scaleX = bounds[2] / (SPRITE_PLACEHOLDER_RADIUS * 2)
        @scaleY = bounds[3] / (SPRITE_PLACEHOLDER_RADIUS * 2)
        return

    @currentAnimation = actionName
    return
    
  notifyActionNeedsRender: (action) ->
    @sprite.trigger('action-needs-render', @sprite, action) 