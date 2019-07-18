{hexToHSL, hslToHex} = require 'core/utils'
createjs = require 'lib/createjs-parts'

module.exports = class SpriteBuilder
  constructor: (@thangType, @options) ->
    @options ?= {}
    raw = @thangType.get('raw') or {}
    @shapeStore = raw.shapes
    @containerStore = raw.containers
    @animationStore = raw.animations
    @buildColorMaps()

  setOptions: (@options) ->

  buildMovieClip: (animationName, mode, startPosition, loops, labels) ->
    animData = @animationStore[animationName]
    unless animData
      console.error 'couldn\'t find animData from', @animationStore, 'for', animationName
      return null
    locals = {}
    _.extend locals, @buildMovieClipShapes(animData.shapes)
    _.extend locals, @buildMovieClipContainers(animData.containers)
    _.extend locals, @buildMovieClipAnimations(animData.animations)
    _.extend locals, @buildMovieClipGraphics(animData.graphics)
    anim = new createjs.MovieClip()
    if not labels
      labels = {}
      labels[animationName] = 0
    anim.initialize(mode ? createjs.MovieClip.INDEPENDENT, startPosition ? 0, loops ? true, labels)
    for tweenData in animData.tweens
      tween = createjs.Tween
      stopped = false
      for func in tweenData
        args = _.cloneDeep(func.a)
        @dereferenceArgs(args, locals)
        if tween[func.n]
          tween = tween[func.n](args...)
        else
          # If we, say, skipped a shadow get(), then the wait() may not be present
          stopped = true
          break
      anim.timeline.addTween(tween) unless stopped

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
      animation = @buildMovieClip(localAnimation.gn, localAnimation.a...)
      animation.setTransform(localAnimation.t...)
      animation._off = true if localAnimation.off
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
      shape.graphics.f @colorMap[shapeKey] or shapeData.fc
    else if shapeData.rf?
      shape.graphics.rf shapeData.rf...
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
    console.error 'Yo we don\'t have no containerKey' unless containerKey
    contData = @containerStore[containerKey]
    cont = new createjs.Container()
    cont.initialize()
    for childData in contData.c
      if _.isString(childData)
        child = @buildShapeFromStore(childData)
      else
        continue if not childData.gn
        child = @buildContainerFromStore(childData.gn)
        child.setTransform(childData.t...)
      cont.addChild(child)
    cont.bounds = new createjs.Rectangle(contData.b...)
    cont

  buildColorMaps: ->
    @colorMap = {}
    colorGroups = @thangType.get('colorGroups')
    return if _.isEmpty colorGroups
    return unless _.size @shapeStore  # We don't have the shapes loaded because we are doing a prerendered spritesheet approach
    colorConfig = @options.colorConfig
#    colorConfig ?= {team: {hue:0.4, saturation: -0.5, lightness: -0.5}} # test config
    return if not colorConfig

    for group, config of colorConfig
      continue unless colorGroups[group] # color group not found...
      if @thangType.get('ozaria')
        @buildOzariaColorMapForGroup(colorGroups[group], config)
      else
        @buildColorMapForGroup(colorGroups[group], config)

  # Simpler Ozaria color mapper.
  # Instead of color shifting we apply the color directly.
  buildOzariaColorMapForGroup: (shapes, config) ->
    return unless shapes.length
    for shapeKey in shapes
      shape = @shapeStore[shapeKey]
      continue if not shape.fc?
      # Store the color we'd like the shape to be rendered with.
      @colorMap[shapeKey] = hslToHex([config.hue, config.saturation, config.lightness])

  buildColorMapForGroup: (shapes, config) ->
    return unless shapes.length
    colors = @initColorMap(shapes)
    @adjustHuesForColorMap(colors, config.hue)
    @adjustValueForColorMap(colors, 1, config.saturation)
    @adjustValueForColorMap(colors, 2, config.lightness)
    @applyColorMap(shapes, colors)

  initColorMap: (shapes) ->
    colors = {}
    for shapeKey in shapes
      shape = @shapeStore[shapeKey]
      continue if (not shape.fc?) or colors[shape.fc]
      hsl = hexToHSL(shape.fc)
      colors[shape.fc] = hsl
    colors

  adjustHuesForColorMap: (colors, targetHue) ->
    hues = (hsl[0] for hex, hsl of colors)

    # 'rotate' the hue spectrum so averaging works
    if Math.max(hues) - Math.min(hues) > 0.5
      hues = (if h < 0.5 then h + 1.0 else h for h in hues)
    averageHue = sum(hues) / hues.length
    averageHue %= 1
    # end result should be something like a hue array of [0.9, 0.3] gets an average of 0.1

    targetHue ?= 0
    diff = targetHue - averageHue
    hsl[0] = (hsl[0] + diff + 1) % 1 for hex, hsl of colors

  adjustValueForColorMap: (colors, index, targetValue) ->
    values = (hsl[index] for hex, hsl of colors)
    averageValue = sum(values) / values.length
    targetValue ?= 0.5
    diff = targetValue - averageValue
    for hex, hsl of colors
      hsl[index] = Math.max(0, Math.min(1, hsl[index] + diff))

  applyColorMap: (shapes, colors) ->
    for shapeKey in shapes
      shape = @shapeStore[shapeKey]
      continue if (not shape.fc?) or not(colors[shape.fc])
      @colorMap[shapeKey] = hslToHex(colors[shape.fc])

sum = (nums) -> _.reduce(nums, (s, num) -> s + num)
