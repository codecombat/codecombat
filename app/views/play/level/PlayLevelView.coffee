require('app/styles/play/level/level-loading-view.sass')
require('app/styles/play/level/tome/spell_palette_entry.sass')
require('app/styles/play/play-level-view.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/play/play-level-view'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'
utils = require 'core/utils'
storage = require 'core/storage'
{createAetherOptions} = require 'lib/aether_utils'
loadAetherLanguage = require 'lib/loadAetherLanguage'

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
Mandate = require 'models/Mandate'
Camera = require 'lib/surface/Camera'
AudioPlayer = require 'lib/AudioPlayer'
Simulator = require 'lib/simulator/Simulator'
GameUIState = require 'models/GameUIState'
createjs = require 'lib/createjs-parts'

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
GameDevTrackView = require './GameDevTrackView'
DuelStatsView = require './DuelStatsView'
VictoryModal = require './modal/VictoryModal'
HeroVictoryModal = require './modal/HeroVictoryModal'
CourseVictoryModal = require './modal/CourseVictoryModal'
PicoCTFVictoryModal = require './modal/PicoCTFVictoryModal'
InfiniteLoopModal = require './modal/InfiniteLoopModal'
LevelSetupManager = require 'lib/LevelSetupManager'
ContactModal = require 'views/core/ContactModal'
HintsView = require './HintsView'
SurfaceContextMenuView = require './SurfaceContextMenuView'
HintsState = require './HintsState'
WebSurfaceView = require './WebSurfaceView'
store = require('core/store')

require 'lib/game-libraries'
window.Box2D = require('exports-loader?Box2D!vendor/scripts/Box2dWeb-2.1.a.3')

PROFILE_ME = false

STOP_CHECK_TOURNAMENT_CLOSE = 0  # tournament ended
KEEP_CHECK_TOURNAMENT_CLOSE = 1  # tournament not begin
STOP_CHECK_TOURNAMENT_OPEN = 2  # none tournament only level
KEEP_CHECK_TOURNAMENT_OPEN = 3  # tournament running

TOURNAMENT_OPEN = [2, 3]
STOP_CHECK_TOURNAMENT = [0, 2]

module.exports = class PlayLevelView extends RootView
  id: 'level-view'
  template: template
  cache: false
  shortcutsEnabled: true
  isEditorPreview: false
  codeFormat: 'text-code'

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
    'level:started': 'onLevelStarted'
    'level:loading-view-unveiling': 'onLoadingViewUnveiling'
    'level:loading-view-unveiled': 'onLoadingViewUnveiled'
    'level:loaded': 'onLevelLoaded'
    'level:session-loaded': 'onSessionLoaded'
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'playback:cinematic-playback-started': 'onCinematicPlaybackStarted'
    'playback:cinematic-playback-ended': 'onCinematicPlaybackEnded'
    'ipad:memory-warning': 'onIPadMemoryWarning'
    'store:item-purchased': 'onItemPurchased'
    'tome:manual-cast': 'onRunCode'
    'tome:code-format-changed': 'onCodeFormatChanged'
    'world:update-key-value-db': 'updateKeyValueDb'

  events:
    'click #level-done-button': 'onDonePressed'
    'click #stop-real-time-playback-button': -> Backbone.Mediator.publish 'playback:stop-real-time-playback', {}
    'click #stop-cinematic-playback-button': -> Backbone.Mediator.publish 'playback:stop-cinematic-playback', {}
    'click .contact-link': 'onContactClicked'
    'contextmenu #webgl-surface': 'onSurfaceContextMenu'
    'click': 'onClick'
    'click .close-solution-btn': 'onCloseSolution'

  onClick: ->
    # workaround to get users out of permanent idle status
    if application.userIsIdle
      application.idleTracker.onVisible()

    #hide context menu if visible
    if @$('#surface-context-menu-view').is(":visible")
      Backbone.Mediator.publish 'level:surface-context-menu-hide', {}

  shortcuts:
    'ctrl+s': 'onCtrlS'
    'esc': 'onEscapePressed'

  # Initial Setup #############################################################

  constructor: (options, @levelID) ->
    console.profile?() if PROFILE_ME
    super options

    @options = options
    @courseID = options.courseID or utils.getQueryVariable 'course'
    @courseInstanceID = options.courseInstanceID or utils.getQueryVariable 'course-instance' or utils.getQueryVariable 'instance' # instance to avoid sessionless to be false when teaching

    @isEditorPreview = utils.getQueryVariable 'dev'
    @sessionID = (utils.getQueryVariable 'session') || @options.sessionID
    @observing = utils.getQueryVariable 'observing'
    @teaching = utils.getQueryVariable 'teaching'

    @opponentSessionID = utils.getQueryVariable('opponent')
    @opponentSessionID ?= @options.opponent
    @gameUIState = new GameUIState()

    $('flying-focus').remove() #Causes problems, so yank it out for play view.
    $(window).on 'resize', @onWindowResize

    if @isEditorPreview
      @supermodel.shouldSaveBackups = (model) ->  # Make sure to load possibly changed things from localStorage.
        model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']
      f = => @load?() unless @levelLoader  # Wait to see if it's just given to us through setLevel.
      setTimeout f, 100
    else
      @load()
      application.tracker?.trackEvent 'Started Level Load', category: 'Play Level', level: @levelID, label: @levelID unless @observing

    @calcTimeOffset()
    @mandate = @supermodel.loadModel(new Mandate()).model

    if features.china
      @checkTournamentEndInterval = setInterval @checkTournamentEnd.bind(@), 3000

    preloadImages = ['/images/level/code_palette_wood_background.png', '/images/level/code_editor_background_border.png']
    _.delay (-> $('<img/>')[0].src = img for img in preloadImages), 1000

  getMeta: ->
    link: [
      { vmid: 'rel-canonical', rel: 'canonical', content: '/play' }
    ]

  setLevel: (@level, givenSupermodel) ->
    @supermodel.models = givenSupermodel.models
    @supermodel.collections = givenSupermodel.collections
    @supermodel.shouldSaveBackups = givenSupermodel.shouldSaveBackups

    serializedLevel = @level.serialize {@supermodel, @session, @otherSession, headless: false, sessionless: false}
    if me.constrainHeroHealth()
      serializedLevel.constrainHeroHealth = true
    @god?.setLevel serializedLevel
    if @world
      @world.loadFromLevel serializedLevel, false
    else
      @load()

  load: ->
    @loadStartTime = new Date()
    levelLoaderOptions = { @supermodel, @levelID, @sessionID, @opponentSessionID, team: utils.getQueryVariable('team'), @observing, @courseID, @courseInstanceID, @teaching }
    if me.isSessionless()
      levelLoaderOptions.fakeSessionConfig = {}
    @levelLoader = new LevelLoader levelLoaderOptions
    @listenToOnce @levelLoader, 'world-necessities-loaded', @onWorldNecessitiesLoaded
    @listenTo @levelLoader, 'world-necessity-load-failed', @onWorldNecessityLoadFailed

    codeFormat = 'text-code'
    codeFormatOverride = utils.getQueryVariable('codeFormat') || utils.getQueryVariable('blocks')
    if codeFormatOverride?
      codeFormat = {
        true: 'blocks-and-code',
        false: 'text-code',
        'blocks-icons': 'blocks-icons',
        'blocks-text': 'blocks-text',
        'blocks-and-code': 'blocks-and-code',
        'text-code': 'text-code',
        }[codeFormatOverride] or codeFormat
    @classroomAceConfig = {liveCompletion: true, codeFormatDefault: codeFormat, classroomItems: true }  # default (home users, teachers, etc.)
    if @courseInstanceID
      fetchAceConfig = $.get("/db/course_instance/#{@courseInstanceID}/classroom?project=aceConfig,members,ownerID,classroomItems")
      @supermodel.trackRequest fetchAceConfig
      fetchAceConfig.then (classroom) =>
        @classroomAceConfig.liveCompletion = classroom.aceConfig?.liveCompletion ? true
        @classroomAceConfig.codeFormatDefault = classroom.aceConfig?.codeFormatDefault ? classroom.aceConfig.defaultCodeFormat ? codeFormat
        @classroomAceConfig.codeFormats = classroom.aceConfig?.codeFormats ? ['blocks-icons', 'blocks-text', 'blocks-and-code', 'text-code']
        @tome?.determineCodeFormat()
        @classroomAceConfig.levelChat = classroom.aceConfig?.levelChat ? 'none'
        @classroomAceConfig.classroomItems = classroom?.classroomItems ? (!features?.china) # china classroomitems default to false and global default to true
        @teacherID = classroom.ownerID

        if @teaching and (not @teacherID.equals(me.id))
          return _.defer -> application.router.redirectHome()

  hasAccessThroughClan: (level) ->
    _.intersection(level.get('clans') ? [], me.get('clans') ? []).length

  onLevelLoaded: (e) ->
    return if @destroyed
    if _.all([
      ((me.isStudent() or me.isTeacher()) and !application.getHocCampaign()),
      not @courseID,
      not e.level.isType('course-ladder', 'ladder')

      # TODO: Add a general way for standalone levels to be accessed by students, teachers
      not @hasAccessThroughClan(e.level)
      e.level.get('slug') not in ['peasants-and-munchkins',
                                  'game-dev-2-tournament-project',
                                  'game-dev-3-tournament-project']
    ])
      return _.defer -> application.router.redirectHome()

    unless e.level.isType('web-dev')
      @god = new God({
        @gameUIState
        indefiniteLength: e.level.isType('game-dev')
      })
    @setupGod() if @waitingToSetUpGod
    @levelSlug = e.level.get('slug')

  checkTournamentEnd: ->
    return unless @timeOffset
    return unless @mandate.loaded
    return unless @levelSlug
    return unless @level?.get('type') is 'course-ladder'
    courseInstanceID = @courseInstanceID or utils.getQueryVariable 'league'
    mandate = @mandate.get('0')

    tournamentState = STOP_CHECK_TOURNAMENT_OPEN
    if mandate
      tournamentState = @getTournamentState mandate, courseInstanceID, @levelSlug, @timeOffset
      unless me.isAdmin() or tournamentState in TOURNAMENT_OPEN
        window.location.href = '/play/ladder/'+@levelSlug+(if courseInstanceID then '/course/'+courseInstanceID else "")
    if tournamentState in STOP_CHECK_TOURNAMENT
      clearInterval @checkTournamentEndInterval

  getTournamentState: (mandate, courseInstanceID, levelSlug, timeOffset) ->
    tournament = _.find mandate.currentTournament or [], (t) ->
      t.courseInstanceID is courseInstanceID and t.level is levelSlug
    if tournament
      currentTime = (Date.now() + timeOffset) / 1000
      console.log "Current time:", new Date(currentTime * 1000)
      if currentTime < tournament.startAt
        delta = tournament.startAt - currentTime
        console.log "Tournament will start at: #{new Date(tournament.startAt * 1000)}, Time left: #{parseInt(delta / 60 / 60) }:#{parseInt(delta / 60) % 60}:#{parseInt(delta) % 60}"
        return KEEP_CHECK_TOURNAMENT_CLOSE
      else if currentTime > tournament.endAt
        console.log "Tournament ended at: #{new Date(tournament.endAt * 1000)}"
        return STOP_CHECK_TOURNAMENT_CLOSE
      delta = tournament.endAt - currentTime
      console.log "Tournament will end at: #{new Date(tournament.endAt * 1000)}, Time left: #{parseInt(delta / 60 / 60) }:#{parseInt(delta / 60) % 60}:#{parseInt(delta) % 60}"
      return KEEP_CHECK_TOURNAMENT_OPEN
    else
      return if levelSlug in (mandate.tournamentOnlyLevels or []) then STOP_CHECK_TOURNAMENT_CLOSE else STOP_CHECK_TOURNAMENT_OPEN

  calcTimeOffset: ->
    $.ajax
      type: 'HEAD'
      success: (result, status, xhr) =>
        @timeOffset = new Date(xhr.getResponseHeader("Date")).getTime() - Date.now()

  trackLevelLoadEnd: ->
    return if @isEditorPreview
    @loadEndTime = new Date()
    @loadDuration = @loadEndTime - @loadStartTime
    console.debug "Level unveiled after #{(@loadDuration / 1000).toFixed(2)}s"
    unless @observing or @isEditorPreview
      application.tracker?.trackEvent 'Finished Level Load', category: 'Play Level', label: @levelID, level: @levelID, loadDuration: @loadDuration
      application.tracker?.trackTiming @loadDuration, 'Level Load Time', @levelID, @levelID

  isCourseMode: -> @courseID and @courseInstanceID

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

    levelName = utils.i18n @level.attributes, 'name'
    @setMeta title: $.i18n.t('play.level_title', { level: levelName, interpolation: { escapeValue: false } })

    unless @level.isType 'ladder'
      randomTeam = @world?.teamForPlayer()  # If no team is set, then we will want to equally distribute players to teams
    team = utils.getQueryVariable('team') ? @session?.get('team') ? randomTeam ? 'humans'
    @loadOpponentTeam(team)
    @setupGod()
    @setTeam team
    @initGoalManager()
    @insertSubviews()
    @initVolume()
    @register()
    @controlBar.setBus(@bus)
    @initScriptManager()

  onWorldNecessityLoadFailed: (resource) ->
    @loadingView.onLoadError(resource)

  grabLevelLoaderData: ->
    @session = @levelLoader.session
    @level = @levelLoader.level
    store.commit('game/setLevel', @level.attributes)
    if @level.isType('web-dev')
      @$el.addClass 'web-dev'  # Hide some of the elements we won't be using
      return
    @world = @levelLoader.world
    if @level.isType('game-dev')
      @$el.addClass 'game-dev'
      @howToPlayText = utils.i18n(@level.attributes, 'studentPlayInstructions')
      @howToPlayText ?= $.i18n.t('play_game_dev_level.default_student_instructions')
      @howToPlayText = marked(@howToPlayText, { sanitize: true })
      @renderSelectors('#how-to-play-game-dev-panel')
    @$el.addClass 'flags' if _.any(@world.thangs, (t) -> (t.programmableProperties and 'findFlags' in t.programmableProperties) or t.inventory?.flag) or @level.get('slug') is 'sky-span'
    if @level.get('product') is 'codecombat-junior'
      @$el.addClass 'junior'
    # TODO: Update terminology to always be opponentSession or otherSession
    # TODO: E.g. if it's always opponent right now, then variable names should be opponentSession until we have coop play
    @otherSession = @levelLoader.opponentSession
    unless @level.isType('game-dev')
      @worldLoadFakeResources = []  # first element (0) is 1%, last (99) is 100%
      for percent in [1 .. 100]
        @worldLoadFakeResources.push @supermodel.addSomethingResource 1
    @renderSelectors '#stop-real-time-playback-button'

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
    for spellTeam, spells of utils.teamSpells
      continue if spellTeam is myTeam or not myTeam
      opponentSpells = opponentSpells.concat spells
    if not @session.get('teamSpells')
      @session.set('teamSpells', utils.teamSpells)
    opponentCode = @otherSession?.get('code') or {}
    myCode = @session.get('code') or {}
    for spell in opponentSpells
      [thang, spell] = spell.split '/'
      c = opponentCode[thang]?[spell]
      myCode[thang] ?= {}
      if c then myCode[thang][spell] = c else delete myCode[thang][spell]
    @session.set('code', myCode)

  setupGod: ->
    return if @level.isType('web-dev')
    return @waitingToSetUpGod = true unless @god
    @waitingToSetUpGod = undefined
    serializedLevel = @level.serialize {@supermodel, @session, @otherSession, headless: false, sessionless: false}
    if me.constrainHeroHealth()
      serializedLevel.constrainHeroHealth = true
    @god.setLevel serializedLevel
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
    options = {}

    if @level.get('assessment') is 'cumulative'
      options.minGoalsToComplete = 1
    @goalManager = new GoalManager(@world, @level.get('goals'), @team, options)
    @god?.setGoalManager @goalManager

  updateGoals: (goals) ->
    @level.set 'goals', goals
    @goalManager.destroy()
    @initGoalManager()

  insertSubviews: ->
    @hintsState = new HintsState({ hidden: true }, { @session, @level, @supermodel })
    store.commit('game/setHintsVisible', false)
    @hintsState.on('change:hidden', (hintsState, newHiddenValue) ->
      store.commit('game/setHintsVisible', !newHiddenValue)
    )
    @insertSubView @tome = new TomeView { @levelID, @session, @otherSession, playLevelView: @, thangs: @world?.thangs ? [], @supermodel, @level, @observing, @courseID, @courseInstanceID, @god, @hintsState, @classroomAceConfig, @teacherID}
    @insertSubView new LevelPlaybackView {@session, @level} unless @level.isType('web-dev')
    @insertSubView new GoalsView {@level, @session}
    @insertSubView new LevelFlagsView {@levelID, @world} if @$el.hasClass 'flags'
    goldInDuelStatsView = @level.get('slug') in ['wakka-maul', 'cross-bones']
    @insertSubView new GoldView {} unless @level.isType('web-dev', 'game-dev') or goldInDuelStatsView or @level.get('product', true) isnt 'codecombat'
    @insertSubView new GameDevTrackView {} if @level.isType('game-dev')
    @insertSubView new HUDView {@level} unless @level.isType('web-dev')
    @insertSubView new LevelDialogueView {@level, sessionID: @session.id}
    @insertSubView new ChatView {@levelID, sessionID: @session.id, @session, aceConfig: @classroomAceConfig}
    @insertSubView new ProblemAlertView {@session, @level, @supermodel, aceConfig: @classroomAceConfig}
    @insertSubView new SurfaceContextMenuView {@session, @level}
    @insertSubView new DuelStatsView {@level, @session, @otherSession, @supermodel, thangs: @world.thangs, showsGold: goldInDuelStatsView} if @level.isLadder()
    @insertSubView @controlBar = new ControlBarView {worldName: utils.i18n(@level.attributes, 'name'), @session, @level, @supermodel, @courseID, @courseInstanceID, @classroomAceConfig, @hintsState, @teacherID, @team }
    @insertSubView @hintsView = new HintsView({ @session, @level, @hintsState,  aceConfig: @classroomAceConfig }), @$('.hints-view')
    @insertSubView @webSurface = new WebSurfaceView {@level, @goalManager} if @level.isType('web-dev')
    #_.delay (=> Backbone.Mediator.publish('level:set-debug', debug: true)), 5000 if @isIPadApp()   # if me.displayName() is 'Nick'

  initVolume: ->
    volume = me.get('volume')
    volume = 1.0 unless volume?
    Backbone.Mediator.publish 'level:set-volume', volume: volume

  initScriptManager: ->
    return if @level.isType('web-dev')
    @scriptManager = new ScriptManager({scripts: @world.scripts or [], view: @, session: @session, levelID: @level.get('slug')})
    @scriptManager.loadFromSession()

  register: ->
    @bus = LevelBus.get(@levelID, @session.id)
    @bus.setSession(@session)
    @bus.setSpells @tome.spells

    if @teacherID
      @bus.subscribeTeacher(@teacherID)
    #@bus.connect() if @session.get('multiplayer')  # TODO: session's multiplayer flag removed; connect bus another way if we care about it

  # Load Completed Setup ######################################################

  onSessionLoaded: (e) ->
    store.commit('game/setTimesCodeRun', e.session.get('timesCodeRun') or 0)
    store.commit('game/setTimesAutocompleteUsed', e.session.get('timesAutocompleteUsed') or 0)
    return if @session
    Backbone.Mediator.publish "ipad:language-chosen", language: e.session.get('codeLanguage') ? "python"
    # Just the level and session have been loaded by the level loader
    if e.level.usesSessionHeroInventory() and not _.size(e.session.get('heroConfig')?.inventory ? {})
      # Delaying this check briefly so LevelLoader.loadDependenciesForSession has a chance to set the heroConfig on the level session
      _.defer =>
        return if @destroyed or _.size(e.session.get('heroConfig')?.inventory ? {})
        # TODO: which scenario is this executed for?
        @setupManager?.destroy()
        @setupManager = new LevelSetupManager({supermodel: @supermodel, level: e.level, levelID: @levelID, parent: @, session: e.session, courseID: @courseID, courseInstanceID: @courseInstanceID})
        @setupManager.open()

  onLoaded: ->
    _.defer => @onLevelLoaderLoaded?()

  onLevelLoaderLoaded: ->
    # Everything is now loaded
    return unless @levelLoader?.progress() is 1  # double check, since closing the guide may trigger this early
    if not @level
      console.warn 'Warning: somehow level loader loaded without having grabbed level loader data first? Trying again soon.'
      _.delay (=> @onLevelLoaderLoaded?()), 2000
      return

    # Save latest level played.
    if not @observing and not @isEditorPreview and not @levelLoader.level.isType('ladder-tutorial')
      me.set('lastLevel', @levelID)
      me.save()
      application.tracker?.identify()
    @saveRecentMatch() if @otherSession
    @levelLoader.destroy()
    @levelLoader = null
    if @level.isType('web-dev')
      Backbone.Mediator.publish 'level:started', {}
    else
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
    surfaceOptions = {
      thangTypes: @supermodel.getModels(ThangType)
      @observing
      playerNames: @findPlayerNames()
      levelType: @level.get('type', true)
      @gameUIState
      @level # TODO: change from levelType to level
      resizeStrategy: 'wrapper-size'
    }
    @surface = new Surface(@world, normalSurface, webGLSurface, surfaceOptions)
    worldBounds = @world.getBounds()
    bounds = [{x: worldBounds.left, y: worldBounds.top}, {x: worldBounds.right, y: worldBounds.bottom}]
    @surface.camera.setBounds(bounds)
    @surface.camera.zoomTo({x: 0, y: 0}, 0.1, 0)
    @listenTo @surface, 'resize', ({ height }) ->
      @$('#how-to-play-game-dev-panel').css({ height })

  findPlayerNames: ->
    return {} unless @level.isType('ladder', 'hero-ladder', 'course-ladder')
    playerNames = {}
    for session in [@session, @otherSession] when session?.get('team')
      playerNames[session.get('team')] = utils.getCorrectName(session)
    playerNames

  # Once Surface is Loaded ####################################################

  onLevelStarted: ->
    return unless @surface? or @webSurface?
    @loadingView.showReady()
    @trackLevelLoadEnd()
    if window.currentModal and not window.currentModal.destroyed and [VictoryModal, CourseVictoryModal, HeroVictoryModal].indexOf(window.currentModal.constructor) is -1
      return Backbone.Mediator.subscribeOnce 'modal:closed', @onLevelStarted, @
    @surface?.showLevel()
    Backbone.Mediator.publish 'level:set-time', time: 0
    if (@isEditorPreview or @observing) and not utils.getQueryVariable('intro')
      @loadingView.startUnveiling()
      @loadingView.unveil true
    else
      $(window).trigger 'resize'
      @scriptManager?.initializeCamera()

  onLoadingViewUnveiling: (e) ->
    @unveiling = true
    @selectHero()

  onLoadingViewUnveiled: (e) ->
    @unveiling = false
    @unveiled = true
    if @level.isType('course-ladder', 'hero-ladder', 'ladder') or @observing
      # We used to autoplay by default, but now we only do it if the level says to in the introduction script.
      Backbone.Mediator.publish 'level:set-playing', playing: true
    @loadingView.$el.remove()
    @removeSubView @loadingView
    @loadingView = null
    @playAmbientSound()
    # TODO: Is it possible to create a Mongoose ObjectId for 'ls', instead of the string returned from get()?
    application.tracker?.trackEvent 'Started Level', category:'Play Level', label: @levelID, levelID: @levelID, ls: @session?.get('_id') unless @observing or @isEditorPreview
    $(window).trigger 'resize'
    _.delay (=> @perhapsStartSimulating?()), 10 * 1000

  onSetVolume: (e) ->
    createjs.Sound.volume = if e.volume is 1 then 0.6 else e.volume  # Quieter for now until individual sound FX controls work again.
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
    @surface?.focusOnHero()

  perhapsStartSimulating: ->
    return unless @shouldSimulate()
    languagesToLoad = ['javascript', 'python', 'coffeescript', 'lua']  # java, cpp
    for language in languagesToLoad
      do (language) =>
        loadAetherLanguage(language).then (aetherLang) =>
          languagesToLoad = _.without languagesToLoad, language
          if not languagesToLoad.length
            @simulateNextGame()

  simulateNextGame: ->
    return @simulator.fetchAndSimulateOneGame() if @simulator
    simulatorOptions = background: true, leagueID: @courseInstanceID
    simulatorOptions.levelID = @level.get('slug') if @level.isLadder()
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
    return true if utils.getQueryVariable('simulate') is true
    return false  # Disabled due to unresolved crashing issues
    return false if utils.getQueryVariable('simulate') is false
    return false if @isEditorPreview
    defaultCores = 2
    cores = window.navigator.hardwareConcurrency or defaultCores  # Available on Chrome/Opera, soon Safari
    defaultHeapLimit = 793000000
    heapLimit = window.performance?.memory?.jsHeapSizeLimit or defaultHeapLimit  # Only available on Chrome, basically just says 32- vs. 64-bit
    gamesSimulated = me.get('simulatedBy')
    console.debug "Should we start simulating? Cores:", window.navigator.hardwareConcurrency, "Heap limit:", window.performance?.memory?.jsHeapSizeLimit, "Load duration:", @loadDuration
    return false unless $.browser?.desktop
    return false if $.browser?.msie or $.browser?.msedge
    return false if $.browser.linux
    return false if me.level() < 8
    return false if @level.get('slug') in ['zero-sum', 'ace-of-coders', 'elemental-wars']
    if @level.isType('course', 'game-dev', 'web-dev')
      return false
    else if @level.isType('hero') and gamesSimulated
      return false if cores < 8
      return false if heapLimit < defaultHeapLimit
      return false if @loadDuration > 10000
    else if @level.isType('hero-ladder') and gamesSimulated
      return false if cores < 4
      return false if heapLimit < defaultHeapLimit
      return false if @loadDuration > 15000
    else if @level.isType('hero-ladder') and not gamesSimulated
      return false if cores < 8
      return false if heapLimit <= defaultHeapLimit
      return false if @loadDuration > 12000
    else if @level.isType('course-ladder')
      return false if cores <= defaultCores
      return false if heapLimit < defaultHeapLimit
      return false if @loadDuration > 18000
    else if @level.isType('ladder')
      return false if cores <= defaultCores
      return false if heapLimit < defaultHeapLimit
      return false if @loadDuration > 18000
    else
      console.warn "Unwritten level type simulation heuristics; fill these in for new level type #{@level.get('type')}?"
      return false if cores < 8
      return false if heapLimit < defaultHeapLimit
      return false if @loadDuration > 10000
    console.debug "We should have the power. Begin background ladder simulation."
    true

  # callbacks

  onCtrlS: (e) ->
    e.preventDefault()

  onEscapePressed: (e) ->
    if @$el.hasClass 'real-time'
      Backbone.Mediator.publish 'playback:stop-real-time-playback', {}
    else if @$el.hasClass 'cinematic'
      Backbone.Mediator.publish 'playback:stop-cinematic-playback', {}

  onLevelReloadFromData: (e) ->
    isReload = Boolean @world
    if isReload
      # Make sure to share any models we loaded that the parent didn't, like hero equipment, in case the parent relodaed
      e.supermodel.registerModel model for url, model of @supermodel.models when not e.supermodel.models[url]
    @setLevel e.level, e.supermodel
    if isReload
      @scriptManager.setScripts(e.level.get('scripts'))
      @updateGoals e.level.get('goals')
      Backbone.Mediator.publish 'tome:cast-spell', {}  # a bit hacky

  onLevelReloadThangType: (e) ->
    tt = e.thangType
    for url, model of @supermodel.models
      if model.id is tt.id
        for key, val of tt.attributes
          model.attributes[key] = val
        break
    Backbone.Mediator.publish 'tome:cast-spell', {}

  onWindowResize: (e) =>
    @endHighlight()
    # See CodeCombat Devices x Layouts spreadsheet https://docs.google.com/spreadsheets/d/1AJ4vh-XwYF95RW0QLBXEGyi-xqVET6qCcaqyT_PZLJ4/edit#gid=0
    windowWidth = $(window).innerWidth()
    windowHeight = $(window).innerHeight()
    windowAspectRatio = windowWidth / windowHeight
    canvasAspectRatio = 924 / 589
    # TODO: set the cinematic class here, depending on whether we are running, rather than setting it elsewhere and then deciding whether to do anything with it here and in CSS
    product = @level?.get('product', true) or 'codecombat'
    cinematic = product is 'codecombat' and @$el.hasClass('cinematic') and (windowAspectRatio < 2 or windowWidth <= 1366) and windowAspectRatio > 1
    tomeLocation = switch
      when @level?.isType('web-dev') then 'right'
      when windowAspectRatio < 1 then 'bottom'
      when windowAspectRatio < 1.35 and @codeFormat is 'blocks-and-code' and not cinematic then 'bottom'
      else 'right'
    workspaceLocation = switch
      when not /blocks/.test(@codeFormat) then 'none'
      when tomeLocation is 'bottom' and @codeFormat is 'blocks-and-code' then 'bottom-middle-third'
      when tomeLocation is 'bottom' and @codeFormat isnt 'blocks-and-code' then 'bottom-left-half'
      when cinematic then 'full-cinematic'
      when @codeFormat is 'blocks-and-code' then 'middle-third'
      else 'left-half'
    toolboxLocation = switch
      when not /blocks/.test(@codeFormat) or cinematic then 'none'
      when tomeLocation is 'bottom' and @codeFormat is 'blocks-and-code' then 'bottom-right-third'
      when tomeLocation is 'bottom' and @codeFormat isnt 'blocks-and-code' then 'bottom-right-half'
      when @codeFormat is 'blocks-and-code' then 'right-third'
      else 'right-half'
    spellPaletteLocation = switch
      when /blocks/.test(@codeFormat) or cinematic then 'none'
      else 'bottom'
    codeLocation = switch
      when @codeFormat is 'blocks-and-code' and cinematic then 'none'
      when @codeFormat is 'blocks-and-code' and tomeLocation is 'bottom' then 'bottom-left-third'
      when @codeFormat is 'blocks-and-code' then 'left-third'
      when @codeFormat is 'text-code' and cinematic then 'full-cinematic'
      when @codeFormat is 'text-code' and not cinematic then 'full'
      else 'none'
    playButtonLocation = switch
      when tomeLocation is 'bottom' then 'bottom-left'
      when spellPaletteLocation is 'bottom' then 'middle'
      else 'bottom'
    minTomeHeight = switch
      when cinematic then Math.max(windowHeight * 0.15, 150)
      else Math.max(windowHeight * 0.25, 250)
    hasManyAPIs = @tome?.spellPaletteView?.entries?.length > 16
    # Used to think min/max/desired code/workspace/toolbox width would be handled here, but actually currently SpellView is figuring that out and changing block zoom levels as needed.
    # Future work could be to also change font size and to move the relevant logic just to one place.
    minCodeChars = @tome?.spellView?.codeChars?.desired  # Also have min available. TODO: be smart here about min vs. desired based on how much space we have
    minCodeChars ?= switch
      when @level?.isType('web-dev') then 80
      # CoCo Jr might have a line like "for (let i = 0; i < 5; ++i) {"
      when product is 'codecombat-junior' then 28
      # Cinematic playback probably doesn't need to show long lines at full width, especially comments
      when cinematic then 40
      # 85% of CodeCombat solution lines are under 60 characters; longer ones are mostly comments, Java/C++, or advanced
      else 60
    maxCodeChars = @tome?.spellView?.codeChars?.max
    maxCodeChars ?= if product is 'codecombat-junior' then 40 else 80
    minCodeCharWidth = 410.47 / 57 # 7.201px, measured at default font size. Can we get down to 5 if we shrink, on small screens? Don't want to shrink on large screens.
    maxCodeCharWidth = 24  # TODO: test and measure this, correlate to a font size
    acePaddingGutterAndMargin = 30 + 41 + 30  # 30px left and right padding, 41px gutter with 10-99 lines of code
    minCodeWidth = if codeLocation is 'none' then 0 else minCodeChars * minCodeCharWidth + acePaddingGutterAndMargin
    maxCodeWidth = if codeLocation is 'none' then 0 else maxCodeChars * maxCodeCharWidth + acePaddingGutterAndMargin
    if minCodeWidth and hasManyAPIs and @codeFormat is 'text-code' and not @level?.isType('web-dev')
      spellPaletteColumnWidth = 137
      spellPaletteMargin = 54
      minimumSpellPaletteColumns = 3
      if @tome?.spellPaletteView?.entries?.length > 32 and windowWidth >= 1480 and windowAspectRatio >= 1.8
        # We have a _lot_ of APIs and the window is very wide, so make sure to have even more spell palette columns
        minimumSpellPaletteColumns = 4
      minCodeWidth = Math.max minCodeWidth, spellPaletteColumnWidth * minimumSpellPaletteColumns + spellPaletteMargin
      maxCodeWidth = Math.max maxCodeWidth, minCodeWidth
    minBlockChars = switch
      when @codeFormat is 'blocks-icons' and product is 'codecombat-junior' then 4
      when @codeFormat is 'blocks-icons' and cinematic then 6
      when @codeFormat is 'blocks-icons' then 7
      when product is 'codecombat-junior' then 30
      else 35
    maxBlockChars = switch
      when @codeFormat is 'blocks-icons' and tomeLocation is 'bottom' then 15
      when @codeFormat is 'blocks-icons' and product is 'codecombat-junior' then 8
      when @codeFormat is 'blocks-icons' and product is 'codecombat' then 10
      when product is 'codecombat-junior' then 40
      else 50
    minBlockCharWidth = if @codeFormat is 'blocks-icons' then 50 else 10
    maxBlockCharWidth = if @codeFormat is 'blocks-icons' then 70 else 15
    minWorkspaceWidth = @tome?.spellView?.workspaceWidth?.desired
    minWorkspaceWidth ?= if workspaceLocation is 'none' then 0 else minBlockChars * minBlockCharWidth
    maxWorkspaceWidth = @tome?.spellView?.workspaceWidth?.max
    maxWorkspaceWidth ?= if workspaceLocation is 'none' then 0 else maxBlockChars * maxBlockCharWidth
    minToolboxWidth = @tome?.spellView?.toolboxWidth?.desired
    minToolboxWidth ?= if toolboxLocation is 'none' then 0 else minBlockChars * minBlockCharWidth
    maxToolboxWidth = @tome?.spellView?.toolboxWidth?.max
    maxToolboxWidth ?= if toolboxLocation is 'none' then 0 else maxBlockChars * maxBlockCharWidth
    if not @unveiling and not @unveiled
      # Just take up 43.5% of the right side of the screen; that's where level goals will be
      minCodeWidth = 0.435 * windowWidth
      minWorkspaceWidth = minToolboxWidth = 0
    if @level?.isType('game-dev') and @$el.hasClass 'real-time'
      # Game dev don't show the editor during playback
      minCodeWidth = maxCodeWidth = minWorkspaceWidth = maxWorkspaceWidth = minToolboxWidth = maxToolboxWidth = 0
    else if @$el.hasClass('real-time')  # and $el.hasClass('flags')
      # Real-time submission (during flag levels or otherwise)
      minCodeWidth = maxCodeWidth = minWorkspaceWidth = maxWorkspaceWidth = minToolboxWidth = maxToolboxWidth = 0

    # Now determine if we should put the control bar as 'none', 'top', 'left', or 'right'.
    # Right vs. left: put it on the right, unless it would lead to empty space below the canvas.
    canvasHeightWhenControlBarRight = Math.min(windowHeight, (windowWidth - minCodeWidth - minWorkspaceWidth - minToolboxWidth) / canvasAspectRatio)
    canvasWidthWhenControlBarRight = canvasHeightWhenControlBarRight * canvasAspectRatio
    tomeWidthWhenControlBarRight = windowWidth - canvasWidthWhenControlBarRight
    emptyHeightBelowCanvasWhenControlBarRight = windowHeight - canvasHeightWhenControlBarRight
    controlBarLocation = switch
      when @level?.isType('web-dev') then 'left'
      when cinematic then 'none'
      when tomeLocation is 'bottom' then 'top'
      when hasManyAPIs then 'left'  # Make more space for APIs
      when tomeWidthWhenControlBarRight > 160 and emptyHeightBelowCanvasWhenControlBarRight <= 0 then 'right'
      else 'left'
    controlBarHeight = if cinematic then 0 else 50
    canvasHeight = switch
      when @level?.isType('web-dev') then windowHeight - controlBarHeight
      when tomeLocation is 'bottom' then Math.min(windowHeight - minTomeHeight - controlBarHeight, windowWidth / canvasAspectRatio)
      else Math.min(windowHeight - (if controlBarLocation is 'left' then controlBarHeight else 0), (windowWidth - minCodeWidth - minWorkspaceWidth - minToolboxWidth) / canvasAspectRatio)
    desiredCanvasWidth = canvasHeight * canvasAspectRatio
    if me.get('aceConfig')?.preferWideEditor or features?.china
      if windowWidth - desiredCanvasWidth < 500 and tomeLocation is 'right'
        # windowWidth / 1.82 get 55% of the screen width for canvas -- our old style
        # windowWidth - 500 get 500px for editor so won't get a really narrow editor
        canvasWidth =  Math.max(windowWidth / 1.82, windowWidth - 500)
      else
        canvasWidth = desiredCanvasWidth
      if @$el.hasClass('real-time') and @level?.isType('game-dev')
        # how-to-play-game-dev-panel width is 20%
        canvasWidth = Math.min(windowWidth * 0.8, desiredCanvasWidth)
      canvasHeight = canvasWidth / canvasAspectRatio
    else
      canvasWidth = switch
        when @level?.isType('game-dev') and @$el.hasClass('real-time') then Math.min(windowWidth * 0.8, desiredCanvasWidth)
        when @level?.isType('web-dev') then windowWidth - minCodeWidth
        else desiredCanvasWidth
    emptyHeightBelowCanvas = switch
      when tomeLocation is 'bottom' then 0
      else windowHeight - canvasHeight - (if controlBarLocation is 'left' then controlBarHeight else 0)
    emptyWidthLeftOfCanvas = switch
      when tomeLocation is 'right' then 0
      else (windowWidth - canvasWidth) / 2
    controlBarWidth = switch
      when controlBarLocation in ['none', 'left'] then canvasWidth
      when controlBarLocation is 'right' then windowWidth - canvasWidth
      else windowWidth
    controlBarLeft = if controlBarLocation is 'right' then canvasWidth else 0
    tomeOverlap = 6
    tomeWidth = if tomeLocation is 'right' then windowWidth - canvasWidth + tomeOverlap else windowWidth
    tomeHeight = switch
      when tomeLocation is 'bottom' then windowHeight - canvasHeight - controlBarHeight
      when cinematic then windowHeight
      when controlBarLocation in ['right', 'top'] then windowHeight - controlBarHeight
      else windowHeight
    tomeTop = switch
      when tomeLocation is 'bottom' then controlBarHeight + canvasHeight
      when controlBarLocation is 'right' then 50
      else 0
    playButtonHeight = 46
    workspaceWidth = switch
      when workspaceLocation is 'none' then 0
      when workspaceLocation in ['left-half', 'bottom-left-half'] then tomeWidth - minToolboxWidth
      when workspaceLocation in ['middle-third', 'bottom-middle-third'] then (minWorkspaceWidth / (minWorkspaceWidth + minCodeWidth)) * (tomeWidth - minToolboxWidth)
      else tomeWidth
    workspaceHeight = if workspaceLocation is 'none' then 0 else tomeHeight - playButtonHeight
    toolboxWidth = switch
      when toolboxLocation is 'none' then 0
      when toolboxLocation in ['right-half', 'bottom-right-half'] then minToolboxWidth
      else minToolboxWidth
    toolboxHeight = if toolboxLocation is 'none' then 0 else tomeHeight - playButtonHeight
    spellPaletteWidth = if spellPaletteLocation is 'none' then 0 else tomeWidth
    spellPaletteHeight = if spellPaletteLocation is 'none' then 0 else 150  # TODO: real spell palette height
    codeWidth = switch
      when codeLocation is 'none' then 0
      when codeLocation in ['left-third', 'bottom-left-third'] then tomeWidth - workspaceWidth - toolboxWidth
      else tomeWidth
    codeHeight = if codeLocation is 'none' then 0 else tomeHeight - playButtonHeight
    playbackLocation = if emptyHeightBelowCanvas > 15 then 'below' else 'bottom'
    playbackHeight = 60  # Technically it's 60, it has funky margins and padding though for some overlap
    playbackTopMargin = Math.min(emptyHeightBelowCanvas - 58, -5)
    hudLocation = if emptyHeightBelowCanvas > 60 then 'below' else 'none'
    footerTop = switch
      when tomeLocation is 'bottom' then controlBarHeight + canvasHeight
      when controlBarLocation is 'right' then canvasHeight + playbackHeight + playbackTopMargin
      when @level?.isType('web-dev') then controlBarHeight + canvasHeight
      else controlBarHeight + canvasHeight + playbackHeight + playbackTopMargin
    footerShadowTop = switch
      when @level?.isType('web-dev') then footerTop - 10
      when playbackLocation is 'bottom' then footerTop - 10
      else footerTop
    duelStatsLeft = (canvasWidth - 500) / 2
    duelStatsTop = canvasHeight - 60 + (if playbackLocation is 'below' then playbackTopMargin else -32)
    dialogueLeft = if tomeLocation is 'bottom' then (canvasWidth - 417) / 2 else canvasWidth - 417 - 50
    levelChatBottom = if controlBarLocation is 'right' then 40 else 5
    gameDevTrackRight = windowWidth - canvasWidth + 12
    stopRealTimePlaybackTop = canvasHeight - 30 - (if controlBarLocation is 'right' then 50 else 0)

    # console.log 'Calculated PlayLevelView dimensions', { @codeFormat, windowWidth, windowHeight, canvasAspectRatio, minCodeChars, maxCodeChars, minCodeCharWidth, maxCodeCharWidth, minCodeWidth, maxCodeWidth, minBlockChars, maxBlockChars, minBlockCharWidth, maxBlockCharWidth, minWorkspaceWidth, maxWorkspaceWidth, minToolboxWidth, maxToolboxWidth, controlBarLocation, controlBarHeight, canvasHeight, canvasWidth, emptyHeightBelowCanvas, emptyWidthLeftOfCanvas, controlBarWidth, controlBarLeft, tomeOverlap, tomeWidth, tomeHeight, tomeTop, playButtonHeight, workspaceWidth, workspaceHeight, toolboxWidth, toolboxHeight, spellPaletteWidth, spellPaletteHeight, codeWidth, codeHeight, playbackLocation, playbackHeight, playbackTopMargin, hudLocation, footerTop, footerShadowTop, duelStatsLeft, duelStatsTop }

    @$el[0].dataset.tomeLocation = tomeLocation
    @$el[0].dataset.workspaceLocation = workspaceLocation
    @$el[0].dataset.toolboxLocation = toolboxLocation
    @$el[0].dataset.spellPaletteLocation = spellPaletteLocation
    @$el[0].dataset.codeLocation = codeLocation
    @$el[0].dataset.playButtonLocation = playButtonLocation
    @$el[0].dataset.controlBarLocation = controlBarLocation
    @$el[0].dataset.playbackLocation = playbackLocation
    @$el[0].dataset.hudLocation = hudLocation

    # Set the widths, heights, and positions on the appropriate elements
    @$el.find('#canvas-wrapper').css width: canvasWidth, height: canvasHeight, left: emptyWidthLeftOfCanvas
    @$el.find('#level-footer-shadow').css top: footerShadowTop
    @$el.find('#control-bar-view').css width: controlBarWidth, height: controlBarHeight, left: controlBarLeft
    @$el.find('#playback-view').css width: canvasWidth, marginTop: playbackTopMargin
    @$el.find('#thang-hud').css width: canvasWidth
    @$el.find('#thang-hud .center').css maxWidth: canvasWidth
    @$el.find('#gold-view').css right: windowWidth - canvasWidth + 12, top: 12
    @$el.find('#code-area').css width: tomeWidth, height: tomeHeight, top: tomeTop
    @$el.find('#solution-area').css right: tomeWidth, width: tomeWidth, height: tomeHeight, top: tomeTop, bottom: 'unset', left: 'unset'
    @$el.find('#solution-area').css right: 'unset', left: '-54px', top: 0, width: tomeWidth, height: 'auto' if tomeLocation is 'bottom'
    @$el.find('#code-area #tome-view #spell-view .ace_editor').css width: codeWidth if /blocks/.test(@codeFormat)  # Let handle own height, and width if there are no blocks
    @$el.find('#solution-area .ace_editor').css width: codeWidth if /blocks/.test(@codeFormat)  # do we need blocks hint?
    @$el.find('#code-area #tome-view #spell-view .blockly-container').css width: workspaceWidth + toolboxWidth, height: workspaceHeight, left: codeWidth
    @$el.find('#duel-stats-view').css left: duelStatsLeft, top: duelStatsTop
    @$el.find('#level-dialogue-view').css left: dialogueLeft
    @$el.find('#level-chat-view').css bottom: levelChatBottom
    @$el.find('#game-dev-track-view').css right: gameDevTrackRight, top: 12
    @$el.find('#stop-real-time-playback-button').css top: stopRealTimePlaybackTop

    # TODO: figure out how to get workspace and toolbox to share width evenly

    # TODO: set the font sizes on the appropriate elements (probably in SpellView)

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

  onShowVictory: (e={}) ->
    $('#level-done-button').show() unless @level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev', 'ladder')  # TODO: do we ever use this? Should remove if not.
    @showVictory(_.pick(e, 'manual')) if e.showModal
    return if @victorySeen
    @victorySeen = true
    victoryTime = (new Date()) - @loadEndTime
    if not @observing and not @isEditorPreview and victoryTime > 10 * 1000   # Don't track it if we're reloading an already-beaten level
      application.tracker?.trackEvent 'Saw Victory',
        category: 'Play Level'
        level: @level.get('name')
        label: @level.get('name')
        levelID: @levelID
        ls: @session?.get('_id')
        playtime: @session?.get('playtime')
      application.tracker?.trackTiming victoryTime, 'Level Victory Time', @levelID, @levelID

  showVictory: (options={}) ->
    return if @level.hasLocalChanges()  # Don't award achievements when beating level changed in level editor
    return if @level.isType('game-dev') and @level.get('shareable') and not options.manual
    return if @showVictoryHandlingInProgress
    @showVictoryHandlingInProgress=true
    @endHighlight()
    options = {level: @level, supermodel: @supermodel, session: @session, hasReceivedMemoryWarning: @hasReceivedMemoryWarning, courseID: @courseID, courseInstanceID: @courseInstanceID, world: @world, parent: @}
    ModalClass = if @level.isType('hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev', 'ladder') then HeroVictoryModal else VictoryModal
    ModalClass = CourseVictoryModal if @isCourseMode() or me.isSessionless()
    if @level.isType('course-ladder') or @level.isType('ladder') and @courseInstanceID
      ModalClass = CourseVictoryModal
      options.courseInstanceID = utils.getQueryVariable('course-instance') or utils.getQueryVariable('league')
    ModalClass = PicoCTFVictoryModal if window.serverConfig.picoCTF
    victoryModal = new ModalClass(options)
    @openModalView(victoryModal)
    victoryModal.once 'hidden', =>
      @showVictoryHandlingInProgress=false

    if me.get('anonymous')
      window.nextURL = '/play/' + (@level.get('campaign') ? '')  # Signup will go here on completion instead of reloading.

  onRestartLevel: ->
    @tome.reloadAllCode()
    Backbone.Mediator.publish 'level:restarted', {}
    $('#level-done-button', @$el).hide()
    application.tracker?.trackEvent 'Confirmed Restart', category: 'Play Level', level: @level.get('name'), label: @level.get('name') unless @observing or @isEditorPreview

  onInfiniteLoop: (e) ->
    return unless e.firstWorld and e.god is @god
    @openModalView new InfiniteLoopModal nonUserCodeProblem: e.nonUserCodeProblem, problem: e.problem, timedOut: e.timedOut
    application.tracker?.trackEvent 'Saw Initial Infinite Loop', category: 'Play Level', level: @level.get('name'), label: @level.get('name') unless @observing or @isEditorPreview

  onHighlightDOM: (e) -> @highlightElement e.selector, delay: e.delay, sides: e.sides, offset: e.offset, rotation: e.rotation

  onEndHighlight: -> @endHighlight()

  onFocusDom: (e) -> $(e.selector).focus()

  onContactClicked: (e) ->
    if me.isStudent()
      console.error("Student clicked contact modal.")
      return
    Backbone.Mediator.publish 'level:contact-button-pressed', {}
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

  onSurfaceContextMenu: (e) ->
    e?.preventDefault?()
    return if @$el.hasClass 'real-time'
    return unless @surface.showCoordinates and ( navigator.clipboard or document.queryCommandSupported('copy') )
    pos = x: e.clientX, y: e.clientY
    wop = @surface.coordinateDisplay.lastPos
    Backbone.Mediator.publish 'level:surface-context-menu-pressed', posX: pos.x, posY: pos.y, wopX: wop.x, wopY: wop.y


  # Dynamic sound loading

  onNewWorld: (e) ->
    return if @headless
    scripts = @world.scripts  # Since these worlds don't have scripts, preserve them.
    @world = e.world

    # without this check, when removing goals, goals aren't updated properly. Make sure we update
    # the goals once the first frame is finished.
    if @world.age > 0 and @willUpdateStudentGoals
      @willUpdateStudentGoals = false
      @updateStudentGoals()
      @updateLevelName()

    @world.scripts = scripts
    thangTypes = @supermodel.getModels(ThangType)
    startFrame = @lastWorldFramesLoaded ? 0
    finishedLoading = @world.frames.length is @world.totalFrames
    @realTimePlaybackWaitingForFrames = false
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
    if @level.isType('game-dev', 'hero', 'course')
      @session.updateKeyValueDb(e.keyValueDb)

  # Real-time playback
  onRealTimePlaybackStarted: (e) ->
    @$el.addClass('real-time').focus()
    @willUpdateStudentGoals = true
    @updateStudentGoals()
    @updateLevelName()
    @onWindowResize()
    @realTimePlaybackWaitingForFrames = true

  updateStudentGoals: ->
    return unless @level.isType('game-dev')
    # Set by users. Defined in `game.GameUI` component in the level editor.
    if @world.uiText?.directions?.length
      @studentGoals = @world.uiText.directions.map((direction) -> {type: "user_defined", direction})
    else
      @studentGoals = @world.thangMap['Hero Placeholder'].stringGoals?.map((g) -> JSON.parse(g))
    @renderSelectors('#how-to-play-game-dev-panel')
    @$('#how-to-play-game-dev-panel').removeClass('hide')

  updateKeyValueDb: ->
    return unless @world?.keyValueDb
    @session.updateKeyValueDb _.cloneDeep(@world.keyValueDb)
    @session.saveKeyValueDb()

  updateLevelName: () ->
    if @world.uiText?.levelName
      @controlBar.setLevelName(@world.uiText.levelName)

  onRealTimePlaybackEnded: (e) ->
    return unless @$el.hasClass 'real-time'
    @$('#how-to-play-game-dev-panel').addClass('hide') if @level.isType('game-dev')
    @$el.removeClass 'real-time'
    @onWindowResize()
    if @level.isType('game-dev', 'hero', 'course')
      @session.saveKeyValueDb()
    if @world.frames.length is @world.totalFrames and not @surface.countdownScreen?.showing and not @realTimePlaybackWaitingForFrames
      _.delay @onSubmissionComplete, 750  # Wait for transition to end.
    else
      @waitingForSubmissionComplete = true

  # Cinematice playback
  onCinematicPlaybackStarted: (e) ->
    @$el.addClass('cinematic').focus()
    @onWindowResize()

  onCinematicPlaybackEnded: (e) ->
    return unless @$el.hasClass 'cinematic'
    @$el.removeClass 'cinematic'
    @onWindowResize()

  onSubmissionComplete: =>
    return if @destroyed
    Backbone.Mediator.publish 'level:set-time', ratio: 1
    return if @level.hasLocalChanges()  # Don't award achievements when beating level changed in level editor
    if @goalManager.checkOverallStatus() is 'success'
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
    if @checkTournamentEndInterval
      clearInterval @checkTournamentEndInterval
    Backbone.Mediator.unsubscribe 'modal:closed', @onLevelStarted, @
    Backbone.Mediator.unsubscribe 'audio-player:loaded', @playAmbientSound, @
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

  onCloseSolution: ->
    Backbone.Mediator.publish 'level:close-solution', {}

  getLoadTrackingTag: () ->
    @level?.get 'slug'

  onRunCode: ->
    @updateKeyValueDb()
    store.commit('game/incrementTimesCodeRun')

  onCodeFormatChanged: (e) ->
    @codeFormat = e.codeFormat
    if e.oldCodeFormat
      @$el.removeClass(e.oldCodeFormat)
    @$el.addClass(e.codeFormat)
