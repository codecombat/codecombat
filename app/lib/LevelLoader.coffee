Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
LevelSystem = require 'models/LevelSystem'
Article = require 'models/Article'
LevelSession = require 'models/LevelSession'
ThangType = require 'models/ThangType'

CocoClass = require 'lib/CocoClass'
AudioPlayer = require 'lib/AudioPlayer'
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

  constructor: (options) ->
    super()
    @supermodel = options.supermodel
    @levelID = options.levelID
    @sessionID = options.sessionID
    @opponentSessionID = options.opponentSessionID
    @team = options.team
    @headless = options.headless
    @spectateMode = options.spectateMode ? false
    @editorMode = options.editorMode # TODO: remove when the surface can load ThangTypes itself

    @loadSession()
    @loadLevel()
    @loadAudio()
    @playJingle()
    if @supermodel.finished()
      @onSupermodelLoaded()
    else
      @listenToOnce @supermodel, 'loaded-all', @onSupermodelLoaded

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

    @session = new LevelSession().setURL url
    @supermodel.loadModel(@session, 'level_session', {cache:false})
    @session.once 'sync', -> @url = -> '/db/level.session/' + @id

    if @opponentSessionID
      @opponentSession = new LevelSession().setURL "/db/level_session/#{@opponentSessionID}"
      @supermodel.loadModel(@opponentSession, 'opponent_session')

  # Supermodel (Level) Loading

  loadLevel: ->
    @level = @supermodel.getModel(Level, @levelID) or new Level _id: @levelID
    if @level.loaded
      @populateLevel()
    else
      @level = @supermodel.loadModel(@level, 'level').model
      @listenToOnce @level, 'sync', @onLevelLoaded

  onLevelLoaded: ->
    @populateLevel()

  populateLevel: ->
    thangIDs = []
    componentVersions = []
    systemVersions = []
    articleVersions = []

    for thang in @level.get('thangs') or []
      thangIDs.push thang.thangType
      for comp in thang.components or []
        componentVersions.push _.pick(comp, ['original', 'majorVersion'])

    for system in @level.get('systems') or []
      systemVersions.push _.pick(system, ['original', 'majorVersion'])
      if indieSprites = system?.config?.indieSprites
        for indieSprite in indieSprites
          thangIDs.push indieSprite.thangType

    unless @headless
      for article in @level.get('documentation')?.generalArticles or []
        articleVersions.push _.pick(article, ['original', 'majorVersion'])

    objUniq = (array) -> _.uniq array, false, (arg) -> JSON.stringify(arg)

    for thangID in _.uniq thangIDs
      url = "/db/thang.type/#{thangID}/version"
      url += "?project=true" if @headless and not @editorMode
      res = @maybeLoadURL url, ThangType, 'thang'
      @listenToOnce res.model, 'sync', @buildSpriteSheetsForThangType if res
    for obj in objUniq componentVersions
      url = "/db/level.component/#{obj.original}/version/#{obj.majorVersion}"
      @maybeLoadURL url, LevelComponent, 'component'
    for obj in objUniq systemVersions
      url = "/db/level.system/#{obj.original}/version/#{obj.majorVersion}"
      @maybeLoadURL url, LevelSystem, 'system'
    for obj in objUniq articleVersions
      url = "/db/article/#{obj.original}/version/#{obj.majorVersion}"
      @maybeLoadURL url, Article, 'article'
    if obj = @level.get 'nextLevel'
      url = "/db/level/#{obj.original}/version/#{obj.majorVersion}"
      @maybeLoadURL url, Level, 'level'

    unless @headless and not @editorMode
      wizard = ThangType.loadUniversalWizard()
      @supermodel.loadModel wizard, 'thang'

  maybeLoadURL: (url, Model, resourceName) ->
    return if @supermodel.getModel(url)
    model = new Model().setURL url
    @supermodel.loadModel(model, resourceName)

  onSupermodelLoaded: ->
    @loadLevelSounds()
    @denormalizeSession()
    app.tracker.updatePlayState(@level, @session) unless @headless
    @initWorld()

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

  buildSpriteSheetsForThangType: (thangType) ->
    @grabThangTypeTeams() unless @thangTypeTeams
    for team in @thangTypeTeams[thangType.get('original')] ? [null]
      spriteOptions = {resolutionFactor: 4, async: false}
      if thangType.get('kind') is 'Floor'
        spriteOptions.resolutionFactor = 2
      if team and color = @teamConfigs[team]?.color
        spriteOptions.colorConfig = team: color
      @buildSpriteSheet thangType, spriteOptions

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

  buildSpriteSheet: (thangType, options) ->
    if thangType.get('name') is 'Wizard'
      options.colorConfig = me.get('wizard')?.colorConfig or {}
    thangType.buildSpriteSheet options

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

  progress: -> @supermodel.progress
