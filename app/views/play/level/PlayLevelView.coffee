RootView = require 'views/core/RootView'
template = require 'templates/play/level'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'
utils = require 'core/utils'
storage = require 'core/storage'
{createAetherOptions} = require 'lib/aether_utils'

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
Simulator = require 'lib/simulator/Simulator'

# subviews
LevelLoadingView = require './LevelLoadingView'
ProblemAlertView = require './tome/ProblemAlertView'
TomeView = require './tome/TomeView'
ChatView = require './LevelChatView'
HUDView = require './LevelHUDView'
LevelDialogueView = require './LevelDialogueView'
ControlBarView = require './ControlBarView'
LevelPlaybackView = require './LevelPlaybackView'
GoalsView = require './LevelGoalsView'
LevelFlagsView = require './LevelFlagsView'
GoldView = require './LevelGoldView'
DuelStatsView = require './DuelStatsView'
VictoryModal = require './modal/VictoryModal'
HeroVictoryModal = require './modal/HeroVictoryModal'
CourseVictoryModal = require './modal/CourseVictoryModal'
InfiniteLoopModal = require './modal/InfiniteLoopModal'
LevelSetupManager = require 'lib/LevelSetupManager'
ContactModal = require 'views/core/ContactModal'

PROFILE_ME = false

module.exports = class PlayLevelView extends RootView
  id: 'level-view'
  template: template
  cache: false
  shortcutsEnabled: true
  isEditorPreview: false

  subscriptions:
    'level:set-volume': 'onSetVolume'
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
    'level:session-will-save': 'onSessionWillSave'
    'level:started': 'onLevelStarted'
    'level:loading-view-unveiling': 'onLoadingViewUnveiling'
    'level:loading-view-unveiled': 'onLoadingViewUnveiled'
    'level:session-loaded': 'onSessionLoaded'
    'playback:real-time-playback-waiting': 'onRealTimePlaybackWaiting'
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'real-time-multiplayer:created-game': 'onRealTimeMultiplayerCreatedGame'
    'real-time-multiplayer:joined-game': 'onRealTimeMultiplayerJoinedGame'
    'real-time-multiplayer:left-game': 'onRealTimeMultiplayerLeftGame'
    'real-time-multiplayer:manual-cast': 'onRealTimeMultiplayerCast'
    'ipad:memory-warning': 'onIPadMemoryWarning'
    'store:item-purchased': 'onItemPurchased'

  events:
    'click #level-done-button': 'onDonePressed'
    'click #stop-real-time-playback-button': -> Backbone.Mediator.publish 'playback:stop-real-time-playback', {}
    'click #fullscreen-editor-background-screen': (e) -> Backbone.Mediator.publish 'tome:toggle-maximize', {}
    'click .contact-link': 'onContactClicked'

  shortcuts:
    'ctrl+s': 'onCtrlS'
    'esc': 'onEscapePressed'

  # Initial Setup #############################################################

  constructor: (options, @levelID) ->
    console.profile?() if PROFILE_ME
    super options

    @courseID = options.courseID or @getQueryVariable 'course'
    @courseInstanceID = options.courseInstanceID or @getQueryVariable 'course-instance'

    @isEditorPreview = @getQueryVariable 'dev'
    @sessionID = @getQueryVariable 'session'
    @observing = @getQueryVariable 'observing'

    @opponentSessionID = @getQueryVariable('opponent')
    @opponentSessionID ?= @options.opponent

    $(window).on 'resize', @onWindowResize
    @saveScreenshot = _.throttle @saveScreenshot, 30000

    application.tracker?.enableInspectletJS(@levelID)

    if @isEditorPreview
      @supermodel.shouldSaveBackups = (model) ->  # Make sure to load possibly changed things from localStorage.
        model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']
      f = => @load() unless @levelLoader  # Wait to see if it's just given to us through setLevel.
      setTimeout f, 100
    else
      @load()
      application.tracker?.trackEvent 'Started Level Load', category: 'Play Level', level: @levelID, label: @levelID unless @observing

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
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, sessionID: @sessionID, opponentSessionID: @opponentSessionID, team: @getQueryVariable('team'), observing: @observing, courseID: @courseID
    @listenToOnce @levelLoader, 'world-necessities-loaded', @onWorldNecessitiesLoaded

  trackLevelLoadEnd: ->
    return if @isEditorPreview
    @loadEndTime = new Date()
    @loadDuration = @loadEndTime - @loadStartTime
    console.debug "Level unveiled after #{(@loadDuration / 1000).toFixed(2)}s"
    unless @observing
      application.tracker?.trackEvent 'Finished Level Load', category: 'Play Level', label: @levelID, level: @levelID, loadDuration: @loadDuration
      application.tracker?.trackTiming @loadDuration, 'Level Load Time', @levelID, @levelID

  # CocoView overridden methods ###############################################

  getRenderData: ->
    c = super()
    c.world = @world
    c

  afterRender: ->
    super()
    window.onPlayLevelViewLoaded? @  # still a hack
    @insertSubView @loadingView = new LevelLoadingView autoUnveil: @options.autoUnveil or @observing, level: @levelLoader?.level ? @level, session: @levelLoader?.session ? @session  # May not have @level loaded yet
    @$el.find('#level-done-button').hide()
    $('body').addClass('is-playing')
    $('body').bind('touchmove', false) if @isIPadApp()

  afterInsert: ->
    super()

  # Partially Loaded Setup ####################################################

  onWorldNecessitiesLoaded: ->
    # Called when we have enough to build the world, but not everything is loaded
    @grabLevelLoaderData()
    team = @getQueryVariable('team') ?  @session.get('team') ? @world.teamForPlayer(0)
    @loadOpponentTeam(team)
    @setupGod()
    @setTeam team
    @initGoalManager()
    @insertSubviews()
    @initVolume()
    @listenTo(@session, 'change:multiplayer', @onMultiplayerChanged)

    @register()
    @controlBar.setBus(@bus)
    @initScriptManager()

  grabLevelLoaderData: ->
    @session = @levelLoader.session
    @world = @levelLoader.world
    @level = @levelLoader.level
    @$el.addClass 'hero' if @level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder']
    @$el.addClass 'flags' if _.any(@world.thangs, (t) -> (t.programmableProperties and 'findFlags' in t.programmableProperties) or t.inventory?.flag) or @level.get('slug') is 'sky-span'
    # TODO: Update terminology to always be opponentSession or otherSession
    # TODO: E.g. if it's always opponent right now, then variable names should be opponentSession until we have coop play
    @otherSession = @levelLoader.opponentSession
    @worldLoadFakeResources = []  # first element (0) is 1%, last (100) is 100%
    for percent in [1 .. 100]
      @worldLoadFakeResources.push @supermodel.addSomethingResource "world_simulation_#{percent}%", 1

  onWorldLoadProgressChanged: (e) ->
    return unless e.god is @god
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
    @session.set 'team', team
    Backbone.Mediator.publish 'level:team-set', team: team  # Needed for scripts
    @team = team

  initGoalManager: ->
    @goalManager = new GoalManager(@world, @level.get('goals'), @team)
    @god.setGoalManager @goalManager

  insertSubviews: ->
    @insertSubView @tome = new TomeView levelID: @levelID, session: @session, otherSession: @otherSession, thangs: @world.thangs, supermodel: @supermodel, level: @level, observing: @observing, courseID: @courseID, courseInstanceID: @courseInstanceID, god: @god
    @insertSubView new LevelPlaybackView session: @session, level: @level
    @insertSubView new GoalsView {}
    @insertSubView new LevelFlagsView levelID: @levelID, world: @world if @$el.hasClass 'flags'
    @insertSubView new GoldView {} unless @level.get('slug') in ['wakka-maul']
    @insertSubView new HUDView {level: @level}
    @insertSubView new LevelDialogueView {level: @level, sessionID: @session.id}
    @insertSubView new ChatView levelID: @levelID, sessionID: @session.id, session: @session
    @insertSubView new ProblemAlertView session: @session, level: @level, supermodel: @supermodel
    @insertSubView new DuelStatsView level: @level, session: @session, otherSession: @otherSession, supermodel: @supermodel, thangs: @world.thangs if @level.get('type') in ['hero-ladder', 'course-ladder']
    @insertSubView @controlBar = new ControlBarView {worldName: utils.i18n(@level.attributes, 'name'), session: @session, level: @level, supermodel: @supermodel, courseID: @courseID, courseInstanceID: @courseInstanceID}
    #_.delay (=> Backbone.Mediator.publish('level:set-debug', debug: true)), 5000 if @isIPadApp()   # if me.displayName() is 'Nick'

  initVolume: ->
    volume = me.get('volume')
    volume = 1.0 unless volume?
    Backbone.Mediator.publish 'level:set-volume', volume: volume

  initScriptManager: ->
    @scriptManager = new ScriptManager({scripts: @world.scripts or [], view: @, session: @session, levelID: @level.get('slug')})
    @scriptManager.loadFromSession()

  register: ->
    @bus = LevelBus.get(@levelID, @session.id)
    @bus.setSession(@session)
    @bus.setSpells @tome.spells
    if @session.get('multiplayer') and not me.isAdmin()
      @session.set 'multiplayer', false  # Temp: multiplayer has bugged out some sessions, so ignoring it.
    @bus.connect() if @session.get('multiplayer')

  # Load Completed Setup ######################################################

  onSessionLoaded: (e) ->
    return if @session
    Backbone.Mediator.publish "ipad:language-chosen", language: e.session.get('codeLanguage') ? "python"
    # Just the level and session have been loaded by the level loader
    if e.level.get('slug') is 'zero-sum'
      sorcerer = '52fd1524c7e6cf99160e7bc9'
      if e.session.get('creator') is '532dbc73a622924444b68ed9'  # Wizard Dude gets his own avatar
        sorcerer = '53e126a4e06b897606d38bef'
      e.session.set 'heroConfig', {"thangType":sorcerer,"inventory":{"misc-0":"53e2396a53457600003e3f0f","programming-book":"546e266e9df4a17d0d449be5","minion":"54eb5dbc49fa2d5c905ddf56","feet":"53e214f153457600003e3eab","right-hand":"54eab7f52b7506e891ca7202","left-hand":"5463758f3839c6e02811d30f","wrists":"54693797a2b1f53ce79443e9","gloves":"5469425ca2b1f53ce7944421","torso":"546d4a549df4a17d0d449a97","neck":"54693274a2b1f53ce79443c9","eyes":"546941fda2b1f53ce794441d","head":"546d4ca19df4a17d0d449abf"}}
    else if e.level.get('slug') is 'ace-of-coders'
      goliath = '55e1a6e876cb0948c96af9f8'
      e.session.set 'heroConfig', {"thangType":goliath,"inventory":{"eyes":"53eb99f41a100989a40ce46e","neck":"54693274a2b1f53ce79443c9","wrists":"54693797a2b1f53ce79443e9","feet":"546d4d8e9df4a17d0d449acd","minion":"54eb5bf649fa2d5c905ddf4a","programming-book":"557871261ff17fef5abee3ee"}}
    else if e.level.get('slug') is 'assembly-speed'
      raider = '55527eb0b8abf4ba1fe9a107'
      e.session.set 'heroConfig', {"thangType":raider,"inventory":{}}
    else if e.level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop'] and not _.size e.session.get('heroConfig')?.inventory ? {}
      @setupManager?.destroy()
      @setupManager = new LevelSetupManager({supermodel: @supermodel, level: e.level, levelID: @levelID, parent: @, session: e.session, courseID: @courseID, courseInstanceID: @courseInstanceID})
      @setupManager.open()

    @onRealTimeMultiplayerLevelLoaded e.session if e.level.get('type') in ['hero-ladder', 'course-ladder']

  onLoaded: ->
    _.defer => @onLevelLoaderLoaded()

  onLevelLoaderLoaded: ->
    # Everything is now loaded
    return unless @levelLoader.progress() is 1  # double check, since closing the guide may trigger this early

    # Save latest level played.
    if not @observing and not (@levelLoader.level.get('type') in ['ladder', 'ladder-tutorial'])
      me.set('lastLevel', @levelID)
      me.save()
      application.tracker?.identify()
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
    @surface = new Surface(@world, normalSurface, webGLSurface, thangTypes: @supermodel.getModels(ThangType), observing: @observing, playerNames: @findPlayerNames(), levelType: @level.get('type', true))
    worldBounds = @world.getBounds()
    bounds = [{x: worldBounds.left, y: worldBounds.top}, {x: worldBounds.right, y: worldBounds.bottom}]
    @surface.camera.setBounds(bounds)
    @surface.camera.zoomTo({x: 0, y: 0}, 0.1, 0)

  findPlayerNames: ->
    return {} unless @level.get('type') in ['ladder', 'hero-ladder', 'course-ladder']
    playerNames = {}
    for session in [@session, @otherSession] when session?.get('team')
      playerNames[session.get('team')] = session.get('creatorName') or 'Anoner'
    playerNames

  # Once Surface is Loaded ####################################################

  onLevelStarted: ->
    return unless @surface?
    @loadingView.showReady()
    @trackLevelLoadEnd()
    if window.currentModal and not window.currentModal.destroyed and window.currentModal.constructor isnt VictoryModal
      return Backbone.Mediator.subscribeOnce 'modal:closed', @onLevelStarted, @
    @surface.showLevel()
    Backbone.Mediator.publish 'level:set-time', time: 0
    if (@isEditorPreview or @observing) and not @getQueryVariable('intro')
      @loadingView.startUnveiling()
      @loadingView.unveil true
    else
      @scriptManager.initializeCamera()

  onLoadingViewUnveiling: (e) ->
    @selectHero()

  onLoadingViewUnveiled: (e) ->
    if @level.get('type') in ['course-ladder', 'hero-ladder'] or @observing
      # We used to autoplay by default, but now we only do it if the level says to in the introduction script.
      Backbone.Mediator.publish 'level:set-playing', playing: true
    @loadingView.$el.remove()
    @removeSubView @loadingView
    @loadingView = null
    @playAmbientSound()
    if @options.realTimeMultiplayerSessionID?
      Backbone.Mediator.publish 'playback:real-time-playback-waiting', {}
      @realTimeMultiplayerContinueGame @options.realTimeMultiplayerSessionID
    # TODO: Is it possible to create a Mongoose ObjectId for 'ls', instead of the string returned from get()?
    application.tracker?.trackEvent 'Started Level', category:'Play Level', levelID: @levelID, ls: @session?.get('_id') unless @observing
    $(window).trigger 'resize'
    _.delay (=> @perhapsStartSimulating?()), 10 * 1000

  onSetVolume: (e) ->
    createjs.Sound.setVolume(if e.volume is 1 then 0.6 else e.volume)  # Quieter for now until individual sound FX controls work again.
    if e.volume and not @ambientSound
      @playAmbientSound()

  playAmbientSound: ->
    return if @destroyed
    return if @ambientSound
    return unless me.get 'volume'
    return unless file = {Dungeon: 'ambient-dungeon', Grass: 'ambient-grass'}[@level.get('terrain')]
    src = "/file/interface/#{file}#{AudioPlayer.ext}"
    unless AudioPlayer.getStatus(src)?.loaded
      AudioPlayer.preloadSound src
      Backbone.Mediator.subscribeOnce 'audio-player:loaded', @playAmbientSound, @
      return
    @ambientSound = createjs.Sound.play src, loop: -1, volume: 0.1
    createjs.Tween.get(@ambientSound).to({volume: 1.0}, 10000)

  selectHero: ->
    Backbone.Mediator.publish 'level:suppress-selection-sounds', suppress: true
    Backbone.Mediator.publish 'tome:select-primary-sprite', {}
    Backbone.Mediator.publish 'level:suppress-selection-sounds', suppress: false
    @surface.focusOnHero()

  perhapsStartSimulating: ->
    return unless @shouldSimulate()
    # TODO: how can we not require these as part of /play bundle?
    #require "vendor/aether-#{codeLanguage}" for codeLanguage in ['javascript', 'python', 'coffeescript', 'lua', 'clojure', 'io']
    require 'vendor/aether-javascript'
    require 'vendor/aether-python'
    require 'vendor/aether-coffeescript'
    require 'vendor/aether-lua'
    require 'vendor/aether-java'
    require 'vendor/aether-clojure'
    require 'vendor/aether-io'
    require 'vendor/aether-java'
    @simulateNextGame()

  simulateNextGame: ->
    return @simulator.fetchAndSimulateOneGame() if @simulator
    simulatorOptions = background: true, leagueID: @courseInstanceID
    simulatorOptions.levelID = @level.get('slug') if @level.get('type', true) in ['course-ladder', 'hero-ladder']
    @simulator = new Simulator simulatorOptions
    # Crude method of mitigating Simulator memory leak issues
    fetchAndSimulateOneGameOriginal = @simulator.fetchAndSimulateOneGame
    @simulator.fetchAndSimulateOneGame = =>
      if @simulator.simulatedByYou >= 10
        console.log '------------------- Destroying Simulator and making a new one -----------------'
        @simulator.destroy()
        @simulator = null
        @simulateNextGame()
      else
        fetchAndSimulateOneGameOriginal.apply @simulator
    @simulator.fetchAndSimulateOneGame()

  shouldSimulate: ->
    return true if @getQueryVariable('simulate') is true
    return false if @getQueryVariable('simulate') is false
    stillBuggy = true  # Keep this true while we still haven't fixed the zombie worker problem when simulating the more difficult levels on Chrome
    defaultCores = 2
    cores = window.navigator.hardwareConcurrency or defaultCores  # Available on Chrome/Opera, soon Safari
    defaultHeapLimit = 793000000
    heapLimit = window.performance?.memory?.jsHeapSizeLimit or defaultHeapLimit  # Only available on Chrome, basically just says 32- vs. 64-bit
    levelType = @level.get 'type', true
    gamesSimulated = me.get('simulatedBy')
    console.debug "Should we start simulating? Cores:", window.navigator.hardwareConcurrency, "Heap limit:", window.performance?.memory?.jsHeapSizeLimit, "Load duration:", @loadDuration
    return false unless $.browser?.desktop
    return false if $.browser?.msie or $.browser?.msedge
    return false if $.browser.linux
    return false if me.level() < 8
    if levelType is 'course'
      return false
    else if levelType is 'hero' and gamesSimulated
      return false if stillBuggy
      return false if cores < 8
      return false if heapLimit < defaultHeapLimit
      return false if @loadDuration > 10000
    else if levelType is 'hero-ladder' and gamesSimulated
      return false if stillBuggy
      return false if cores < 4
      return false if heapLimit < defaultHeapLimit
      return false if @loadDuration > 15000
    else if levelType is 'hero-ladder' and not gamesSimulated
      return false if stillBuggy
      return false if cores < 8
      return false if heapLimit <= defaultHeapLimit
      return false if @loadDuration > 20000
    else if levelType is 'course-ladder'
      return false if cores <= defaultCores
      return false if heapLimit < defaultHeapLimit
      return false if @loadDuration > 18000
    else
      console.warn "Unwritten level type simulation heuristics; fill these in for new level type #{levelType}?"
      return false if stillBuggy
      return false if cores < 8
      return false if heapLimit < defaultHeapLimit
      return false if @loadDuration > 10000
    console.debug "We should have the power. Begin background ladder simulation."
    true

  # callbacks

  onCtrlS: (e) ->
    e.preventDefault()

  onEscapePressed: (e) ->
    return unless @$el.hasClass 'real-time'
    Backbone.Mediator.publish 'playback:stop-real-time-playback', {}

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
    $('#level-done-button').show() unless @level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder']
    @showVictory() if e.showModal
    return if @victorySeen
    @victorySeen = true
    victoryTime = (new Date()) - @loadEndTime
    if not @observing and victoryTime > 10 * 1000   # Don't track it if we're reloading an already-beaten level
      application.tracker?.trackEvent 'Saw Victory',
        category: 'Play Level'
        level: @level.get('name')
        label: @level.get('name')
        levelID: @levelID
        ls: @session?.get('_id')
      application.tracker?.trackTiming victoryTime, 'Level Victory Time', @levelID, @levelID

  showVictory: ->
    return if @level.hasLocalChanges()  # Don't award achievements when beating level changed in level editor
    @endHighlight()
    options = {level: @level, supermodel: @supermodel, session: @session, hasReceivedMemoryWarning: @hasReceivedMemoryWarning, courseID: @courseID, courseInstanceID: @courseInstanceID}
    ModalClass = if @level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder'] then HeroVictoryModal else VictoryModal
    ModalClass = CourseVictoryModal if @courseID and @courseInstanceID
    victoryModal = new ModalClass(options)
    @openModalView(victoryModal)
    if me.get('anonymous')
      window.nextURL = '/play/' + (@level.get('campaign') ? '')  # Signup will go here on completion instead of reloading.

  onRestartLevel: ->
    @tome.reloadAllCode()
    Backbone.Mediator.publish 'level:restarted', {}
    $('#level-done-button', @$el).hide()
    application.tracker?.trackEvent 'Confirmed Restart', category: 'Play Level', level: @level.get('name'), label: @level.get('name') unless @observing

  onInfiniteLoop: (e) ->
    return unless e.firstWorld and e.god is @god
    @openModalView new InfiniteLoopModal nonUserCodeProblem: e.nonUserCodeProblem
    application.tracker?.trackEvent 'Saw Initial Infinite Loop', category: 'Play Level', level: @level.get('name'), label: @level.get('name') unless @observing

  onHighlightDOM: (e) -> @highlightElement e.selector, delay: e.delay, sides: e.sides, offset: e.offset, rotation: e.rotation

  onEndHighlight: -> @endHighlight()

  onFocusDom: (e) -> $(e.selector).focus()

  onMultiplayerChanged: (e) ->
    if @session.get('multiplayer')
      @bus.connect()
    else
      @bus.removeFirebaseData =>
        @bus.disconnect()

  onSessionWillSave: (e) ->
    # Something interesting has happened, so (at a lower frequency), we'll save a screenshot.
    #@saveScreenshot e.session

  # Throttled
  saveScreenshot: (session) =>
    return unless screenshot = @surface?.screenshot()
    session.save {screenshot: screenshot}, {patch: true, type: 'PUT'}

  onContactClicked: (e) ->
    @openModalView contactModal = new ContactModal levelID: @level.get('slug') or @level.id, courseID: @courseID, courseInstanceID: @courseInstanceID
    screenshot = @surface.screenshot(1, 'image/png', 1.0, 1)
    body =
      b64png: screenshot.replace 'data:image/png;base64,', ''
      filename: "screenshot-#{@levelID}-#{_.string.slugify((new Date()).toString())}.png"
      path: "db/user/#{me.id}"
      mimetype: 'image/png'
    contactModal.screenshotURL = "http://codecombat.com/file/#{body.path}/#{body.filename}"
    window.screenshot = screenshot
    window.screenshotURL = contactModal.screenshotURL
    $.ajax '/file', type: 'POST', data: body, success: (e) ->
      contactModal.updateScreenshot?()

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
    return if @level.hasLocalChanges()  # Don't award achievements when beating level changed in level editor
    # TODO: Show a victory dialog specific to hero-ladder level
    if @goalManager.checkOverallStatus() is 'success' and not @options.realTimeMultiplayerSessionID?
      showModalFn = -> Backbone.Mediator.publish 'level:show-victory', showModal: true
      @session.recordScores @world.scores, @level
      if @level.get 'replayable'
        @session.increaseDifficulty showModalFn
      else
        showModalFn()

  destroy: ->
    @levelLoader?.destroy()
    @surface?.destroy()
    @god?.destroy()
    @goalManager?.destroy()
    @scriptManager?.destroy()
    @setupManager?.destroy()
    @simulator?.destroy()
    if ambientSound = @ambientSound
      # Doesn't seem to work; stops immediately.
      createjs.Tween.get(ambientSound).to({volume: 0.0}, 1500).call -> ambientSound.stop()
    $(window).off 'resize', @onWindowResize
    delete window.world # not sure where this is set, but this is one way to clean it up
    @bus?.destroy()
    #@instance.save() unless @instance.loading
    delete window.nextURL
    console.profileEnd?() if PROFILE_ME
    @onRealTimeMultiplayerLevelUnloaded()
    application.tracker?.disableInspectletJS()
    super()

  onIPadMemoryWarning: (e) ->
    @hasReceivedMemoryWarning = true

  onItemPurchased: (e) ->
    heroConfig = @session.get('heroConfig') ? {}
    inventory = heroConfig.inventory ? {}
    slot = e.item.getAllowedSlots()[0]
    if slot and not inventory[slot]
      # Open up the inventory modal so they can equip the new item
      @setupManager?.destroy()
      @setupManager = new LevelSetupManager({supermodel: @supermodel, level: @level, levelID: @levelID, parent: @, session: @session, hadEverChosenHero: true})
      @setupManager.open()

  # Start Real-time Multiplayer ######################################################
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
  #   Swap teams on game joined, if necessary
  #   Reload PlayLevelView on real-time submit, automatically continue game and real-time playback
  #
  # It monitors these:
  #   Real-time multiplayer sessions
  #   Current real-time multiplayer session
  #   Internal multiplayer create/joined/left events
  #
  # Real-time state variables.
  # Each Ref is Firebase reference, and may have a matching Data suffixed variable with the latest data received.
  #   @realTimePlayerRef - User's real-time multiplayer player for this level
  #   @realTimePlayerGameRef - User's current real-time multiplayer player game session
  #   @realTimeSessionRef - Current real-time multiplayer game session
  #   @realTimeOpponentRef - Current real-time multiplayer opponent
  #   @realTimePlayersRef - Real-time players for current real-time multiplayer game session
  #   @options.realTimeMultiplayerSessionID - Need to continue an existing real-time multiplayer session
  #
  # TODO: Move this code to it's own file, or possibly the LevelBus
  # TODO: Save settings somewhere reasonable
  multiplayerFireHost: 'https://codecombat.firebaseio.com/test/db/'

  onRealTimeMultiplayerLevelLoaded: (session) ->
    # console.log 'PlayLevelView onRealTimeMultiplayerLevelLoaded'
    return if @realTimePlayerRef?
    return if me.get('anonymous')
    @realTimePlayerRef = new Firebase "#{@multiplayerFireHost}multiplayer_players/#{@levelID}/#{me.id}"
    unless @options.realTimeMultiplayerSessionID?
      # TODO: Wait for name instead of using 'Anon', or try and update it later?
      name = me.get('name') ? session.get('creatorName') ? 'Anon'
      @realTimePlayerRef.set
        id: me.id # TODO: is this redundant info necessary?
        name: name
        state: 'playing'
        created: new Date().toISOString()
        heartbeat: new Date().toISOString()
    @timerMultiplayerHeartbeatID = setInterval @onRealTimeMultiplayerHeartbeat, 60 * 1000
    @cleanupRealTimeSessions()

  cleanupRealTimeSessions: ->
    # console.log 'PlayLevelView cleanupRealTimeSessions'
    # TODO: Reduce this call, possibly by username and dates
    realTimeSessionCollection = new Firebase "#{@multiplayerFireHost}multiplayer_level_sessions/#{@levelID}"
    realTimeSessionCollection.once 'value', (collectionSnapshot) =>
      for multiplayerSessionID, multiplayerSession of collectionSnapshot.val()
        continue if @options.realTimeMultiplayerSessionID? and @options.realTimeMultiplayerSessionID is multiplayerSessionID
        continue unless multiplayerSession.state isnt 'finished'
        player = realTimeSessionCollection.child "#{multiplayerSession.id}/players/#{me.id}"
        player.once 'value', (playerSnapshot) =>
          if playerSnapshot.val()
            console.info 'Cleaning up previous real-time multiplayer session', multiplayerSessionID
            player.update 'state': 'left'
            multiplayerSessionRef = realTimeSessionCollection.child "#{multiplayerSessionID}"
            multiplayerSessionRef.update 'state': 'finished'

  onRealTimeMultiplayerLevelUnloaded: ->
    # console.log 'PlayLevelView onRealTimeMultiplayerLevelUnloaded'
    if @timerMultiplayerHeartbeatID?
      clearInterval @timerMultiplayerHeartbeatID
      @timerMultiplayerHeartbeatID = null

    # TODO: similar to game ending cleanup
    if @realTimeOpponentRef?
      @realTimeOpponentRef.off 'value', @onRealTimeOpponentChanged
      @realTimeOpponentRef = null
    if @realTimePlayersRef?
      @realTimePlayersRef.off 'child_added', @onRealTimePlayerAdded
      @realTimePlayersRef = null
    if @realTimeSessionRef?
      @realTimeSessionRef.off 'value', @onRealTimeSessionChanged
      @realTimeSessionRef = null
    if @realTimePlayerGameRef?
      @realTimePlayerGameRef = null
    if @realTimePlayerRef?
      @realTimePlayerRef = null

  onRealTimeMultiplayerHeartbeat: =>
    # console.log 'PlayLevelView onRealTimeMultiplayerHeartbeat', @realTimePlayerRef
    @realTimePlayerRef.update 'heartbeat': new Date().toISOString() if @realTimePlayerRef?

  onRealTimeMultiplayerCreatedGame: (e) ->
    # console.log 'PlayLevelView onRealTimeMultiplayerCreatedGame'
    @joinRealTimeMultiplayerGame e
    @realTimePlayerGameRef.update 'state': 'coding'
    @realTimePlayerRef.update 'state': 'available'
    Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Waiting for opponent..'

  onRealTimeSessionChanged: (snapshot) =>
    # console.log 'PlayLevelView onRealTimeSessionChanged', snapshot.val()
    @realTimeSessionData = snapshot.val()
    if @realTimeSessionData?.state is 'finished'
      @realTimeGameEnded()
      Backbone.Mediator.publish 'real-time-multiplayer:left-game', {}

  onRealTimePlayerAdded: (snapshot) =>
    # console.log 'PlayLevelView onRealTimePlayerAdded', snapshot.val()
    # Assume game is full, game on
    data = snapshot.val()
    if data? and data.id isnt me.id
      @realTimeOpponentData = data
      # console.log 'PlayLevelView onRealTimePlayerAdded opponent', @realTimeOpponentData, @realTimePlayersData
      @realTimePlayersData[@realTimeOpponentData.id] = @realTimeOpponentData
      if @realTimeSessionData?.state is 'creating'
        @realTimeSessionRef.update 'state': 'coding'
        @realTimePlayerRef.update 'state': 'unavailable'
        @realTimeOpponentRef = @realTimeSessionRef.child "players/#{@realTimeOpponentData.id}"
        @realTimeOpponentRef.on 'value', @onRealTimeOpponentChanged
        Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: "Playing against #{@realTimeOpponentData.name}"

  onRealTimeOpponentChanged: (snapshot) =>
    # console.log 'PlayLevelView onRealTimeOpponentChanged', snapshot.val()
    @realTimeOpponentData = snapshot.val()
    switch @realTimeOpponentData?.state
      when 'left'
        console.info 'Real-time multiplayer opponent left the game'
        opponentID = @realTimeOpponentData.id
        @realTimeGameEnded()
        Backbone.Mediator.publish 'real-time-multiplayer:left-game', userID: opponentID
      when 'submitted'
        # TODO: What should this message say?
        Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: "#{@realTimeOpponentData.name} waiting for your code"

  joinRealTimeMultiplayerGame: (e) ->
    # console.log 'PlayLevelView joinRealTimeMultiplayerGame', e
    unless @realTimeSessionRef?
      @session.set('submittedCodeLanguage', @session.get('codeLanguage'))
      @session.save()

      @realTimeSessionRef = new Firebase "#{@multiplayerFireHost}multiplayer_level_sessions/#{@levelID}/#{e.realTimeSessionID}"
      @realTimePlayersRef = @realTimeSessionRef.child 'players'

      # Look for opponent
      @realTimeSessionRef.once 'value', (multiplayerSessionSnapshot) =>
        if @realTimeSessionData = multiplayerSessionSnapshot.val()
          @realTimePlayersRef.once 'value', (playsSnapshot) =>
            if @realTimePlayersData = playsSnapshot.val()
              for id, player of @realTimePlayersData
                if id isnt me.id
                  @realTimeOpponentRef = @realTimeSessionRef.child "players/#{id}"
                  @realTimeOpponentRef.once 'value', (opponentSnapshot) =>
                    if @realTimeOpponentData = opponentSnapshot.val()
                      @updateTeam()
                    else
                      console.error 'Could not lookup multiplayer opponent data.'
                    @realTimeOpponentRef.on 'value', @onRealTimeOpponentChanged
                  Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Playing against ' + player.name
            else
              console.error 'Could not lookup multiplayer session players data.'
            # TODO: need child_removed too?
            @realTimePlayersRef.on 'child_added', @onRealTimePlayerAdded
        else
          console.error 'Could not lookup multiplayer session data.'
        @realTimeSessionRef.on 'value', @onRealTimeSessionChanged

      @realTimePlayerGameRef = @realTimeSessionRef.child "players/#{me.id}"

    # TODO: Follow up in MultiplayerView to see if double joins can be avoided
    # else
    #   console.error 'Joining real-time multiplayer game with an existing @realTimeSessionRef.'

  onRealTimeMultiplayerJoinedGame: (e) ->
    # console.log 'PlayLevelView onRealTimeMultiplayerJoinedGame', e
    @joinRealTimeMultiplayerGame e
    @realTimePlayerGameRef.update 'state': 'coding'
    @realTimePlayerRef.update 'state': 'unavailable'

  onRealTimeMultiplayerLeftGame: (e) ->
    # console.log 'PlayLevelView onRealTimeMultiplayerLeftGame', e
    if e.userID? and e.userID is me.id
      @realTimePlayerGameRef.update 'state': 'left'
      @realTimeGameEnded()

  realTimeMultiplayerContinueGame: (realTimeSessionID) ->
    # console.log 'PlayLevelView realTimeMultiplayerContinueGame', realTimeSessionID, me.id
    Backbone.Mediator.publish 'real-time-multiplayer:joined-game', realTimeSessionID: realTimeSessionID

    console.info 'Setting my game status to ready'
    @realTimePlayerGameRef.update 'state': 'ready'

    if @realTimeOpponentData.state is 'ready'
      @realTimeOpponentIsReady()
    else
      console.info 'Waiting for opponent to be ready'
      @realTimeOpponentRef.on 'value', @realTimeOpponentMaybeReady

  realTimeOpponentMaybeReady: (snapshot) =>
    # console.log 'PlayLevelView realTimeOpponentMaybeReady'
    if @realTimeOpponentData = snapshot.val()
      if @realTimeOpponentData.state is 'ready'
        @realTimeOpponentRef.off 'value', @realTimeOpponentMaybeReady
        @realTimeOpponentIsReady()

  realTimeOpponentIsReady: =>
    console.info 'All real-time multiplayer players are ready!'
    @realTimeSessionRef.update 'state': 'running'
    Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: 'Battling ' + @realTimeOpponentData.name
    Backbone.Mediator.publish 'tome:manual-cast', {realTime: true}

  realTimeGameEnded: ->
    if @realTimeOpponentRef?
      @realTimeOpponentRef.off 'value', @onRealTimeOpponentChanged
      @realTimeOpponentRef = null
    if @realTimePlayersRef?
      @realTimePlayersRef.off 'child_added', @onRealTimePlayerAdded
      @realTimePlayersRef = null
    if @realTimeSessionRef?
      @realTimeSessionRef.off 'value', @onRealTimeSessionChanged
      @realTimeSessionRef.update 'state': 'finished'
      @realTimeSessionRef = null
    if @realTimePlayerGameRef?
      @realTimePlayerGameRef = null
    if @realTimePlayerRef?
      @realTimePlayerRef.update 'state': 'playing'
    Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: ''

  onRealTimeMultiplayerCast: (e) ->
    # console.log 'PlayLevelView onRealTimeMultiplayerCast', @realTimeSessionData, @realTimePlayersData
    unless @realTimeSessionRef?
      console.error 'Real-time multiplayer cast without multiplayer session.'
      return
    unless @realTimeSessionData?
      console.error 'Real-time multiplayer cast without multiplayer data.'
      return
    unless @realTimePlayersData?
      console.error 'Real-time multiplayer cast without multiplayer players data.'
      return

    # Set submissionCount for created real-time multiplayer session
    if me.id is @realTimeSessionData.creator
      sessionState = @session.get('state')
      if sessionState?
        submissionCount = sessionState.submissionCount ? 0
        console.info 'Setting multiplayer submissionCount to', submissionCount
        @realTimeSessionRef.update 'submissionCount': submissionCount
      else
        console.error 'Failed to read sessionState in onRealTimeMultiplayerCast'

    console.info 'Submitting my code'
    # Transpiling code copied from scripts/transpile.coffee
    # TODO: Should this live somewhere else?
    transpiledCode = {}
    for thang, spells of @session.get('code')
      transpiledCode[thang] = {}
      for spellID, spell of spells
        spellName = thang + '/' + spellID
        continue if @session.get('teamSpells') and not (spellName in @session.get('teamSpells')[@session.get('team')])
        # console.log "PlayLevelView Transpiling spell #{spellName}"
        aetherOptions = createAetherOptions functionName: spellID, codeLanguage: @session.get('submittedCodeLanguage'), includeFlow: true
        aether = new Aether aetherOptions
        transpiledCode[thang][spellID] = aether.transpile spell
    # console.log "PlayLevelView transpiled code", transpiledCode
    @session.set 'transpiledCode', transpiledCode
    permissions = @session.get 'permissions' ? []
    unless _.find(permissions, (p) -> p.target is 'public' and p.access is 'read')
      permissions.push target:'public', access:'read'
      @session.set 'permissions', permissions
    @session.patch()
    @realTimePlayerGameRef.update 'state': 'submitted'

    console.info 'Other player is', @realTimeOpponentData.state
    if @realTimeOpponentData.state in ['submitted', 'ready']
      @realTimeOpponentSubmittedCode @realTimeOpponentData, @realTimePlayerGameData
    else
      # Wait for opponent to submit their code
      Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: "Waiting for code from #{@realTimeOpponentData.name}"
      @realTimeOpponentRef.on 'value', @realTimeOpponentMaybeSubmitted

  realTimeOpponentMaybeSubmitted: (snapshot) =>
    if @realTimeOpponentData = snapshot.val()
      if @realTimeOpponentData.state in ['submitted', 'ready']
        @realTimeOpponentRef.off 'value', @realTimeOpponentMaybeSubmitted
        @realTimeOpponentSubmittedCode @realTimeOpponentData, @realTimePlayerGameData

  onRealTimeMultiplayerPlaybackEnded: ->
    # console.log 'PlayLevelView onRealTimeMultiplayerPlaybackEnded'
    if @realTimeSessionRef?
      @realTimeSessionRef.update 'state': 'coding'
      @realTimePlayerGameRef.update 'state': 'coding'
    if @realTimeOpponentData?
      Backbone.Mediator.publish 'real-time-multiplayer:player-status', status: "Playing against #{@realTimeOpponentData.name}"

  realTimeOpponentSubmittedCode: (opponentPlayer, myPlayer) =>
    # console.log 'PlayLevelView realTimeOpponentSubmittedCode', @realTimeSessionData.id, opponentPlayer.level_session
    # Read submissionCount for joined real-time multiplayer session
    if me.id isnt @realTimeSessionData.creator
      sessionState = @session.get('state') ? {}
      newSubmissionCount = @realTimeSessionData.submissionCount
      if newSubmissionCount?
        # TODO: This isn't always getting updated where the random seed generation uses it.
        sessionState.submissionCount = parseInt newSubmissionCount
        console.info 'Got multiplayer submissionCount', sessionState.submissionCount
        @session.set 'state', sessionState
        @session.patch()

    # Reload this level so the opponent session can easily be wired up
    Backbone.Mediator.publish 'router:navigate',
      route: "/play/level/#{@levelID}"
      viewClass: PlayLevelView
      viewArgs: [{supermodel: @supermodel, autoUnveil: true, realTimeMultiplayerSessionID: @realTimeSessionData.id, opponent: opponentPlayer.level_session, team: @team}, @levelID]

  updateTeam: ->
    # If not creator, and same team as creator, then switch teams
    # TODO: Assumes there are only 'humans' and 'ogres'

    unless @realTimeOpponentData?
      console.error 'Tried to switch teams without real-time multiplayer opponent data.'
      return
    unless @realTimeSessionData?
      console.error 'Tried to switch teams without real-time multiplayer session data.'
      return
    return if me.id is @realTimeSessionData.creator

    oldTeam = @realTimeOpponentData.team
    return unless oldTeam is @session.get('team')

    # Need to switch to other team
    newTeam = if oldTeam is 'humans' then 'ogres' else 'humans'
    console.info "Switching from team #{oldTeam} to #{newTeam}"

    # Move code from old team to new team
    # Assumes teamSpells has matching spells for each team
    # TODO: Similar to code in loadOpponentTeam, consolidate?
    code = @session.get 'code'
    teamSpells = @session.get 'teamSpells'
    for oldSpellKey in teamSpells[oldTeam]
      [oldThang, oldSpell] = oldSpellKey.split '/'
      oldCode = code[oldThang]?[oldSpell]
      continue unless oldCode?
      # Move oldCode to new team under same spell
      for newSpellKey in teamSpells[newTeam]
        [newThang, newSpell] = newSpellKey.split '/'
        if newSpell is oldSpell
          # Found spell location under new team
          # console.log "Swapping spell=#{oldSpell} from #{oldThang} to #{newThang}"
          if code[newThang]?[oldSpell]?
            # Option 1: have a new spell to swap
            code[oldThang][oldSpell] = code[newThang][oldSpell]
          else
            # Option 2: no new spell to swap
            delete code[oldThang][oldSpell]
          code[newThang] = {} unless code[newThang]?
          code[newThang][oldSpell] = oldCode
          break

    @setTeam newTeam # Sets @session 'team'
    sessionState = @session.get('state')
    if sessionState?
    # TODO: Don't hard code thangID
      sessionState.selected = if newTeam is 'humans' then 'Hero Placeholder' else 'Hero Placeholder 1'
      @session.set 'state', sessionState
    @session.set 'code', code
    @session.patch()

    if sessionState?
      # TODO: Don't hardcode spellName
      Backbone.Mediator.publish 'level:select-sprite', thangID: sessionState.selected, spellName: 'plan'

# End Real-time Multiplayer ######################################################
