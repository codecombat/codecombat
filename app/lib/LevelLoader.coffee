Level = require 'models/Level'
CocoClass = require 'lib/CocoClass'
AudioPlayer = require 'lib/AudioPlayer'
LevelSession = require 'models/LevelSession'
ThangType = require 'models/ThangType'
app = require 'application'
World = require 'lib/world/world'

# This is an initial stab at unifying loading and setup into a single place which can
# monitor everything and keep a LoadingScreen visible overall progress.
#
# Would also like to incorporate into here:
#  * World Building
#  * Sprite map generation
#  * Connecting to Firebase

module.exports = class LevelLoader extends CocoClass

  spriteSheetsBuilt: 0
  spriteSheetsToBuild: 0

  subscriptions:
    'god:new-world-created': 'loadSoundsForWorld'

  constructor: (options) ->
    super()
    @supermodel = options.supermodel
    @levelID = options.levelID
    @sessionID = options.sessionID
    @opponentSessionID = options.opponentSessionID
    @team = options.team
    @headless = options.headless

    @loadSession()
    @loadLevelModels()
    @loadAudio()
    @playJingle()
    _.defer @update  # Lets everything else resolve first

  playJingle: ->
    return if @headless
    jingles = ["ident_1", "ident_2"]
    AudioPlayer.playInterfaceSound jingles[Math.floor Math.random() * jingles.length]

  # Session Loading

  loadSession: ->
    if @sessionID
      url = "/db/level_session/#{@sessionID}"
    else
      url = "/db/level/#{@levelID}/session"
      url += "?team=#{@team}" if @team

    @session = new LevelSession()
    @session.url = -> url

    # Unless you specify cache:false, sometimes the browser will use a cached session
    # and players will 'lose' code
    @session.fetch({cache:false})
    @session.once 'sync', @onSessionLoaded, @

    if @opponentSessionID
      @opponentSession = new LevelSession()
      @opponentSession.url = "/db/level_session/#{@opponentSessionID}"
      @opponentSession.fetch()
      @opponentSession.once 'sync', @onSessionLoaded, @

  sessionsLoaded: ->
    @session.loaded and ((not @opponentSession) or @opponentSession.loaded)

  onSessionLoaded: ->
    # TODO: maybe have all non versioned models do this? Or make it work to PUT/PATCH to relative urls
    if @session.loaded
      @session.url = -> '/db/level.session/' + @id
    @update() if @sessionsLoaded()

  # Supermodel (Level) Loading

  loadLevelModels: ->
    @supermodel.on 'loaded-one', @onSupermodelLoadedOne, @
    @supermodel.once 'error', @onSupermodelError, @
    @level = @supermodel.getModel(Level, @levelID) or new Level _id: @levelID
    levelID = @levelID
    headless = @headless

    @supermodel.shouldPopulate = (model) ->
      # if left unchecked, the supermodel would load this level
      # and every level next on the chain. This limits the population
      handles = [model.id, model.get 'slug']
      return model.constructor.className isnt "Level" or levelID in handles

    @supermodel.shouldLoadProjection = (model) ->
      return true if headless and model.constructor.className is 'ThangType'
      false

    @supermodel.populateModel @level

  onSupermodelError: ->
    msg = $.i18n.t('play_level.level_load_error',
      defaultValue: "Level could not be loaded.")
    @$el.html('<div class="alert">' + msg + '</div>')

  onSupermodelLoadedOne: (e) ->
    @notifyProgress()

  # Things to do when either the Session or Supermodel load

  update: =>
    @notifyProgress()

    return if @updateCompleted
    return unless @supermodel.finished() and @sessionsLoaded()
    @denormalizeSession()
    @loadLevelSounds()
    app.tracker.updatePlayState(@level, @session)
    @updateCompleted = true

  denormalizeSession: ->
    return if @session.get 'levelName'
    patch =
      'levelName': @level.get('name')
      'levelID': @level.get('slug') or @level.id
    if me.id is @session.get 'creator'
      patch.creatorName = me.get('name')

    @session.set key, value for key, value of patch
    tempSession = new LevelSession _id: @session.id
    tempSession.save(patch, {patch: true})
    @sessionDenormalized = true

  # World init

  initWorld: ->
    return if @initialized
    @initialized = true
    @world = new World @level.get('name')
    serializedLevel = @level.serialize(@supermodel)
    @world.loadFromLevel serializedLevel, false
    @buildSpriteSheets()

  buildSpriteSheets: ->
    return if @headless
    thangTypes = {}
    thangTypes[tt.get('name')] = tt for tt in @supermodel.getModels(ThangType)

    colorConfigs = @world.getTeamColors()

    thangsProduced = {}
    baseOptions = {resolutionFactor: 4, async: true}

    for thang in @world.thangs
      continue unless thang.spriteName
      thangType = thangTypes[thang.spriteName]
      options = thang.getSpriteOptions(colorConfigs)
      options.async = true
      thangsProduced[thang.spriteName] = true
      @buildSpriteSheet(thangType, options)

    for thangName, thangType of thangTypes
      continue if thangsProduced[thangName]
      thangType.spriteOptions = {resolutionFactor: 4, async: true}
      @buildSpriteSheet(thangType, thangType.spriteOptions)

  buildSpriteSheet: (thangType, options) ->
    if thangType.get('name') is 'Wizard'
      options.colorConfig = me.get('wizard')?.colorConfig or {}
    building = thangType.buildSpriteSheet options
    return unless building
    console.log 'Building:', thangType.get('name'), options
    @spriteSheetsToBuild += 1
    thangType.once 'build-complete', =>
      @spriteSheetsBuilt += 1
      @notifyProgress()

  # Initial Sound Loading

  loadAudio: ->
    return if @headless
    AudioPlayer.preloadInterfaceSounds ["victory"]

  loadLevelSounds: ->
    return if @headless
    scripts = @level.get 'scripts'
    return unless scripts

    for script in scripts when script.noteChain
      for noteGroup in script.noteChain when noteGroup.sprites
        for sprite in noteGroup.sprites when sprite.say?.sound
          AudioPlayer.preloadSoundReference(sprite.say.sound)

    thangTypes = @supermodel.getModels(ThangType)
    for thangType in thangTypes
      for trigger, sounds of thangType.get('soundTriggers') or {} when trigger isnt 'say'
        AudioPlayer.preloadSoundReference sound for sound in sounds

  # Dynamic sound loading

  loadSoundsForWorld: (e) ->
    return if @headless
    world = e.world
    thangTypes = @supermodel.getModels(ThangType)
    for [spriteName, message] in world.thangDialogueSounds()
      continue unless thangType = _.find thangTypes, (m) -> m.get('name') is spriteName
      continue unless sound = AudioPlayer.soundForDialogue message, thangType.get('soundTriggers')
      filename = AudioPlayer.preloadSoundReference sound

  # everything else sound wise is loaded as needed as worlds are generated

  allDone: ->
    @supermodel.finished() and @sessionsLoaded() and @spriteSheetsBuilt is @spriteSheetsToBuild

  progress: ->
    return 0 unless @level.loaded
    overallProgress = 0
    supermodelProgress = @supermodel.progress()
    overallProgress += supermodelProgress * 0.7
    overallProgress += 0.1 if @sessionsLoaded()
    if @headless
      spriteMapProgress = 0.2
    else
      spriteMapProgress = if supermodelProgress is 1 then 0.2 else 0
      spriteMapProgress *= @spriteSheetsBuilt / @spriteSheetsToBuild if @spriteSheetsToBuild
    overallProgress += spriteMapProgress
    return overallProgress

  notifyProgress: ->
    Backbone.Mediator.publish 'level-loader:progress-changed', progress: @progress()
    @initWorld() if @allDone()
    @trigger 'loaded-all' if @progress() is 1

  destroy: ->
    @supermodel.off 'loaded-one', @onSupermodelLoadedOne
    @world = null  # don't hold onto garbage
    @update = null
    super()
