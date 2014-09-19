SpriteBuilder = require 'lib/sprites/SpriteBuilder'

module.exports = class SegmentedSprite extends createjs.SpriteContainer
  childMovieClips: null

  constructor: (@spriteSheet, @thangType, @spriteSheetPrefix, @resolutionFactor=SPRITE_RESOLUTION_FACTOR) ->
    @initialize(@spriteSheet)
    @addEventListener 'tick', @handleTick

  destroy: ->
    @handleTick = undefined
    @removeAllEventListeners()
  
  # CreateJS.Sprite-like interface
    
  play: -> @paused = false
  stop: -> @paused = true
  gotoAndPlay: (actionName) -> @goto(actionName, false)
  gotoAndStop: (actionName) -> @goto(actionName, true)
  
  goto: (actionName, @paused=true) ->
    @currentAnimation = actionName
    @baseMovieClip = @framerate = null
    @actionNotSupported = false

    action = @thangType.getActions()[actionName]
    randomStart = actionName.startsWith('move')
    reg = action.positions?.registration or @thangType.get('positions')?.registration or {x:0, y:0}

    if action.animation
      @framerate = (action.framerate ? 20) * (action.speed ? 1)
      @regX = -reg.x
      @regY = -reg.y
      @childMovieClips = []
      @baseMovieClip = @buildMovieClip(action.animation)
      @children = @baseMovieClip.children
      @frames = action.frames
      @frames = (parseInt(f) for f in @frames.split(',')) if @frames
      @animLength = if @frames then @frames.length else @baseMovieClip.frameBounds.length
      @currentFrame = if randomStart then Math.floor(Math.random() * @animLength) else 0
      @baseMovieClip.gotoAndStop(@currentFrame)
      @loop = action.loops isnt false
      @goesTo = action.goesTo
      @notifyActionNeedsRender(action) if @actionNotSupported

    else if action.container
      scale = @resolutionFactor * (action.scale ? @thangType.get('scale') ? 1)
      @regX = -reg.x
      @regY = -reg.y
      @childMovieClips = []
      containerName = @spriteSheetPrefix + action.container
      sprite = new createjs.Sprite(@spriteSheet)
      sprite.gotoAndStop(containerName)
      if sprite.currentFrame is 0
        @notifyActionNeedsRender(action)
        bounds = @thangType.get('raw').containers[action.container].b
        sprite.x = bounds[0]
        sprite.y = bounds[1]
        sprite.scaleX = bounds[2] / (SPRITE_PLACEHOLDER_RADIUS * 2 * scale)
        sprite.scaleY = bounds[3] / (SPRITE_PLACEHOLDER_RADIUS * 2 * scale)
      else
        sprite.scaleX = sprite.scaleY = 1 / scale
      @children = [sprite]

    return

  notifyActionNeedsRender: (action) ->
    @sprite?.trigger('action-needs-render', @sprite, action)

  buildMovieClip: (animationName, mode, startPosition, loops) ->
    raw = @thangType.get('raw')
    animData = raw.animations[animationName]
    movieClip = new createjs.MovieClip()

    locals = {}
    _.extend locals, @buildMovieClipContainers(animData.containers)
    _.extend locals, @buildMovieClipAnimations(animData.animations)

    toSkip = {}
    toSkip[shape.bn] = true for shape in animData.shapes
    toSkip[graphic.bn] = true for graphic in animData.graphics

    anim = new createjs.MovieClip()
    anim.initialize(mode ? createjs.MovieClip.INDEPENDENT, startPosition ? 0, loops ? true)

    for tweenData in animData.tweens
      stopped = false
      tween = createjs.Tween
      for func in tweenData
        args = $.extend(true, [], (func.a))
        if @dereferenceArgs(args, locals, toSkip) is false
          console.debug 'Did not dereference args:', args
          stopped = true
          break
        tween = tween[func.n](args...)
      continue if stopped
      anim.timeline.addTween(tween)

    anim.nominalBounds = new createjs.Rectangle(animData.bounds...)
    if animData.frameBounds
      anim.frameBounds = (new createjs.Rectangle(bounds...) for bounds in animData.frameBounds)
    return anim

  buildMovieClipContainers: (localContainers) ->
    map = {}
    for localContainer in localContainers
      outerContainer = new createjs.SpriteContainer(@spriteSheet)
      innerContainer = new createjs.Sprite(@spriteSheet)
      innerContainer.gotoAndStop(@spriteSheetPrefix + localContainer.gn)
      if innerContainer.currentFrame is 0
        @actionNotSupported = true
        bounds = @thangType.get('raw').containers[localContainer.gn].b
        innerContainer.x = bounds[0]
        innerContainer.y = bounds[1]
        innerContainer.scaleX = bounds[2] / (SPRITE_PLACEHOLDER_RADIUS * @resolutionFactor * 2)
        innerContainer.scaleY = bounds[3] / (SPRITE_PLACEHOLDER_RADIUS * @resolutionFactor * 2)
      else
        innerContainer.scaleX = innerContainer.scaleY = 1 / (@resolutionFactor * (@thangType.get('scale') or 1))
      outerContainer.addChild(innerContainer)
      outerContainer.setTransform(localContainer.t...)
      outerContainer._off = localContainer.o if localContainer.o?
      outerContainer.alpha = localContainer.al if localContainer.al?
      map[localContainer.bn] = outerContainer
    return map

  buildMovieClipAnimations: (localAnimations) ->
    map = {}
    for localAnimation in localAnimations
      animation = @buildMovieClip(localAnimation.gn, localAnimation.a...)
      animation.setTransform(localAnimation.t...)
      map[localAnimation.bn] = animation
      @childMovieClips.push(animation)
    return map

  dereferenceArgs: (args, locals, toSkip) ->
    for key, val of args
      if locals[val]
        args[key] = locals[val]
      else if val is null
        args[key] = {}
      else if _.isString(val) and val.indexOf('createjs.') is 0
        args[key] = eval(val) # TODO: Security risk
      else if _.isObject(val) or _.isArray(val)
        res = @dereferenceArgs(val, locals, toSkip)
        return res if res is false
      else if _.isString(val) and toSkip[val]
        return false
    return args

  handleTick: (e) =>
    if @lastTimeStamp
      @tick(e.timeStamp - @lastTimeStamp)
    @lastTimeStamp = e.timeStamp

  tick: (delta) ->
    return if @paused
    newFrame = @currentFrame + @framerate * delta / 1000

    if newFrame > @animLength
      if @goesTo
        @gotoAndPlay(@goesTo)
        return
      else if not @loop
        @paused = true
        newFrame = @animLength - 1
        @dispatchEvent('animationend')
      else
        newFrame = newFrame % @animLength

    if @frames
      prevFrame = Math.floor(newFrame)
      nextFrame = Math.ceil(newFrame)
      if prevFrame is nextFrame
        @baseMovieClip.gotoAndStop(@frames[newFrame])
      else if nextFrame is @frames.length
        @baseMovieClip.gotoAndStop(@frames[prevFrame])
      else
        # interpolate between frames
        pct = newFrame % 1
        newFrameIndex = @frames[prevFrame] + (pct * (@frames[nextFrame] - @frames[prevFrame]))
        @baseMovieClip.gotoAndStop(newFrameIndex)
    else
      @baseMovieClip.gotoAndStop(newFrame)

    @currentFrame = newFrame

    # So, originally I thought I'd have to swap in MovieClips for parallel 
    # SpriteContainers between each frame, but turns out that's not the case.
    # The WebGL rendering system treats the MovieClip like a SpriteContainer,
    # which makes things simpler for me...

    # For some reason, though, gotoAndStop doesn't seem to advance the children
    # so I gotta do that manually.
    movieClip.gotoAndStop(newFrame) for movieClip in @childMovieClips

  getBounds: ->
    @baseMovieClip.getBounds()
