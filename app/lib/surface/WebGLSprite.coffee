SpriteBuilder = require 'lib/sprites/SpriteBuilder'

module.exports = class WebGLSprite extends createjs.SpriteContainer
  childSpriteContainers: null
  
  constructor: (@spriteSheet, @thangType, @spriteSheetPrefix) ->
    @initialize(@spriteSheet)
    
  gotoAndPlay: (actionName) -> @goto(actionName, false)
  gotoAndStop: (actionName) -> @goto(actionName, true)
  
  goto: (actionName, @paused=true) ->
    @currentAnimation = actionName
    action = @thangType.getActions()[actionName]
    if action.animation
      @childSpriteContainers = []
      @baseMovieClip = @buildMovieClip(action.animation)
      @mirrorMovieClip(@baseMovieClip, @)
      @framerate = (action.framerate ? 20) * (action.speed ? 1)
      @frames = action.frames
      @currentFrame = 0
      if @frames
        @frames = (parseInt(f) for f in @frames.split(','))
      
      if @frames and @frames.length is 1
        @baseMovieClip.gotoAndStop(@frames[0])
        @paused = true
      @loop = action.loops isnt false
      @goesTo = action.goesTo
      @animLength = if @frames then @frames.length else @baseMovieClip.frameBounds.length
      
    return
  
  mirrorMovieClip: (movieClip, spriteContainer) ->
    spriteContainer.children = movieClip.children

  buildMovieClip: (animationName, mode, startPosition, loops) ->
    raw = @thangType.get('raw')
    animData = raw.animations[animationName]
    movieClip = new createjs.MovieClip()

    locals = {}
    _.extend locals, @buildMovieClipContainers(animData.containers)
    _.extend locals, @buildMovieClipAnimations(animData.animations)

    anim = new createjs.MovieClip()
    anim.initialize(mode ? createjs.MovieClip.INDEPENDENT, startPosition ? 0, loops ? true)

    for tweenData in animData.tweens
      stopped = false
      tween = createjs.Tween
      for func in tweenData
        args = $.extend(true, [], (func.a))
        if @dereferenceArgs(args, locals) is false
          console.log 'could not dereference args', args
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
      container = new createjs.Sprite(@spriteSheet)
      container.gotoAndStop(@spriteSheetPrefix + localContainer.gn)
      container.setTransform(localContainer.t...)
      container._off = localContainer.o if localContainer.o?
      container.alpha = localContainer.al if localContainer.al?
      map[localContainer.bn] = container
    return map

  buildMovieClipAnimations: (localAnimations) ->
    map = {}
    for localAnimation in localAnimations
      animation = @buildMovieClip(localAnimation.gn, localAnimation.a...)
      animation.setTransform(localAnimation.t...)
      map[localAnimation.bn] = animation
      childSpriteContainer = new createjs.SpriteContainer(@spriteSheet)
      childSpriteContainer.movieClip = animation
      childSpriteContainer.children = animation.children
      @childSpriteContainers.push(childSpriteContainer)
    return map

  dereferenceArgs: (args, locals) ->
    for key, val of args
      if locals[val]
        args[key] = locals[val]
      else if val is null
        args[key] = {}
      else if _.isString(val) and val.indexOf('createjs.') is 0
        args[key] = eval(val) # TODO: Security risk
      else if _.isObject(val) or _.isArray(val)
        res = @dereferenceArgs(val, locals)
        return res if res is false
      else if _.isString(val)
        return false
    return args

  tick: (delta) ->
    return unless @framerate and not @paused
    newFrame = @currentFrame + @framerate * delta / 1000
    
    if newFrame > @animLength
      if @goesTo
        @gotoAndPlay(@goesTo)
        return
      else if not @loop
        @paused = false
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

    if @childSpriteContainers
      for childSpriteContainer in @childSpriteContainers
        movieClip = childSpriteContainer.movieClip
        index = movieClip.parent.getChildIndex(movieClip)
        movieClip.gotoAndStop(newFrame)
        movieClip.parent[index] = childSpriteContainer

  getBounds: ->
    @baseMovieClip.getBounds()
