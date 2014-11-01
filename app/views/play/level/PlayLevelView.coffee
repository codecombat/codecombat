RootView = require 'views/kinds/RootView'
template = require 'templates/play/level'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
utils = require 'lib/utils'
storage = require 'lib/storage'

# tools
Surface = require 'lib/surface/Surface'
God = require 'lib/God'
GoalManager = require 'lib/world/GoalManager'
ScriptManager = require 'lib/scripts/ScriptManager'
LevelBus = require 'lib/LevelBus'
LevelLoader = require 'lib/LevelLoader'
LevelSession = require 'models/LevelSession'
Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
Article = require 'models/Article'
Camera = require 'lib/surface/Camera'
AudioPlayer = require 'lib/AudioPlayer'
RealTimeModel = require 'models/RealTimeModel'
RealTimeCollection = require 'collections/RealTimeCollection'

# subviews
LevelLoadingView = require './LevelLoadingView'
TomeView = require './tome/TomeView'
ChatView = require './LevelChatView'
HUDView = require './LevelHUDView'
ControlBarView = require './ControlBarView'
LevelPlaybackView = require './LevelPlaybackView'
GoalsView = require './LevelGoalsView'
LevelFlagsView = require './LevelFlagsView'
GoldView = require './LevelGoldView'
VictoryModal = require './modal/VictoryModal'
HeroVictoryModal = require './modal/HeroVictoryModal'
InfiniteLoopModal = require './modal/InfiniteLoopModal'
GameMenuModal = require 'views/game-menu/GameMenuModal'
MultiplayerStatusView = require './MultiplayerStatusView'

PROFILE_ME = false

module.exports = class PlayLevelView extends RootView
  id: 'level-view'
  template: template
  cache: false
  shortcutsEnabled: true
  isEditorPreview: false

  subscriptions:
    'level:set-volume': (e) -> createjs.Sound.setVolume(if e.volume is 1 then 0.6 else e.volume)  # Quieter for now until individual sound FX controls work again.
    'level:show-victory': 'onShowVictory'
    'level:restart': 'onRestartLevel'
    'level:highlight-dom': 'onHighlightDOM'
    'level:end-highlight-dom': 'onEndHighlight'
    'level:focus-dom': 'onFocusDom'
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'god:world-load-progress-changed': 'onWorldLoadProgressChanged'
    'god:new-world-created': 'onNewWorld'
    'god:streaming-world-updated': 'onNewWorld'
    'god:infinite-loop': 'onInfiniteLoop'
    'level:reload-from-data': 'onLevelReloadFromData'
    'level:reload-thang-type': 'onLevelReloadThangType'
    'level:play-next-level': 'onPlayNextLevel'
    'level:edit-wizard-settings': 'showWizardSettingsModal'
    'level:session-will-save': 'onSessionWillSave'
    'level:started': 'onLevelStarted'
    'level:loading-view-unveiling': 'onLoadingViewUnveiling'
    'level:loading-view-unveiled': 'onLoadingViewUnveiled'
    'level:loaded': 'onLevelLoaded'
    'level:session-loaded': 'onSessionLoaded'
    'playback:real-time-playback-waiting': 'onRealTimePlaybackWaiting'
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'real-time-multiplayer:created-game': 'onRealTimeMultiplayerCreatedGame'
    'real-time-multiplayer:joined-game': 'onRealTimeMultiplayerJoinedGame'
    'real-time-multiplayer:left-game': 'onRealTimeMultiplayerLeftGame'
    'real-time-multiplayer:manual-cast': 'onRealTimeMultiplayerCast'
    'level:hero-config-changed': 'onHeroConfigChanged'

  events:
    'click #level-done-button': 'onDonePressed'
    'click #stop-real-time-playback-button': -> Backbone.Mediator.publish 'playback:stop-real-time-playback', {}
    'click #fullscreen-editor-background-screen': (e) -> Backbone.Mediator.publish 'tome:toggle-maximize', {}

  shortcuts:
    'ctrl+s': 'onCtrlS'

  # Initial Setup #############################################################

  constructor: (options, @levelID) ->
    console.profile?() if PROFILE_ME
    super options
    if not me.get('hourOfCode') and @getQueryVariable 'hour_of_code'
      @setUpHourOfCode()

    @isEditorPreview = @getQueryVariable 'dev'
    @sessionID = @getQueryVariable 'session'

    $(window).on 'resize', @onWindowResize
    @saveScreenshot = _.throttle @saveScreenshot, 30000

    if @isEditorPreview
      @supermodel.shouldSaveBackups = (model) ->  # Make sure to load possibly changed things from localStorage.
        model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']
      f = => @load() unless @levelLoader  # Wait to see if it's just given to us through setLevel.
      setTimeout f, 100
    else
      @load()
      application.tracker?.trackEvent 'Started Level Load', level: @levelID, label: @levelID, ['Google Analytics']

  setUpHourOfCode: ->
    me.set 'hourOfCode', true
    me.patch()
    $('body').append($('<img src="http://code.org/api/hour/begin_codecombat.png" style="visibility: hidden;">'))
    application.tracker?.trackEvent 'Hour of Code Begin', {}

  setLevel: (@level, givenSupermodel) ->
    @supermodel.models = givenSupermodel.models
    @supermodel.collections = givenSupermodel.collections
    @supermodel.shouldSaveBackups = givenSupermodel.shouldSaveBackups

    serializedLevel = @level.serialize @supermodel, @session, @otherSession
    @god?.setLevel serializedLevel
    if @world
      @world.loadFromLevel serializedLevel, false
    else
      @load()

  load: ->
    @loadStartTime = new Date()
    @god = new God debugWorker: true
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, sessionID: @sessionID, opponentSessionID: @getQueryVariable('opponent'), team: @getQueryVariable('team')
    @listenToOnce @levelLoader, 'world-necessities-loaded', @onWorldNecessitiesLoaded

  trackLevelLoadEnd: ->
    return if @isEditorPreview
    @loadEndTime = new Date()
    loadDuration = @loadEndTime - @loadStartTime
    console.debug "Level unveiled after #{(loadDuration / 1000).toFixed(2)}s"
    application.tracker?.trackEvent 'Finished Level Load', level: @levelID, label: @levelID, loadDuration: loadDuration, ['Google Analytics']
    application.tracker?.trackTiming loadDuration, 'Level Load Time', @levelID, @levelID
    application.tracker?.trackEvent 'Play Level', Action: 'Loaded', levelID: @levelID

  # CocoView overridden methods ###############################################

  getRenderData: ->
    c = super()
    c.world = @world
    if me.get('hourOfCode') and me.get('preferredLanguage', true) is 'en-US'
      # Show the Hour of Code footer explanation until it's been more than a day
      elapsed = (new Date() - new Date(me.get('dateCreated')))
      c.explainHourOfCode = elapsed < 86400 * 1000
    c

  afterRender: ->
    super()
    window.onPlayLevelViewLoaded? @  # still a hack
    @insertSubView @loadingView = new LevelLoadingView autoUnveil: @options.autoUnveil, level: @level  # May not have @level loaded yet
    @$el.find('#level-done-button').hide()
    $('body').addClass('is-playing')
    $('body').bind('touchmove', false) if @isIPadApp()

  afterInsert: ->
    super()

  # Partially Loaded Setup ####################################################

  onWorldNecessitiesLoaded: ->
    # Called when we have enough to build the world, but not everything is loaded
    @grabLevelLoaderData()
    team = @getQueryVariable('team') ? @world.teamForPlayer(0)
    @loadOpponentTeam(team)
    @setupGod()
    @setTeam team
    @initGoalManager()
    @insertSubviews()
    @initVolume()
    @listenTo(@session, 'change:multiplayer', @onMultiplayerChanged)

    @originalSessionState = $.extend(true, {}, @session.get('state'))
    @register()
    @controlBar.setBus(@bus)
    @initScriptManager()

  grabLevelLoaderData: ->
    @session = @levelLoader.session
    @world = @levelLoader.world
    @level = @levelLoader.level
    @$el.addClass 'hero' if @level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop']
    @$el.addClass 'flags' if @level.get('slug') is 'sky-span' or (@level.get('type', true) in ['hero-ladder', 'hero-coop']) # TODO: figure out when the player has flags.
    @otherSession = @levelLoader.opponentSession
    @worldLoadFakeResources = []  # first element (0) is 1%, last (100) is 100%
    for percent in [1 .. 100]
      @worldLoadFakeResources.push @supermodel.addSomethingResource "world_simulation_#{percent}%", 1

  onWorldLoadProgressChanged: (e) ->
    return unless @worldLoadFakeResources
    @lastWorldLoadPercent ?= 0
    worldLoadPercent = Math.floor 100 * e.progress
    for percent in [@lastWorldLoadPercent + 1 .. worldLoadPercent] by 1
      @worldLoadFakeResources[percent - 1].markLoaded()
    @lastWorldLoadPercent = worldLoadPercent
    @worldFakeLoadResources = null if worldLoadPercent is 100  # Done, don't need to watch progress any more.

  loadOpponentTeam: (myTeam) ->
    opponentSpells = []
    for spellTeam, spells of @session.get('teamSpells') ? @otherSession?.get('teamSpells') ? {}
      continue if spellTeam is myTeam or not myTeam
      opponentSpells = opponentSpells.concat spells
    if (not @session.get('teamSpells')) and @otherSession?.get('teamSpells')
      @session.set('teamSpells', @otherSession.get('teamSpells'))
    opponentCode = @otherSession?.get('transpiledCode') or {}
    myCode = @session.get('code') or {}
    for spell in opponentSpells
      [thang, spell] = spell.split '/'
      c = opponentCode[thang]?[spell]
      myCode[thang] ?= {}
      if c then myCode[thang][spell] = c else delete myCode[thang][spell]
    @session.set('code', myCode)
    if @session.get('multiplayer') and @otherSession?
      # For now, ladderGame will disallow multiplayer, because session code combining doesn't play nice yet.
      @session.set 'multiplayer', false

  setupGod: ->
    @god.setLevel @level.serialize @supermodel, @session, @otherSession
    @god.setLevelSessionIDs if @otherSession then [@session.id, @otherSession.id] else [@session.id]
    @god.setWorldClassMap @world.classMap

  setTeam: (team) ->
    team = team?.team unless _.isString team
    team ?= 'humans'
    me.team = team
    Backbone.Mediator.publish 'level:team-set', team: team  # Needed for scripts
    @team = team

  initGoalManager: ->
    @goalManager = new GoalManager(@world, @level.get('goals'), @team)
    @god.setGoalManager @goalManager

  insertSubviews: ->
    @insertSubView @tome = new TomeView levelID: @levelID, session: @session, otherSession: @otherSession, thangs: @world.thangs, supermodel: @supermodel, level: @level
    @insertSubView new LevelPlaybackView session: @session, levelID: @levelID, level: @level
    @insertSubView new GoalsView {}
    @insertSubView new LevelFlagsView world: @world if @levelID is 'sky-span' or @level.get('type', true) in ['hero-ladder', 'hero-coop'] # TODO: figure out when flags are available
    @insertSubView new GoldView {}
    @insertSubView new HUDView {level: @level}
    @insertSubView new ChatView levelID: @levelID, sessionID: @session.id, session: @session
    if @level.get('type') in ['ladder', 'hero-ladder']
      @insertSubView new MultiplayerStatusView levelID: @levelID, session: @session, level: @level
    worldName = utils.i18n @level.attributes, 'name'
    @controlBar = @insertSubView new ControlBarView {worldName: worldName, session: @session, level: @level, supermodel: @supermodel}
    #_.delay (=> Backbone.Mediator.publish('level:set-debug', debug: true)), 5000 if @isIPadApp()   # if me.displayName() is 'Nick'

  initVolume: ->
    volume = me.get('volume')
    volume = 1.0 unless volume?
    Backbone.Mediator.publish 'level:set-volume', volume: volume

  initScriptManager: ->
    @scriptManager = new ScriptManager({scripts: @world.scripts or [], view: @, session: @session})
    @scriptManager.loadFromSession()

  register: ->
    @bus = LevelBus.get(@levelID, @session.id)
    @bus.setSession(@session)
    @bus.setSpells @tome.spells
    @bus.connect() if @session.get('multiplayer')

  # Load Completed Setup ######################################################

  onLevelLoaded: (e) ->
    # Just the level has been loaded by the level loader
    @showWizardSettingsModal() if not me.get('name') and not @isIPadApp() and not (e.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop'])

  onSessionLoaded: (e) ->
    # Just the level and session have been loaded by the level loader
    if e.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop'] and not _.size e.session.get('heroConfig')?.inventory ? {}
      @openModalView new GameMenuModal level: e.level, session: e.session, supermodel: @supermodel
    @onRealTimeMultiplayerLevelLoaded e.session if e.level.get('type') in ['ladder', 'hero-ladder']

  onLoaded: ->
    _.defer => @onLevelLoaderLoaded()

  onLevelLoaderLoaded: ->
    # Everything is now loaded
    return unless @levelLoader.progress() is 1  # double check, since closing the guide may trigger this early

    # Save latest level played.
    if not (@levelLoader.level.get('type') in ['ladder', 'ladder-tutorial'])
      me.set('lastLevel', @levelID)
      me.save()
    @saveRecentMatch() if @otherSession
    @levelLoader.destroy()
    @levelLoader = null
    @initSurface()

  saveRecentMatch: ->
    allRecentlyPlayedMatches = storage.load('recently-played-matches') ? {}
    recentlyPlayedMatches = allRecentlyPlayedMatches[@levelID] ? []
    allRecentlyPlayedMatches[@levelID] = recentlyPlayedMatches
    recentlyPlayedMatches.unshift yourTeam: me.team, otherSessionID: @otherSession.id, opponentName: @otherSession.get('creatorName') unless _.find recentlyPlayedMatches, otherSessionID: @otherSession.id
    recentlyPlayedMatches.splice(8)
    storage.save 'recently-played-matches', allRecentlyPlayedMatches

  initSurface: ->
    webGLSurface = $('canvas#webgl-surface', @$el)
    normalSurface = $('canvas#normal-surface', @$el)
    @surface = new Surface(@world, normalSurface, webGLSurface, thangTypes: @supermodel.getModels(ThangType), playJingle: not @isEditorPreview, wizards: not (@level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop']))
    worldBounds = @world.getBounds()
    bounds = [{x: worldBounds.left, y: worldBounds.top}, {x: worldBounds.right, y: worldBounds.bottom}]
    @surface.camera.setBounds(bounds)
    @surface.camera.zoomTo({x: 0, y: 0}, 0.1, 0)

  # Once Surface is Loaded ####################################################

  onLevelStarted: ->
    return unless @surface?
    @loadingView.showReady()
    @trackLevelLoadEnd()
    if window.currentModal and not window.currentModal.destroyed and window.currentModal.constructor isnt VictoryModal
      return Backbone.Mediator.subscribeOnce 'modal:closed', @onLevelStarted, @
    @surface.showLevel()
    if @otherSession and not (@level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop'])
      # TODO: colorize name and cloud by team, colorize wizard by user's color config
      @surface.createOpponentWizard id: @otherSession.get('creator'), name: @otherSession.get('creatorName'), team: @otherSession.get('team'), levelSlug: @level.get('slug'), codeLanguage: @otherSession.get('submittedCodeLanguage')
    if @isEditorPreview
      @loadingView.startUnveiling()
      @loadingView.unveil()

  onLoadingViewUnveiling: (e) ->
    @restoreSessionState()

  onLoadingViewUnveiled: (e) ->
    @loadingView.$el.remove()
    @removeSubView @loadingView
    @loadingView = null
    @playAmbientSound()
    application.tracker?.trackEvent 'Play Level', Action: 'Start Level', levelID: @levelID

  playAmbientSound: ->
    return if @ambientSound
    return unless file = {Dungeon: 'ambient-dungeon', Grass: 'ambient-grass'}[@level.get('terrain')]
    src = "/file/interface/#{file}#{AudioPlayer.ext}"
    unless AudioPlayer.getStatus(src)?.loaded
      AudioPlayer.preloadSound src
      Backbone.Mediator.subscribeOnce 'audio-player:loaded', @playAmbientSound, @
      return
    @ambientSound = createjs.Sound.play src, loop: -1, volume: 0.1
    createjs.Tween.get(@ambientSound).to({volume: 1.0}, 10000)

  restoreSessionState: ->
    return if @alreadyLoadedState
    @alreadyLoadedState = true
    state = @originalSessionState
    if @level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop']
      Backbone.Mediator.publish 'level:suppress-selection-sounds', suppress: true
      Backbone.Mediator.publish 'tome:select-primary-sprite', {}
      Backbone.Mediator.publish 'level:suppress-selection-sounds', suppress: false
      @surface.focusOnHero()
      Backbone.Mediator.publish 'level:set-time', time: 0
      Backbone.Mediator.publish 'level:set-playing', playing: true
    else
      if state.frame and @level.get('type', true) isnt 'ladder'  # https://github.com/codecombat/codecombat/issues/714
        Backbone.Mediator.publish 'level:set-time', time: 0, frameOffset: state.frame
      if state.selected
        # TODO: Should also restore selected spell here by saving spellName
        Backbone.Mediator.publish 'level:select-sprite', thangID: state.selected, spellName: null
      if state.playing?
        Backbone.Mediator.publish 'level:set-playing', playing: state.playing

  # callbacks

  onCtrlS: (e) ->
    e.preventDefault()

  onLevelReloadFromData: (e) ->
    isReload = Boolean @world
    @setLevel e.level, e.supermodel
    if isReload
      @scriptManager.setScripts(e.level.get('scripts'))
      Backbone.Mediator.publish 'tome:cast-spell', {}  # a bit hacky

  onLevelReloadThangType: (e) ->
    tt = e.thangType
    for url, model of @supermodel.models
      if model.id is tt.id
        for key, val of tt.attributes
          model.attributes[key] = val
        break
    Backbone.Mediator.publish 'tome:cast-spell', {}

  onHeroConfigChanged: (e) ->
    # Doesn't work because the new inventory ThangTypes may not be loaded.
    #@setLevel @level, @supermodel
    #Backbone.Mediator.publish 'tome:cast-spell', {}
    # We'll just make a new PlayLevelView instead
    console.log 'Hero config changed; reload the level.'
    Backbone.Mediator.publish 'router:navigate', {
      route: window.location.pathname,
      viewClass: PlayLevelView,
      viewArgs: [{supermodel: @supermodel, autoUnveil: true}, @levelID]
    }

  onWindowResize: (e) => @endHighlight()

  onDisableControls: (e) ->
    return if e.controls and not ('level' in e.controls)
    @shortcutsEnabled = false
    @wasFocusedOn = document.activeElement
    $('body').focus()

  onEnableControls: (e) ->
    return if e.controls? and not ('level' in e.controls)
    @shortcutsEnabled = true
    $(@wasFocusedOn).focus() if @wasFocusedOn
    @wasFocusedOn = null

  onDonePressed: -> @showVictory()

  onShowVictory: (e) ->
    $('#level-done-button').show() unless @level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop']
    @showVictory() if e.showModal
    setTimeout(@preloadNextLevel, 3000)
    return if @victorySeen
    @victorySeen = true
    victoryTime = (new Date()) - @loadEndTime
    if victoryTime > 10 * 1000   # Don't track it if we're reloading an already-beaten level
      application.tracker?.trackEvent 'Saw Victory', level: @level.get('name'), label: @level.get('name')
      application.tracker?.trackTiming victoryTime, 'Level Victory Time', @levelID, @levelID, 100

  showVictory: ->
    options = {level: @level, supermodel: @supermodel, session: @session}
    ModalClass = if @level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop'] then HeroVictoryModal else VictoryModal
    victoryModal = new ModalClass(options)
    @openModalView(victoryModal)
    if me.get('anonymous')
      window.nextLevelURL = @getNextLevelURL()  # Signup will go here on completion instead of reloading.

  onRestartLevel: ->
    @tome.reloadAllCode()
    Backbone.Mediator.publish 'level:restarted', {}
    $('#level-done-button', @$el).hide()
    application.tracker?.trackEvent 'Confirmed Restart', level: @level.get('name'), label: @level.get('name')

  onInfiniteLoop: (e) ->
    return unless e.firstWorld
    @openModalView new InfiniteLoopModal()
    application.tracker?.trackEvent 'Saw Initial Infinite Loop', level: @level.get('name'), label: @level.get('name')

  onPlayNextLevel: ->
    nextLevelID = @getNextLevelID()
    nextLevelURL = @getNextLevelURL()
    Backbone.Mediator.publish 'router:navigate', {
      route: nextLevelURL,
      viewClass: PlayLevelView,
      viewArgs: [{supermodel: @supermodel}, nextLevelID]}

  getNextLevel: ->
    return null unless nextLevelOriginal = @level.get('nextLevel')?.original
    levels = @supermodel.getModels(Level)
    return l for l in levels when l.get('original') is nextLevelOriginal

  getNextLevelID: ->
    return null unless nextLevel = @getNextLevel()
    nextLevelID = nextLevel.get('slug') or nextLevel.id

  getNextLevelURL: ->
    return null unless @getNextLevelID()
    "/play/level/#{@getNextLevelID()}"

  onHighlightDOM: (e) -> @highlightElement e.selector, delay: e.delay, sides: e.sides, offset: e.offset, rotation: e.rotation

  onEndHighlight: -> @endHighlight()

  onFocusDom: (e) -> $(e.selector).focus()

  onMultiplayerChanged: (e) ->
    if @session.get('multiplayer')
      @bus.connect()
    else
      @bus.removeFirebaseData =>
        @bus.disconnect()

  preloadNextLevel: =>
    # TODO: Loading models in the middle of gameplay causes stuttering. Most of the improvement in loading time is simply from passing the supermodel from this level to the next, but if we can find a way to populate the level early without it being noticeable, that would be even better.
#    return if @destroyed
#    return if @preloaded
#    nextLevel = @getNextLevel()
#    @supermodel.populateModel nextLevel
#    @preloaded = true

  onSessionWillSave: (e) ->
    # Something interesting has happened, so (at a lower frequency), we'll save a screenshot.
    #@saveScreenshot e.session

  # Throttled
  saveScreenshot: (session) =>
    return unless screenshot = @surface?.screenshot()
    session.save {screenshot: screenshot}, {patch: true, type: 'PUT'}

  # Dynamic sound loading

  onNewWorld: (e) ->
    return if @headless
    scripts = @world.scripts  # Since these worlds don't have scripts, preserve them.
    @world = e.world
    @world.scripts = scripts
    thangTypes = @supermodel.getModels(ThangType)
    startFrame = @lastWorldFramesLoaded ? 0
    finishedLoading = @world.frames.length is @world.totalFrames
    if finishedLoading
      @lastWorldFramesLoaded = 0
      if @waitingForSubmissionComplete
        _.defer @onSubmissionComplete  # Give it a frame to make sure we have the latest goals
        @waitingForSubmissionComplete = false
    else
      @lastWorldFramesLoaded = @world.frames.length
    for [spriteName, message] in @world.thangDialogueSounds startFrame
      continue unless thangType = _.find thangTypes, (m) -> m.get('name') is spriteName
      continue unless sound = AudioPlayer.soundForDialogue message, thangType.get('soundTriggers')
      AudioPlayer.preloadSoundReference sound

  # Real-time playback
  onRealTimePlaybackWaiting: (e) ->
    @$el.addClass('real-time').focus()
    @onWindowResize()

  onRealTimePlaybackStarted: (e) ->
    @$el.addClass('real-time').focus()
    @onWindowResize()

  onRealTimePlaybackEnded: (e) ->
    return unless @$el.hasClass 'real-time'
    @$el.removeClass 'real-time'
    @onWindowResize()
    if @world.frames.length is @world.totalFrames
      _.delay @onSubmissionComplete, 750  # Wait for transition to end.
    else
      @waitingForSubmissionComplete = true
    @onRealTimeMultiplayerPlaybackEnded()

  onSubmissionComplete: =>
    return if @destroyed
    Backbone.Mediator.publish 'level:show-victory', showModal: true if @goalManager.checkOverallStatus() is 'success'

  destroy: ->
    @levelLoader?.destroy()
    @surface?.destroy()
    @god?.destroy()
    @goalManager?.destroy()
    @scriptManager?.destroy()
    if ambientSound = @ambientSound
      # Doesn't seem to work; stops immediately.
      createjs.Tween.get(ambientSound).to({volume: 0.0}, 1500).call -> ambientSound.stop()
    $(window).off 'resize', @onWindowResize
    delete window.world # not sure where this is set, but this is one way to clean it up
    @bus?.destroy()
    #@instance.save() unless @instance.loading
    delete window.nextLevelURL
    console.profileEnd?() if PROFILE_ME
    @onRealTimeMultiplayerLevelUnloaded()
    super()

  # Real-time Multiplayer ######################################################
  #
  # This view acts as a hub for the real-time multiplayer session for the current level.
  #
  # It performs these actions:
  #   Player heartbeat
  #   Publishes player status
  #   Updates real-time multiplayer session state
  #   Updates real-time multiplayer player state
  #   Cleans up old sessions (sets state to 'finished')
  #   Real-time multiplayer cast handshake
  #
  # It monitors these:
  #   Real-time multiplayer sessions
  #   Current real-time multiplayer session
  #   Internal multiplayer create/joined/left events
  #
  # Real-time state variables:
  #   @realTimePlayerStatus - User's real-time multiplayer state for this level
  #   @realTimePlayerGameStatus - User's state for current real-time multiplayer game session
  #   @realTimeSession - Current real-time multiplayer game session
  #   @realTimeOpponent - Current real-time multiplayer opponent
  #   @realTimePlayers - Real-time players for current real-time multiplayer game session
  #   @realTimeSessionCollection - Collection of all real-time multiplayer sessions
  #
  # TODO: Move this code to it's own file, or possibly the LevelBus
  # TODO: save settings somewhere reasonable

  onRealTimeMultiplayerLevelLoaded: (session) ->
    return if me.get('anonymous')
    players = new RealTimeCollection('multiplayer_players/' + @levelID)
    players.create
      id: me.id
      name: session.get('creatorName')
      state: 'playing'
      created: new Date().toISOString()
      heartbeat: new Date().toISOString()
    @realTimePlayerStatus = new RealTimeModel('multiplayer_players/' + @levelID + '/' + me.id)
    @timerMultiplayerHeartbeatID = setInterval @onRealTimeMultiplayerHeartbeat, 60 * 1000
    @cleanupRealTimeSessions()

  cleanupRealTimeSessions: ->
    @realTimeSessionCollection = new RealTimeCollection 'multiplayer_level_sessions'
    @realTimeSessionCollection.on 'add', @cleanupRealTimeSession
    @realTimeSessionCollection.each @cleanupRealTimeSession

  cleanupRealTimeSession: (session) =>
    if session.get('state') isnt 'finished'
      players = new RealTimeCollection 'multiplayer_level_sessions/' + session.id + '/players'
      players.each (player) =>
        if player.id is me.id
          p = new RealTimeModel 'multiplayer_level_sessions/' + session.id + '/players/' + me.id
          console.info 'Cleaning up previous real-time multiplayer session', session.id
          p.set 'state', 'left'
          session.set 'state', 'finished'

  onRealTimeMultiplayerLevelUnloaded: ->
    clearInterval @timerMultiplayerHeartbeatID if @timerMultiplayerHeartbeatID?
    if @realTimeSessionCollection?
      @realTimeSessionCollection.off 'add', @cleanupRealTimeSession
      @realTimeSessionCollection = null

  onRealTimeMultiplayerHeartbeat: =>
    @realTimePlayerStatus.set 'heartbeat', new Date().toISOString() if @realTimePlayerStatus

  onRealTimeMultiplayerCreatedGame: (e) ->
    # Watch external multiplayer session
    @realTimeSession = new RealTimeModel 'multiplayer_level_sessions/' + e.session.id
    @realTimeSession.on 'change', @onRealTimeSessionChanged
    @realTimePlayers = new RealTimeCollection 'multiplayer_level_sessions/' + e.session.id + '/players'
    @realTimePlayers.on 'add', @onRealTimePlayerAdded
    @realTimePlayerGameStatus = new RealTimeModel 'multiplayer_level_sessions/' + e.session.id + '/players/' + me.id
    @realTimePlayerGameStatus.set 'state', 'coding'
    @realTimePlayerStatus.set 'state', 'available'
    Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Waiting for opponent..'

  onRealTimeSessionChanged: (e) =>
    # console.log 'PlayLevelView onRealTimeSessionChanged', e
    if e.get('state') is 'finished'
      @realTimeGameEnded()
      Backbone.Mediator.publish 'real-time-multiplayer:left-game', {}

  onRealTimePlayerAdded: (e) =>
    # console.log 'PlayLevelView onRealTimePlayerAdded', e
    # Assume game is full, game on
    if @realTimeSession.get('state') is 'creating'
      @realTimeSession.set 'state', 'coding'
      @realTimePlayerStatus.set 'state', 'unavailable'
      @realTimeOpponent = new RealTimeModel('multiplayer_level_sessions/' + @realTimeSession.id + '/players/' + e.id)
      @realTimeOpponent.on 'change', @onRealTimeOpponentChanged
      Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Playing against ' + e.get('name')
    else
      console.error 'PlayLevelView onRealTimePlayerAdded session in unexpected state', @realTimeSession.get('state')

  onRealTimeOpponentChanged: (e) =>
    # console.log 'PlayLevelView onRealTimeOpponentChanged', e
    switch @realTimeOpponent.get('state')
      when 'left'
        console.info 'Real-time multiplayer opponent left the game'
        opponentID = @realTimeOpponent.id
        @realTimeGameEnded()
        Backbone.Mediator.publish 'real-time-multiplayer:left-game', id: opponentID
      when 'submitted'
        # TODO: What should this message say?
        Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: @realTimeOpponent.get('name') + ' waiting for your code..'

  onRealTimeMultiplayerJoinedGame: (e) ->
    # console.log 'PlayLevelView onRealTimeMultiplayerJoinedGame', e
    if e.id is me.id
      @realTimeSession = new RealTimeModel 'multiplayer_level_sessions/' + e.session.id
      @realTimeSession.set 'state', 'coding'
      @realTimeSession.on 'change', @onRealTimeSessionChanged
      @realTimePlayers = new RealTimeCollection 'multiplayer_level_sessions/' + e.session.id + '/players'
      @realTimePlayers.on 'add', @onRealTimePlayerAdded
      @realTimePlayerGameStatus = new RealTimeModel 'multiplayer_level_sessions/' + e.session.id + '/players/' + me.id
      @realTimePlayerGameStatus.set 'state', 'coding'
      @realTimePlayerStatus.set 'state', 'unavailable'
      for id, player of e.session.get('players')
        if id isnt me.id
          @realTimeOpponent = new RealTimeModel 'multiplayer_level_sessions/' + e.session.id + '/players/' + id
          Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Playing against ' + player.name

  onRealTimeMultiplayerLeftGame: (e) ->
    # console.log 'PlayLevelView onRealTimeMultiplayerLeftGame', e
    if e.id? and e.id is me.id
      @realTimePlayerGameStatus.set 'state', 'left'
      @realTimeGameEnded()

  realTimeGameEnded: ->
    if @realTimeOpponent?
      @realTimeOpponent.off 'change', @onRealTimeOpponentChanged
      @realTimeOpponent = null
    if @realTimePlayers?
      @realTimePlayers.off 'add', @onRealTimePlayerAdded
      @realTimePlayers = null
    if @realTimeSession?
      @realTimeSession.off 'change', @onRealTimeSessionChanged
      @realTimeSession.set 'state', 'finished'
      @realTimeSession = null
    if @realTimePlayerGameStatus?
      @realTimePlayerGameStatus = null
    if @realTimePlayerStatus?
      @realTimePlayerStatus.set 'state', 'playing'
    Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: ''

  onRealTimeMultiplayerCast: (e) ->
    unless @realTimeSession
      console.error 'onRealTimeMultiplayerCast without a multiplayerSession'
      return
    players = new RealTimeCollection('multiplayer_level_sessions/' + @realTimeSession.id + '/players')
    myPlayer = opponentPlayer = null
    players.each (player) ->
      if player.id is me.id
        myPlayer = player
      else
        opponentPlayer = player
    if myPlayer
      console.info 'Submitting my code'
      myPlayer.set 'code', @session.get('code')
      myPlayer.set 'codeLanguage', @session.get('codeLanguage')
      myPlayer.set 'state', 'submitted'
      myPlayer.set 'team', me.team
    else
      console.error 'Did not find my player in onRealTimeMultiplayerCast'
    if opponentPlayer
      # TODO: Shouldn't need nested opponentPlayer change listeners here
      state = opponentPlayer.get('state')
      console.info 'Other player is', state
      if state in ['submitted', 'ready']
        @realTimeOpponentSubmittedCode opponentPlayer, myPlayer
      else
        # Wait for opponent to submit their code
        Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Waiting for code from ' + @realTimeOpponent.get('name')
        opponentPlayer.on 'change', (e) =>
          state = opponentPlayer.get('state')
          if state in ['submitted', 'ready']
            @realTimeOpponentSubmittedCode opponentPlayer, myPlayer

  onRealTimeMultiplayerPlaybackEnded: ->
    if @realTimeSession?
      @realTimeSession.set 'state', 'coding'
      @realTimePlayers.each (player) -> player.set 'state', 'coding' if player.id is me.id
    if @realTimeOpponent?
      Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Playing against ' + @realTimeOpponent.get('name')

  realTimeOpponentSubmittedCode: (opponentPlayer, myPlayer) =>
    # Save opponent's code
    Backbone.Mediator.publish 'real-time-multiplayer:new-opponent-code', {codeLanguage: opponentPlayer.get('codeLanguage'), code: opponentPlayer.get('code'), team: opponentPlayer.get('team')}
    # I'm ready to rumble
    myPlayer.set 'state', 'ready'
    if opponentPlayer.get('state') is 'ready'
      console.info 'All real-time multiplayer players are ready!'
      @realTimeSession.set 'state', 'running'
      Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Battling ' + @realTimeOpponent.get('name')
    else
      # Wait for opponent to be ready
      opponentPlayer.on 'change', (e) =>
        if opponentPlayer.get('state') is 'ready'
          opponentPlayer.off 'change'
          console.info 'All real-time multiplayer players are ready!'
          @realTimeSession.set 'state', 'running'
          Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Battling ' + @realTimeOpponent.get('name')
