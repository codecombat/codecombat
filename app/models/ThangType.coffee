CocoModel = require('./CocoModel')
SpriteBuilder = require 'lib/sprites/SpriteBuilder'

module.exports = class ThangType extends CocoModel
  @className: "ThangType"
  urlRoot: "/db/thang.type"
  building: 0

  initialize: ->
    super()
    @setDefaults()
    @on 'sync', @setDefaults
    @spriteSheets = {}

  setDefaults: ->
    @resetRawData() unless @get('raw')

  resetRawData: ->
    @set('raw', {shapes:{}, containers:{}, animations:{}})

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
    
  resetSpriteSheetCache: ->
    @buildActions()
    @spriteSheets = {}

  getActions: ->
    return @actions or @buildActions()
    
  buildActions: ->
    @actions = _.cloneDeep(@get('actions'))
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
    @initBuild(options)
#    @options.portraitOnly = true
    @addGeneralFrames() unless @options.portraitOnly
    @addPortrait()
    @finishBuild()

  initBuild: (options) ->
    @buildActions() if not @actions
    @options = @fillOptions options
    @vectorParser = new SpriteBuilder(@)
    @builder = new createjs.SpriteSheetBuilder()
    @builder.padding = 2
    @frames = {}
    
  addPortrait: ->
    # The portrait is built very differently than the other animations, so it gets a separate function.
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
      frames = @normalizeFrames(portrait.frames, frames[0]) if portrait.frames?
      portrait.frames = frames
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
      @builder.addMovieClip mc, null, animation.scale * @options.resolutionFactor
      framesMap[animation.scale + "_" + name] = @builder._animations[name].frames

    for name, action of @actions when action.animation
      continue if name is 'portrait'
      scale = action.scale ? @get('scale') ? 1
      frames = framesMap[scale + "_" + action.animation]
      frames = @mapFrames(action.frames, frames[0]) if action.frames?
      action.frames = frames  # Keep generated frame numbers around
      next = true
      next = action.goesTo if action.goesTo
      next = false if action.loops is false
      @builder.addAnimation name, frames, next
      
    for name, action of @actions when action.container and not action.animation
      continue if name is 'portrait'
      scale = @options.resolutionFactor * (action.scale or @get('scale') or 1)
      s = @vectorParser.buildContainerFromStore(action.container)
      frame = @builder.addFrame(s, s.bounds, scale)
      @builder.addAnimation name, [frame], false
      
  mapFrames: (frames, frameOffset) ->
    return frames unless _.isString(frames) # don't accidentally do this again
    (parseInt(f, 10) + frameOffset for f in frames.split(','))

  finishBuild: ->
    return if _.isEmpty(@builder._animations)
    key = @spriteSheetKey(@options)
    spriteSheet = null
    if @options.async
      @builder.buildAsync()
      @builder.on 'complete', @onBuildSpriteSheetComplete, @, true, key
      return true
    
    console.warn 'Building', @get('name'), 'and blocking the main thread. LevelLoader should have it built asynchronously instead.'
    spriteSheet = @builder.build()
    @spriteSheets[key] = spriteSheet
    spriteSheet
    
  onBuildSpriteSheetComplete: (e, key) ->
    @spriteSheets[key] = e.target.spriteSheet
    @trigger 'build-complete'

  spriteSheetKey: (options) ->
    "#{@get('name')} - #{options.resolutionFactor}"

  getPortrait: (spriteOptionsOrKey, size=100) ->
    key = spriteOptionsOrKey
    key = if _.isObject(key) then @spriteSheetKey(key) else key
    spriteSheet = @spriteSheets[key]
    return unless spriteSheet
    canvas = $("<canvas width='#{size}' height='#{size}'></canvas>")
    stage = new createjs.Stage(canvas[0])
    sprite = new createjs.Sprite(spriteSheet)
    pt = @actions.portrait?.positions?.registration
    sprite.regX = pt?.x or 0
    sprite.regY = pt?.y or 0
    sprite.gotoAndStop 'portrait'
    stage.addChild(sprite)
    stage.update()
    url = stage.toDataURL()
    img = $('<img />').attr('src', url)
