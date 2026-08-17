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
    if animData.rasterSheet
      return @buildRasterMovieClip animationName, animData, mode, startPosition, loops, labels
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

  # Raster-backed animation: a MovieClip showing one source-rect crop of a
  # packed raster sheet per timeline frame. Returns null until the sheet image
  # is loaded, so callers skip it and a rebuild after 'raster-raw-images-loaded'
  # picks it up. The bitmaps are timeline-managed (no addChild), like the
  # tween targets of an Animate-published clip.
  buildRasterMovieClip: (animationName, animData, mode, startPosition, loops, labels) ->
    img = @thangType.getRasterRawImage? animData.rasterSheet
    unless img
      console.warn 'Raster sheet not loaded yet for animation', animationName, animData.rasterSheet
      return null
    rasterFrames = animData.rasterFrames or []
    unless rasterFrames.length
      console.error 'Raster animation has no rasterFrames', animationName
      return null
    anim = new createjs.MovieClip()
    if not labels
      labels = {}
      labels[animationName] = 0
    anim.initialize(mode ? createjs.MovieClip.INDEPENDENT, startPosition ? 0, loops ? true, labels)
    numFrames = rasterFrames.length
    frameBounds = []
    for frameData, i in rasterFrames
      [x, y, w, h, regX, regY] = frameData
      regX ?= 0
      regY ?= 0
      bitmap = new createjs.Bitmap(img)
      bitmap.sourceRect = new createjs.Rectangle(x, y, w, h)
      bitmap.regX = regX
      bitmap.regY = regY
      bitmap._off = i isnt 0
      frameBounds.push new createjs.Rectangle(-regX, -regY, w, h)
      if numFrames is 1
        tween = createjs.Tween.get(bitmap).wait(1)
      else
        tween = createjs.Tween.get(bitmap)
        tween = tween.wait(i) if i > 0
        tween = tween.to({_off: false}, 0).wait(1).to({_off: true}, 0)
        remaining = numFrames - i - 1
        tween = tween.wait(remaining) if remaining > 0
      anim.timeline.addTween(tween)
    if animData.bounds
      anim.nominalBounds = new createjs.Rectangle(animData.bounds...)
    else
      left = _.min(b.x for b in frameBounds)
      top = _.min(b.y for b in frameBounds)
      right = _.max(b.x + b.width for b in frameBounds)
      bottom = _.max(b.y + b.height for b in frameBounds)
      anim.nominalBounds = new createjs.Rectangle(left, top, right - left, bottom - top)
    if animData.frameBounds
      anim.frameBounds = (new createjs.Rectangle(bounds...) for bounds in animData.frameBounds)
    else
      anim.frameBounds = frameBounds
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
    if contData?.img
      return @buildRasterContainer containerKey, contData
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

  # Raster-backed container: a single Bitmap placed at the container's bounds
  # offset instead of vector children. Returns null until the image is loaded.
  buildRasterContainer: (containerKey, contData) ->
    img = @thangType.getRasterRawImage? contData.img
    unless img
      console.warn 'Raster image not loaded yet for container', containerKey, contData.img
      return null
    naturalWidth = img.naturalWidth or img.width
    naturalHeight = img.naturalHeight or img.height
    b = contData.b or [0, 0, naturalWidth, naturalHeight]
    cont = new createjs.Container()
    cont.initialize()
    bitmap = new createjs.Bitmap(img)
    bitmap.x = b[0]
    bitmap.y = b[1]
    bitmap.scaleX = b[2] / naturalWidth if naturalWidth
    bitmap.scaleY = b[3] / naturalHeight if naturalHeight
    cont.addChild(bitmap)
    cont.bounds = new createjs.Rectangle(b...)
    cont

  # Builds the spritesheet using the texture atlas images for each animation/action and updates its reference in the movieClip file
  buildSpriteSheetFromTextureAtlas: (actionNames) ->
    for action in actionNames
      spriteData = @thangType.getRasterAtlasSpriteData(action)

      unless spriteData and spriteData.ssMetadata and spriteData.ss
        console.warn "Sprite data for #{action} does not contain the required data to build a spritesheet! ", spriteData
        continue

      try
        # spriteData holds a reference to the spritesheet in the adobe animate's movieClip file (ss)
        for metaData in spriteData?.ssMetadata
          # builds the spritesheets everytime an action is rendered
          # TODO build new spritesheet only if there are changes in metaData.images / metaData.frames
          spriteData.ss?[metaData.name] = new createjs.SpriteSheet( { 'images': metaData.images, 'frames': metaData.frames })
      catch e
        console.error 'Error in creating spritesheet', e

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
      continue if not shape?.fc?
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
      continue if (not shape?.fc?) or colors[shape.fc]
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
      continue if (not shape?.fc?) or not(colors[shape.fc])
      @colorMap[shapeKey] = hslToHex(colors[shape.fc])

sum = (nums) -> _.reduce(nums, (s, num) -> s + num)
