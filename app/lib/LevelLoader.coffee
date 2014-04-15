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

  constructor: (options) ->
    super()
    @supermodel = options.supermodel
    @levelID = options.levelID
    @sessionID = options.sessionID
    @opponentSessionID = options.opponentSessionID
    @team = options.team
    @headless = options.headless
    @spectateMode = options.spectateMode ? false

    @loadSession()
    @loadLevelModels()
    @loadAudio()
    @playJingle()
    _.defer @update  # Lets everything else resolve first

  playJingle: ->
    return if @headless
    # Apparently the jingle, when it tries to play immediately during all this loading, you can't hear it.
    # Add the timeout to fix this weird behavior.
    f = ->
      jingles = ["ident_1", "ident_2"]
      AudioPlayer.playInterfaceSound jingles[Math.floor Math.random() * jingles.length]
    setTimeout f, 500

  # Session Loading

  loadSession: ->
    return if @headless
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
    @listenToOnce(@session, 'sync', @onSessionLoaded)

    if @opponentSessionID
      @opponentSession = new LevelSession()
      @opponentSession.url = "/db/level_session/#{@opponentSessionID}"
      @opponentSession.fetch()
      @listenToOnce(@opponentSession, 'sync', @onSessionLoaded)

  sessionsLoaded: ->
    return true if @headless
    @session.loaded and ((not @opponentSession) or @opponentSession.loaded)

  onSessionLoaded: ->
    return if @destroyed
    # TODO: maybe have all non versioned models do this? Or make it work to PUT/PATCH to relative urls
    if @session.loaded
      @session.url = -> '/db/level.session/' + @id
    @update() if @sessionsLoaded()

  # Supermodel (Level) Loading

  loadLevelModels: ->
    @listenTo(@supermodel, 'loaded-one', @onSupermodelLoadedOne)
    @listenToOnce(@supermodel, 'error', @onSupermodelError)
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

  onSupermodelLoadedOne: (e) ->
    @buildSpriteSheetsForThangType e.model if not @headless and e.model instanceof ThangType
    @update() unless @destroyed

  # Things to do when either the Session or Supermodel load

  update: =>
    return if @destroyed
    @notifyProgress()

    return if @updateCompleted
    return unless @supermodel?.finished() and @sessionsLoaded()
    @denormalizeSession()
    @loadLevelSounds()
    app.tracker.updatePlayState(@level, @session) unless @headless
    @updateCompleted = true

  denormalizeSession: ->
    return if @headless or @sessionDenormalized or @spectateMode
    patch =
      'levelName': @level.get('name')
      'levelID': @level.get('slug') or @level.id
    if me.id is @session.get 'creator'
      patch.creatorName = me.get('name')
    for key, value of patch
      if @session.get(key) is value
        delete patch[key]
    unless _.isEmpty patch
      @session.set key, value for key, value of patch
      tempSession = new LevelSession _id: @session.id
      tempSession.save(patch, {patch: true})
    @sessionDenormalized = true

  # Building sprite sheets

  grabThangTypeTeams: ->
    @grabTeamConfigs()
    @thangTypeTeams = {}
    for thang in @level.get('thangs')
      for component in thang.components
        if team = component.config?.team
          @thangTypeTeams[thang.thangType] ?= []
          @thangTypeTeams[thang.thangType].push team unless team in @thangTypeTeams[thang.thangType]
          break
    @thangTypeTeams

  grabTeamConfigs: ->
    for system in @level.get('systems')
      if @teamConfigs = system.config?.teamConfigs
        break
    unless @teamConfigs
      # Hack: pulled from Alliance System code. TODO: put in just one place.
      @teamConfigs = {"humans":{"superteam":"humans","color":{"hue":0,"saturation":0.75,"lightness":0.5},"playable":true},"ogres":{"superteam":"ogres","color":{"hue":0.66,"saturation":0.75,"lightness":0.5},"playable":false},"neutral":{"superteam":"neutral","color":{"hue":0.33,"saturation":0.75,"lightness":0.5}}}
    @teamConfigs

  buildSpriteSheetsForThangType: (thangType) ->
    @grabThangTypeTeams() unless @thangTypeTeams
    for team in @thangTypeTeams[thangType.get('original')] ? [null]
      spriteOptions = {resolutionFactor: 4, async: false}
      if thangType.get('kind') is 'Floor'
        spriteOptions.resolutionFactor = 2
      if team and color = @teamConfigs[team]?.color
        spriteOptions.colorConfig = team: color
      @buildSpriteSheet thangType, spriteOptions

  buildSpriteSheet: (thangType, options) ->
    if thangType.get('name') is 'Wizard'
      options.colorConfig = me.get('wizard')?.colorConfig or {}
    building = thangType.buildSpriteSheet options
    return unless building
    #console.log 'Building:', thangType.get('name'), options
    @spriteSheetsToBuild += 1
    onBuildComplete = =>
      return if @destroyed
      @spriteSheetsBuilt += 1
      @notifyProgress()
    if options.async
      thangType.once 'build-complete', onBuildComplete
    else
      onBuildComplete()

  # World init

  initWorld: ->
    return if @initialized
    @initialized = true
    @world = new World @level.get('name')
    serializedLevel = @level.serialize(@supermodel)
    @world.loadFromLevel serializedLevel, false

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
    @trigger 'progress'
    @trigger 'loaded-all' if @progress() is 1
