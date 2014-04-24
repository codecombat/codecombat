CocoModel = require('./CocoModel')
SpriteBuilder = require 'lib/sprites/SpriteBuilder'

buildQueue = []

module.exports = class ThangType extends CocoModel
  @className: "ThangType"
  @schema: require 'schemas/models/thang_type'
  urlRoot: "/db/thang.type"
  building: {}

  initialize: ->
    super()
    @building = {}
    @setDefaults()
    @on 'sync', @setDefaults
    @spriteSheets = {}

  setDefaults: ->
    @resetRawData() unless @get('raw')

  resetRawData: ->
    @set('raw', {shapes:{}, containers:{}, animations:{}})

  resetSpriteSheetCache: ->
    @buildActions()
    @spriteSheets = {}
    @building = {}

  getActions: ->
    return @actions or @buildActions()

  buildActions: ->
    @actions = $.extend(true, {}, @get('actions') or {})
    for name, action of @actions
      action.name = name
      for relatedName, relatedAction of action.relatedActions ? {}
        relatedAction.name = action.name + "_" + relatedName
        @actions[relatedAction.name] = relatedAction
    @actions

  getSpriteSheet: (options) ->
    options = @fillOptions options
    key = @spriteSheetKey(options)
    return @spriteSheets[key] or @buildSpriteSheet(options)

  fillOptions: (options) ->
    options ?= {}
    options = _.clone options
    options.resolutionFactor ?= 4
    options.async ?= false
    options

  buildSpriteSheet: (options) ->
    @options = @fillOptions options
    key = @spriteSheetKey(@options)
    return if @building[key]
    @initBuild(options)
    @addGeneralFrames() unless @options.portraitOnly
    @addPortrait()
    @building[key] = true
    result = @finishBuild()
    return result

  initBuild: (options) ->
    @buildActions() if not @actions
    @vectorParser = new SpriteBuilder(@, options)
    @builder = new createjs.SpriteSheetBuilder()
    @builder.padding = 2
    @frames = {}

  addPortrait: ->
    # The portrait is built very differently than the other animations, so it gets a separate function.
    return unless @actions
    portrait = @actions.portrait
    return unless portrait
    scale = portrait.scale or 1
    pt = portrait.positions?.registration
    rect = new createjs.Rectangle(pt?.x/scale or 0, pt?.y/scale or 0, 100/scale, 100/scale)
    if portrait.animation
      mc = @vectorParser.buildMovieClip portrait.animation
      mc.nominalBounds = mc.frameBounds = null # override what the movie clip says on bounding
      @builder.addMovieClip(mc, rect, scale)
      frames = @builder._animations[portrait.animation].frames
      frames = @mapFrames(portrait.frames, frames[0]) if portrait.frames?
      @builder.addAnimation 'portrait', frames, true
    else if portrait.container
      s = @vectorParser.buildContainerFromStore(portrait.container)
      frame = @builder.addFrame(s, rect, scale)
      @builder.addAnimation 'portrait', [frame], false

  addGeneralFrames: ->
    framesMap = {}
    for animation in @requiredRawAnimations()
      name = animation.animation
      mc = @vectorParser.buildMovieClip name
      continue unless mc
      @builder.addMovieClip mc, null, animation.scale * @options.resolutionFactor
      framesMap[animation.scale + "_" + name] = @builder._animations[name].frames

    for name, action of @actions when action.animation
      continue if name is 'portrait'
      scale = action.scale ? @get('scale') ? 1
      frames = framesMap[scale + "_" + action.animation]
      continue unless frames
      frames = @mapFrames(action.frames, frames[0]) if action.frames?
      next = true
      next = action.goesTo if action.goesTo
      next = false if action.loops is false
      @builder.addAnimation name, frames, next

    for name, action of @actions when action.container and not action.animation
      continue if name is 'portrait'
      scale = @options.resolutionFactor * (action.scale or @get('scale') or 1)
      s = @vectorParser.buildContainerFromStore(action.container)
      continue unless s
      frame = @builder.addFrame(s, s.bounds, scale)
      @builder.addAnimation name, [frame], false

  requiredRawAnimations: ->
    required = []
    for name, action of @get('actions')
      continue if name is 'portrait'
      allActions = [action].concat(_.values (action.relatedActions ? {}))
      for a in allActions when a.animation
        scale = if name is 'portrait' then a.scale or 1 else a.scale or @get('scale') or 1
        animation = {animation: a.animation, scale: scale}
        animation.portrait = name is 'portrait'
        unless _.find(required, (r) -> _.isEqual r, animation)
          required.push animation
    required

  mapFrames: (frames, frameOffset) ->
    return frames unless _.isString(frames) # don't accidentally do this again
    (parseInt(f, 10) + frameOffset for f in frames.split(','))

  finishBuild: ->
    return if _.isEmpty(@builder._animations)
    key = @spriteSheetKey(@options)
    spriteSheet = null
    if @options.async
      buildQueue.push @builder
      @builder.t0 = new Date().getTime()
      @builder.buildAsync() unless buildQueue.length > 1
      @builder.on 'complete', @onBuildSpriteSheetComplete, @, true, key
      return true
    t0 = new Date()
    spriteSheet = @builder.build()
    console.warn "Built #{@get('name')} in #{new Date() - t0}ms on main thread."
    @spriteSheets[key] = spriteSheet
    delete @building[key]
    spriteSheet

  onBuildSpriteSheetComplete: (e, key) ->
    console.log "Built #{@get('name')} async in #{new Date().getTime() - @builder.t0}ms." if @builder
    buildQueue = buildQueue.slice(1)
    buildQueue[0].t0 = new Date().getTime() if buildQueue[0]
    buildQueue[0]?.buildAsync()
    @spriteSheets[key] = e.target.spriteSheet
    delete @building[key]
    @trigger 'build-complete'
    @builder = null
    @vectorParser = null

  spriteSheetKey: (options) ->
    colorConfigs = []
    for groupName, config of options.colorConfig or {}
      colorConfigs.push "#{groupName}:#{config.hue}|#{config.saturation}|#{config.lightness}"
    colorConfigs = colorConfigs.join ','
    portraitOnly = !!options.portraitOnly
    "#{@get('name')} - #{options.resolutionFactor} - #{colorConfigs} - #{portraitOnly}"

  getPortraitImage: (spriteOptionsOrKey, size=100) ->
    src = @getPortraitSource(spriteOptionsOrKey, size)
    return null unless src
    $('<img />').attr('src', src)

  getPortraitSource: (spriteOptionsOrKey, size=100) ->
    stage = @getPortraitStage(spriteOptionsOrKey, size)
    stage?.toDataURL()

  getPortraitStage: (spriteOptionsOrKey, size=100) ->
    key = spriteOptionsOrKey
    key = if _.isString(key) then key else @spriteSheetKey(@fillOptions(key))
    spriteSheet = @spriteSheets[key]
    if not spriteSheet
      options = if _.isPlainObject spriteOptionsOrKey then spriteOptionsOrKey else {}
      options.portraitOnly = true
      spriteSheet = @buildSpriteSheet(options)
    return unless spriteSheet
    canvas = $("<canvas width='#{size}' height='#{size}'></canvas>")
    stage = new createjs.Stage(canvas[0])
    sprite = new createjs.Sprite(spriteSheet)
    pt = @actions.portrait?.positions?.registration
    sprite.regX = pt?.x or 0
    sprite.regY = pt?.y or 0
    sprite.framerate = @actions.portrait?.framerate ? 20
    sprite.gotoAndStop 'portrait'
    stage.addChild(sprite)
    stage.update()
    stage.startTalking = ->
      sprite.gotoAndPlay 'portrait'
      return if @tick
      @tick = (e) => @update(e)
      createjs.Ticker.addEventListener 'tick', @tick
    stage.stopTalking = ->
      sprite.gotoAndStop 'portrait'
      @update()
      createjs.Ticker.removeEventListener 'tick', @tick
      @tick = null
    stage

  uploadGenericPortrait: (callback) ->
    src = @getPortraitSource()
    return callback?() unless src
    src = src.replace('data:image/png;base64,', '').replace(/\ /g, '+')
    body =
      filename: 'portrait.png'
      mimetype: 'image/png'
      path: "db/thang.type/#{@get('original')}"
      b64png: src
      force: 'true'
    $.ajax('/file', { type: 'POST', data: body, success: callback or @onFileUploaded })

  onFileUploaded: =>
    console.log 'Image uploaded'

  @loadUniversalWizard: ->
    return @wizardType if @wizardType
    wizOriginal = "52a00d55cf1818f2be00000b"
    url = "/db/thang.type/#{wizOriginal}/version"
    @wizardType = new module.exports()
    @wizardType.url = -> url
    @wizardType.fetch()
    @wizardType
