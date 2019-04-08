CocoModel = require './CocoModel'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
LevelComponent = require './LevelComponent'
CocoCollection = require 'collections/CocoCollection'
createjs = require 'lib/createjs-parts'
ThangTypeConstants = require 'lib/ThangTypeConstants'
ThangTypeLib = require 'lib/ThangTypeLib'

utils = require 'core/utils'

buildQueue = []

module.exports = class ThangType extends CocoModel
  @className: 'ThangType'
  @schema: require 'schemas/models/thang_type'
  @heroes: ThangTypeConstants.heroes
  @heroClasses: ThangTypeConstants.heroClasses
  @items: ThangTypeConstants.items
  urlRoot: '/db/thang.type'
  building: {}
  editableByArtisans: true
  @defaultActions: ['idle', 'die', 'move', 'attack', 'trick', 'cast']
  @heroConfigStats: {}  # Build a cache of these for quickly determining hero/item loadout aggregate stats

  initialize: ->
    super()
    @building = {}
    @spriteSheets = {}

    ## Testing memory clearing
    #f = =>
    #  console.info 'resetting raw data'
    #  @unset 'raw'
    #  @_previousAttributes.raw = null
    #setTimeout f, 40000

  resetRawData: ->
    @set('raw', {shapes: {}, containers: {}, animations: {}})

  resetSpriteSheetCache: ->
    @buildActions()
    @spriteSheets = {}
    @building = {}

  isFullyLoaded: ->
    # TODO: Come up with a better way to identify when the model doesn't have everything needed to build the sprite. ie when it's a projection without all the required data.
    return @get('actions') or @get('raster') # needs one of these two things

  loadRasterImage: ->
    return if @loadingRaster or @loadedRaster
    return unless raster = @get('raster')
    # IE11 does not support CORS for images in the canvas element
    # https://caniuse.com/#feat=cors
    @rasterImage = if utils.isIE() then $("<img src='/file/#{raster}' />")
    else $("<img crossOrigin='Anonymous', src='/file/#{raster}' />")
    @loadingRaster = true
    @rasterImage.one('load', =>
      @loadingRaster = false
      @loadedRaster = true
      @trigger('raster-image-loaded', @))
    @rasterImage.one('error', =>
      @loadingRaster = false
      @trigger('raster-image-load-errored', @)
    )

  getActions: ->
    return {} unless @isFullyLoaded()
    return @actions or @buildActions()

  getDefaultActions: ->
    actions = []
    for action in _.values(@getActions())
      continue unless _.any ThangType.defaultActions, (prefix) ->
        _.string.startsWith(action.name, prefix)
      actions.push(action)
    return actions

  buildActions: ->
    return null unless @isFullyLoaded()
    @actions = $.extend(true, {}, @get('actions'))
    for name, action of @actions
      action.name = name
      for relatedName, relatedAction of action.relatedActions ? {}
        relatedAction.name = action.name + '_' + relatedName
        @actions[relatedAction.name] = relatedAction
    @actions

  fillOptions: (options) ->
    options ?= {}
    options = _.clone options
    options.resolutionFactor ?= SPRITE_RESOLUTION_FACTOR
    options.async ?= false
    options.thang = null  # Don't hold onto any bad Thang references.
    options

  buildSpriteSheet: (options) ->
    return false unless @isFullyLoaded() and @get 'raw'
    @options = @fillOptions options
    key = @spriteSheetKey(@options)
    if ss = @spriteSheets[key] then return ss
    if @building[key]
      @options = null
      return key
    @t0 = new Date().getTime()
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
      framesMap[animation.scale + '_' + name] = @builder._animations[name].frames

    for name, action of @actions when action.animation
      continue if name is 'portrait'
      scale = action.scale ? @get('scale') ? 1
      frames = framesMap[scale + '_' + action.animation]
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
      @builder.on 'complete', @onBuildSpriteSheetComplete, @, true, [@builder, key, @options]
      @builder = null
      return key
    spriteSheet = @builder.build()
    @logBuild @t0, false, @options.portraitOnly
    @spriteSheets[key] = spriteSheet
    @building[key] = false
    @builder = null
    @options = null
    spriteSheet

  onBuildSpriteSheetComplete: (e, data) ->
    [builder, key, options] = data
    @logBuild builder.t0, true, options.portraitOnly
    buildQueue = buildQueue.slice(1)
    buildQueue[0].t0 = new Date().getTime() if buildQueue[0]
    buildQueue[0]?.buildAsync()
    @spriteSheets[key] = e.target.spriteSheet
    @building[key] = false
    @trigger 'build-complete', {key: key, thangType: @}
    @vectorParser = null

  logBuild: (startTime, async, portrait) ->
    kind = if async then 'Async' else 'Sync '
    portrait = if portrait then '(Portrait)' else ''
    name = _.string.rpad @get('name'), 20
    time = _.string.lpad '' + new Date().getTime() - startTime, 6
    console.debug "Built sheet:  #{name} #{time}ms  #{kind}  #{portrait}"

  spriteSheetKey: (options) ->
    colorConfigs = []
    for groupName, config of options.colorConfig or {}
      colorConfigs.push "#{groupName}:#{config.hue}|#{config.saturation}|#{config.lightness}"
    colorConfigs = colorConfigs.join ','
    portraitOnly = !!options.portraitOnly
    "#{@get('name')} - #{options.resolutionFactor} - #{colorConfigs} - #{portraitOnly}"

  getHeroShortName: -> ThangTypeLib.getHeroShortName(@attributes)

  getGender: -> ThangTypeLib.getGender(@attributes)

  getPortraitImage: (spriteOptionsOrKey, size=100) ->
    src = @getPortraitSource(spriteOptionsOrKey, size)
    return null unless src
    $('<img />').attr('src', src)

  getPortraitSource: (spriteOptionsOrKey, size=100) ->
    return @getPortraitURL() if @get('rasterIcon') or @get('raster')
    stage = @getPortraitStage(spriteOptionsOrKey, size)
    stage?.toDataURL()

  getPortraitStage: (spriteOptionsOrKey, size=100) ->
    canvas = $("<canvas width='#{size}' height='#{size}'></canvas>")
    try
      stage = new createjs.Stage(canvas[0])
    catch err
      console.error "Error trying to create #{@get('name')} avatar stage:", err, "with window as", window
      return null
    return stage unless @isFullyLoaded()
    key = spriteOptionsOrKey
    key = if _.isString(key) then key else @spriteSheetKey(@fillOptions(key))
    spriteSheet = @spriteSheets[key]
    if not spriteSheet
      options = if _.isPlainObject spriteOptionsOrKey then spriteOptionsOrKey else {}
      options.portraitOnly = true
      spriteSheet = @buildSpriteSheet(options)
    return if _.isString spriteSheet
    return unless spriteSheet
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
      return  # TODO: causes infinite recursion in new EaselJS
      return if @tick
      @tick = (e) => @update(e)
      createjs.Ticker.addEventListener 'tick', @tick
    stage.stopTalking = ->
      sprite.gotoAndStop 'portrait'
      return  # TODO: just breaks in new EaselJS
      @update()
      createjs.Ticker.removeEventListener 'tick', @tick
      @tick = null
    stage

  getVectorPortraitStage: (size=100) ->
    return unless @actions
    canvas = $("<canvas width='#{size}' height='#{size}'></canvas>")
    stage = new createjs.Stage(canvas[0])
    portrait = @actions.portrait
    return unless portrait and (portrait.animation or portrait.container)
    scale = portrait.scale or 1

    vectorParser = new SpriteBuilder(@, {})
    if portrait.animation
      sprite = vectorParser.buildMovieClip portrait.animation
      sprite.gotoAndStop(0)
    else if portrait.container
      sprite = vectorParser.buildContainerFromStore(portrait.container)

    pt = portrait.positions?.registration
    sprite.regX = pt?.x / scale or 0
    sprite.regY = pt?.y / scale or 0
    sprite.scaleX = sprite.scaleY = scale * size / 100
    stage.addChild(sprite)
    stage.update()
    stage

  uploadGenericPortrait: (callback, src) ->
    src ?= @getPortraitSource()
    return callback?() unless src and _.string.startsWith src, 'data:'
    src = src.replace('data:image/png;base64,', '').replace(/\ /g, '+')
    body =
      filename: 'portrait.png'
      mimetype: 'image/png'
      path: "db/thang.type/#{@get('original')}"
      b64png: src
      force: 'true'
    $.ajax('/file', {type: 'POST', data: body, success: callback or @onFileUploaded})

  onFileUploaded: =>
    console.log 'Image uploaded'

  @loadUniversalWizard: ->
    return @wizardType if @wizardType
    wizOriginal = '52a00d55cf1818f2be00000b'
    url = "/db/thang.type/#{wizOriginal}/version"
    @wizardType = new module.exports()
    @wizardType.url = -> url
    @wizardType.fetch()
    @wizardType

  getPortraitURL: -> ThangTypeLib.getPortraitURL(@attributes)

  # Item functions

  getAllowedSlots: ->
    itemComponentRef = _.find(
      @get('components') or [],
      (compRef) -> compRef.original is LevelComponent.ItemID)
    return itemComponentRef?.config?.slots or ['right-hand']  # ['right-hand'] is default

  getAllowedHeroClasses: ->
    return [heroClass] if heroClass = @get 'heroClass'
    ['Warrior', 'Ranger', 'Wizard']

  getHeroStats: ->
    # Translate from raw hero properties into appropriate display values for the PlayHeroesModal.
    # Adapted from https://docs.google.com/a/codecombat.com/spreadsheets/d/1BGI1bzT4xHvWA81aeyIaCKWWw9zxn7-MwDdydmB5vw4/edit#gid=809922675
    return unless heroClass = @get('heroClass')
    components = @get('components') or []
    unless equipsConfig = _.find(components, original: LevelComponent.EquipsID)?.config
      return console.warn @get('name'), 'is not an equipping hero, but you are asking for its hero stats. (Did you project away components?)'
    unless movesConfig = _.find(components, original: LevelComponent.MovesID)?.config
      return console.warn @get('name'), 'is not a moving hero, but you are asking for its hero stats.'
    unless programmableConfig = _.find(components, original: LevelComponent.ProgrammableID)?.config
      return console.warn @get('name'), 'is not a Programmable hero, but you are asking for its hero stats.'
    @classStatAverages ?=
      attack: {Warrior: 7.5, Ranger: 5, Wizard: 2.5}
      health: {Warrior: 7.5, Ranger: 5, Wizard: 3.5}
    stats = {}
    rawNumbers = attack: equipsConfig.attackDamageFactor ? 1, health: equipsConfig.maxHealthFactor ? 1, speed: movesConfig.maxSpeed
    for prop in ['attack', 'health']
      stat = rawNumbers[prop]
      if stat < 1
        classSpecificScore = 10 - 5 / stat
      else
        classSpecificScore = stat * 5
      classAverage = @classStatAverages[prop][@get('heroClass')]
      stats[prop] =
        relative: Math.round(2 * ((classAverage - 2.5) + classSpecificScore / 2)) / 2 / 10
        absolute: stat
      pieces = ($.i18n.t "choose_hero.#{prop}_#{num}" for num in [1 .. 3])
      percent = Math.round(stat * 100) + '%'
      className = $.i18n.t "general.#{_.string.slugify @get('heroClass')}"
      stats[prop].description = [pieces[0], percent, pieces[1], className, pieces[2]].join ' '

    minSpeed = 4
    maxSpeed = 16
    speedRange = maxSpeed - minSpeed
    speedPoints = rawNumbers.speed - minSpeed
    stats.speed =
      relative: Math.round(20 * speedPoints / speedRange) / 2 / 10
      absolute: rawNumbers.speed
      description: "#{$.i18n.t 'choose_hero.speed_1'} #{rawNumbers.speed} #{$.i18n.t 'choose_hero.speed_2'}"

    stats.skills = (_.string.titleize(_.string.humanize(skill)) for skill in programmableConfig.programmableProperties when skill isnt 'say' and not /(Range|Pos|Radius|Damage)$/.test(skill))

    stats

  getFrontFacingStats: ->
    components = @get('components') or []
    unless itemConfig = _.find(components, original: LevelComponent.ItemID)?.config
      console.warn @get('name'), 'is not an item, but you are asking for its stats.'
      return props: [], stats: {}
    stats = {}
    props = itemConfig.programmableProperties ? []
    props = props.concat itemConfig.moreProgrammableProperties ? []
    props = _.without props, 'canCast', 'spellNames', 'spells'
    for stat, modifiers of itemConfig.stats ? {}
      stats[stat] = @formatStatDisplay stat, modifiers
    for stat in itemConfig.extraHUDProperties ? []
      stats[stat] ?= null  # Find it in the other Components.
    for component in components
      continue unless config = component.config
      for stat, value of stats when not value?
        value = config[stat]
        continue unless value?
        stats[stat] = @formatStatDisplay stat, setTo: value
        if stat is 'attackDamage'
          dps = (value / (config.cooldown or 0.5)).toFixed(1)
          stats[stat].display += " (#{dps} DPS)"
      if config.programmableSnippets
        props = props.concat config.programmableSnippets
    for stat, value of stats when not value?
      stats[stat] = name: stat, display: '???'
    statKeys = _.keys(stats)
    statKeys.sort()
    props.sort()
    sortedStats = {}
    sortedStats[key] = stats[key] for key in statKeys
    props: props, stats: sortedStats

  formatStatDisplay: (name, modifiers) ->
    i18nKey = {
      maxHealth: 'health'
      maxSpeed: 'speed'
      healthReplenishRate: 'regeneration'
      attackDamage: 'attack'
      attackRange: 'range'
      shieldDefenseFactor: 'blocks'
      visualRange: 'range'
      throwDamage: 'attack'
      throwRange: 'range'
      bashDamage: 'attack'
      backstabDamage: 'backstab'
    }[name]

    if i18nKey
      name = $.i18n.t 'choose_hero.' + i18nKey
      matchedShortName = true
    else
      name = _.string.humanize name
      matchedShortName = false

    format = ''
    format = 'm' if /(range|radius|distance|vision)$/i.test name
    format ||= 's' if /cooldown$/i.test name
    format ||= 'm/s' if /speed$/i.test name
    format ||= '/s' if /(regeneration| rate)$/i.test name
    value = modifiers.setTo
    if /(blocks)$/i.test name
      format ||= '%'
      value = (value*100).toFixed(1)
    value = value.join ', ' if _.isArray value
    display = []
    display.push "#{value}#{format}" if value?
    display.push "+#{modifiers.addend}#{format}" if modifiers.addend > 0
    display.push "#{modifiers.addend}#{format}" if modifiers.addend < 0
    display.push "x#{modifiers.factor}" if modifiers.factor? and modifiers.factor isnt 1
    display = display.join ', '
    display = display.replace /9001m?/, 'Infinity'
    name: name, display: display, matchedShortName: matchedShortName

  isSilhouettedItem: ->
    return console.error "Trying to determine whether #{@get('name')} should be a silhouetted item, but it has no gem cost." unless @get('gems')? or @get('tier')?
    console.info "Add (or make sure you have fetched) a tier for #{@get('name')} to more accurately determine whether it is silhouetted." unless @get('tier')?
    tier = @get 'tier'
    if tier?
      return @levelRequiredForItem() > me.level()
    points = me.get('points')
    expectedTotalGems = (points ? 0) * 1.5   # Not actually true, but roughly kinda close for tier 0, kinda tier 1
    @get('gems') > (100 + expectedTotalGems) * 1.2

  levelRequiredForItem: ->
    return console.error "Trying to determine what level is required for #{@get('name')}, but it has no tier." unless @get('tier')?
    itemTier = @get 'tier'
    playerTier = itemTier / 2.5
    playerLevel = me.constructor.levelForTier playerTier
    #console.log 'Level required for', @get('name'), 'is', playerLevel, 'player tier', playerTier, 'because it is itemTier', itemTier, 'which is normally level', me.constructor.levelForTier(itemTier)
    playerLevel

  getContainersForAnimation: (animation, action) ->
    rawAnimation = @get('raw').animations[animation]
    if not rawAnimation
      console.error 'thang type', @get('name'), 'is missing animation', animation, 'from action', action
    containers = rawAnimation.containers
    for animation in @get('raw').animations[animation].animations
      containers = containers.concat(@getContainersForAnimation(animation.gn, action))
    return containers

  getContainersForActions: (actionNames) ->
    containersToRender = {}
    actions = @getActions()
    for actionName in actionNames
      action = _.find(actions, {name: actionName})
      if action.container
        containersToRender[action.container] = true
      else if action.animation
        animationContainers = @getContainersForAnimation(action.animation, action)
        containersToRender[container.gn] = true for container in animationContainers
    return _.keys(containersToRender)

  nextForAction: (action) ->
    next = true
    next = action.goesTo if action.goesTo
    next = false if action.loops is false
    return next

  noRawData: -> not @get('raw')

  initPrerenderedSpriteSheets: ->
    return if @prerenderedSpriteSheets or not data = @get('prerenderedSpriteSheetData')
    # creates a collection of prerendered sprite sheets
    @prerenderedSpriteSheets = new PrerenderedSpriteSheets(data)

  getPrerenderedSpriteSheet: (colorConfig, defaultSpriteType) ->
    return unless @prerenderedSpriteSheets
    spriteType = @get('spriteType') or defaultSpriteType
    result = @prerenderedSpriteSheets.find (pss) ->
      return false if pss.get('spriteType') isnt spriteType
      otherColorConfig = pss.get('colorConfig')
      return true if _.isEmpty(colorConfig) and _.isEmpty(otherColorConfig)
      getHue = (config) -> _.result(_.result(config, 'team'), 'hue')
      return getHue(colorConfig) is getHue(otherColorConfig)
    if (not result) and @noRawData()
      return @prerenderedSpriteSheets.first() # there can only be one
    return result

  getPrerenderedSpriteSheetToLoad: ->
    return unless @prerenderedSpriteSheets
    if @noRawData()
      return @prerenderedSpriteSheets.first() # there can only be one
    @prerenderedSpriteSheets.find (pss) -> pss.needToLoad and not pss.loadedImage

  onLoaded: ->
    super()
    return if ThangType.heroConfigStats[@get('original')]
    # Cache certain component properties for quickly determining hero/item loadout aggregate stats
    components = @get('components') or []
    return unless components.length
    return if not @get('gems')? and (
      (@project and not /gems/.test(@project)) or
      (/project/.test(@getURL()) and not /gems/.test(@getURL())) or
      (@collection?.project and not /gems/.test(@collection?.project)) or
      (/project/.test(@collection?.getURL()) and not /gems/.test(@collection?.getURL()))
    )
    stats = gems: @get('gems') or 0
    if itemConfig = _.find(components, original: LevelComponent.ItemID)?.config
      stats.kind = 'item'
      stats.speed = speed if speed = itemConfig.stats?.maxSpeed?.addend
      stats.health = health if health = itemConfig.stats?.maxHealth?.addend
      if attacksConfig = _.find(components, original: LevelComponent.AttacksID)?.config
        stats.attack = (attacksConfig.attackDamage ? 3) / (attacksConfig.cooldown ? 1)
      ThangType.heroConfigStats[@get('original')] = stats
    else if equipsConfig = _.find(components, original: LevelComponent.EquipsID)?.config
      stats.kind = 'hero'
      stats.attackMultiplier = equipsConfig.attackDamageFactor ? 1
      stats.healthMultiplier = equipsConfig.maxHealthFactor ? 1
      if movesConfig = _.find(components, original: LevelComponent.MovesID)?.config
        stats.speed = movesConfig.maxSpeed ? 3.6
      if attackableConfig = _.find(components, original: LevelComponent.AttackableID)?.config
        stats.baseHealth = attackableConfig.maxHealth ? 11
      ThangType.heroConfigStats[@get('original')] = stats
    null

  @calculateStatsForHeroConfig: (heroConfig, callback) ->
    # Load enough information from the ThangTypes involved in a hero configuration to show various stats the hero will have.
    # We don't rely on any supermodel caches, because this ThangType projection is useless anywhere else.
    thisHeroConfigStats = {}
    heroOriginal = heroConfig.thangType ? ThangType.heroes.captain
    for original in _.values(heroConfig.inventory).concat [heroOriginal]
      thisHeroConfigStats[original] = ThangType.heroConfigStats[original] or 'loading'
    for original, stats of thisHeroConfigStats when stats is 'loading'
      url = "/db/thang.type/#{original}/version?project=original,components,gems"
      tt = new ThangType().setURL url
      do (tt) =>
        tt.on 'sync', =>
          thisHeroConfigStats[tt.get('original')] = ThangType.heroConfigStats[tt.get('original')]
          tt.off 'sync'
          tt.destroy()
          @formatStatsForHeroConfig thisHeroConfigStats, callback
      tt.fetch()
    @formatStatsForHeroConfig thisHeroConfigStats, callback

  @formatStatsForHeroConfig: (heroConfigStats, callback) ->
    heroConfigStatValues = _.values heroConfigStats
    return if 'loading' in heroConfigStatValues
    heroStats = _.find heroConfigStatValues, kind: 'hero'
    totals = {health: heroStats.baseHealth ? 11, speed: 0, gems: 0}
    for stats in heroConfigStatValues
      totals.gems += stats.gems if stats.gems
      totals.health += stats.health * (heroStats.healthMultiplier or 1) if stats.health
      totals.attack = stats.attack * (heroStats.attackMultiplier or 1) if stats.attack
      totals.speed += stats.speed if stats.speed
    callback totals


class PrerenderedSpriteSheet extends CocoModel
  @className: 'PrerenderedSpriteSheet'

  loadImage: ->
    return true if @loadingImage
    return false if @loadedImage
    return false unless imageURL = @get('image')
    @image = $("<img crossOrigin='Anonymous', src='/file/#{imageURL}' />")
    @loadingImage = true
    @image.one('load', =>
      @loadingImage = false
      @loadedImage = true
      @buildSpriteSheet()
      @trigger('image-loaded', @))
    @image.one('error', =>
      @loadingImage = false
      @trigger('image-load-error', @)
    )
    return true

  buildSpriteSheet: ->
    @spriteSheet = new createjs.SpriteSheet({
      images: [@image[0]],
      frames: @get('frames')
      animations: @get('animations')
    })

  markToLoad: -> @needToLoad = true

  needToLoad: false
  loadedImage: false
  loadingImage: false


class PrerenderedSpriteSheets extends CocoCollection
  model: PrerenderedSpriteSheet
