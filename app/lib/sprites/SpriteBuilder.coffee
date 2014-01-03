module.exports = class SpriteBuilder
  constructor: (@thangType, @options) ->
    raw = _.cloneDeep(@thangType.get('raw'))
    @shapeStore = raw.shapes
    @containerStore = raw.containers
    @animationStore = raw.animations

  setOptions: (@options) ->

  buildMovieClip: (animationName, movieClipArgs...) ->
    animData = @animationStore[animationName]
    console.log "couldn't find animData from", @animationStore, "for", animationName unless animData
    locals = {}
    _.extend locals, @buildMovieClipShapes(animData.shapes)
    _.extend locals, @buildMovieClipContainers(animData.containers)
    _.extend locals, @buildMovieClipAnimations(animData.animations)
    _.extend locals, @buildMovieClipGraphics(animData.graphics)
    anim = new createjs.MovieClip()
    movieClipArgs ?= []
    labels = {}
    labels[animationName] = 0
    anim.initialize(
      movieClipArgs[0] ? createjs.MovieClip.INDEPENDENT, # mode
      movieClipArgs[1] ? 0, # start position
      movieClipArgs[2] ? true, # loops
      labels)
    for tweenData in animData.tweens
      tween = createjs.Tween
      for func in tweenData
        args = _.cloneDeep(func.a)
        @dereferenceArgs(args, locals)
        tween = tween[func.n](args...)
      anim.timeline.addTween(tween)

    anim.nominalBounds = new createjs.Rectangle(animData.bounds...)
    if animData.frameBounds
      anim.frameBounds = (new createjs.Rectangle(bounds...) for bounds in animData.frameBounds)
    anim

  dereferenceArgs: (args, locals) ->
    for key, val of args
      if locals[val]
        args[key] = locals[val]
      else if val is null
        args[key] = {}
      else if _.isString(val) and val.indexOf('createjs.') is 0
        args[key] = eval(val) # TODO: Security risk
      else if _.isObject(val) or _.isArray(val)
        @dereferenceArgs(val, locals)
    args

  buildMovieClipShapes: (localShapes) ->
    map = {}
    for localShape in localShapes
      if localShape.im
        shape = new createjs.Shape()
        shape._off = true
      else
        shape = @buildShapeFromStore(localShape.gn)
        if localShape.m
          shape.mask = map[localShape.m]
      map[localShape.bn] = shape
    map

  buildMovieClipContainers: (localContainers) ->
    map = {}
    for localContainer in localContainers
      container = @buildContainerFromStore(localContainer.gn)
      container.setTransform(localContainer.t...)
      container._off = localContainer.o if localContainer.o?
      container.alpha = localContainer.al if localContainer.al?
      map[localContainer.bn] = container
    map

  buildMovieClipAnimations: (localAnimations) ->
    map = {}
    for localAnimation in localAnimations
      animation = @buildMovieClip(localAnimation.gn, localAnimation.a)
      animation.setTransform(localAnimation.t...)
      map[localAnimation.bn] = animation
    map

  buildMovieClipGraphics: (localGraphics) ->
    map = {}
    for localGraphic in localGraphics
      graphic = new createjs.Graphics().p(localGraphic.p)
      map[localGraphic.bn] = graphic
    map

  buildShapeFromStore: (shapeKey, debug=false) ->
    shapeData = @shapeStore[shapeKey]
    shape = new createjs.Shape()
    if shapeData.lf?
      shape.graphics.lf shapeData.lf...
    else if shapeData.fc?
      shape.graphics.f shapeData.fc
    if shapeData.ls?
      shape.graphics.ls shapeData.ls...
    else if shapeData.sc?
      shape.graphics.s shapeData.sc
    shape.graphics.ss shapeData.ss... if shapeData.ss?
    shape.graphics.de shapeData.de... if shapeData.de?
    shape.graphics.p shapeData.p if shapeData.p?
    shape.setTransform shapeData.t...
    shape

  buildContainerFromStore: (containerKey) ->
    console.error "Yo we don't have no", containerKey unless containerKey
    contData = @containerStore[containerKey]
    cont = new createjs.Container()
    cont.initialize()
    for childData in contData.c
      if _.isString(childData)
        child = @buildShapeFromStore(childData)
      else
        child = @buildContainerFromStore(childData.gn)
        child.setTransform(childData.t...)
      cont.addChild(child)
    cont.bounds = new createjs.Rectangle(contData.b...)
    cont
