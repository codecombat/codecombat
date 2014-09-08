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
InfiniteLoopModal = require './modal/InfiniteLoopModal'

PROFILE_ME = false

module.exports = class PlayLevelView extends RootView
  id: 'level-view'
  template: template
  cache: false
  shortcutsEnabled: true
  isEditorPreview: false

  subscriptions:
    'level:set-volume': (e) -> createjs.Sound.setVolume(e.volume)
    'level:show-victory': 'onShowVictory'
    'level:restart': 'onRestartLevel'
    'level:highlight-dom': 'onHighlightDom'
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
    'surface:world-set-up': 'onSurfaceSetUpNewWorld'
    'level:session-will-save': 'onSessionWillSave'
    'level:started': 'onLevelStarted'
    'level:loading-view-unveiled': 'onLoadingViewUnveiled'
    'playback:real-time-playback-waiting': 'onRealTimePlaybackWaiting'
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'real-time-multiplayer:joined-game': 'onJoinedRealTimeMultiplayerGame'
    'real-time-multiplayer:left-game': 'onLeftRealTimeMultiplayerGame'
    'real-time-multiplayer:manual-cast': 'onRealTimeMultiplayerCast'
    'level:inventory-changed': 'onInventoryChanged'

  events:
    'click #level-done-button': 'onDonePressed'
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

    serializedLevel = @level.serialize @supermodel, @session
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

  # CocoView overridden methods ###############################################

  updateProgress: (progress) ->
    super(progress)
    return if @seenDocs
    return if @isIPadApp()
    return unless @levelLoader.session.loaded and @levelLoader.level.loaded
    return unless showFrequency = @levelLoader.level.get('showsGuide')
    session = @levelLoader.session
    diff = new Date().getTime() - new Date(session.get('created')).getTime()
    return if showFrequency is 'first-time' and diff > (5 * 60 * 1000)
    articles = @levelLoader.supermodel.getModels Article
    for article in articles
      return unless article.loaded
    @showGuide()

  showGuide: ->
    @seenDocs = true
    LevelGuideModal = require './modal/LevelGuideModal'
    options =
      docs: @levelLoader.level.get('documentation')
      supermodel: @supermodel
      firstOnly: true
    @openModalView(new LevelGuideModal(options), true)
    onGuideOpened = (e) ->
      @guideOpenTime = new Date()
    onGuideClosed = (e) ->
      application.tracker?.trackTiming new Date() - @guideOpenTime, 'Intro Guide Time', @levelID, @levelID, 100
      @onLevelStarted()
    Backbone.Mediator.subscribeOnce 'modal:opened', onGuideOpened, @
    Backbone.Mediator.subscribeOnce 'modal:closed', onGuideClosed, @
    return true

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
    @insertSubView @loadingView = new LevelLoadingView {}
    @$el.find('#level-done-button').hide()
    $('body').addClass('is-playing')
    $('body').bind('touchmove', false) if @isIPadApp()

  afterInsert: ->
    super()
    @showWizardSettingsModal() if not me.get('name') and not @isIPadApp()

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
    @god.setLevel @level.serialize @supermodel, @session
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
    @insertSubView @tome = new TomeView levelID: @levelID, session: @session, otherSession: @otherSession, thangs: @world.thangs, supermodel: @supermodel
    @insertSubView new LevelPlaybackView session: @session
    @insertSubView new GoalsView {}
    @insertSubView new LevelFlagsView world: @world
    @insertSubView new GoldView {}
    @insertSubView new HUDView {}
    @insertSubView new ChatView levelID: @levelID, sessionID: @session.id, session: @session
    worldName = utils.i18n @level.attributes, 'name'
    @controlBar = @insertSubView new ControlBarView {worldName: worldName, session: @session, level: @level, supermodel: @supermodel, playableTeams: @world.playableTeams}
    Backbone.Mediator.publish('level:set-debug', debug: true) if @isIPadApp()  # if me.displayName() is 'Nick'

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

  onLoaded: ->
    _.defer => @onLevelLoaded()

  onLevelLoaded: ->
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
    surfaceCanvas = $('canvas#surface', @$el)
    @surface = new Surface(@world, surfaceCanvas, thangTypes: @supermodel.getModels(ThangType), playJingle: not @isEditorPreview)
    worldBounds = @world.getBounds()
    bounds = [{x: worldBounds.left, y: worldBounds.top}, {x: worldBounds.right, y: worldBounds.bottom}]
    @surface.camera.setBounds(bounds)
    @surface.camera.zoomTo({x: 0, y: 0}, 0.1, 0)

  # Once Surface is Loaded ####################################################

  onLevelStarted: ->
    return unless @surface?
    @loadingView.showReady()
    if window.currentModal and not window.currentModal.destroyed
      return Backbone.Mediator.subscribeOnce 'modal:closed', @onLevelStarted, @
    @surface.showLevel()
    if @otherSession
      # TODO: colorize name and cloud by team, colorize wizard by user's color config
      @surface.createOpponentWizard id: @otherSession.get('creator'), name: @otherSession.get('creatorName'), team: @otherSession.get('team'), levelSlug: @level.get('slug'), codeLanguage: @otherSession.get('submittedCodeLanguage')
    @loadingView?.unveil()

  onLoadingViewUnveiled: (e) ->
    @loadingView.$el.remove()
    @removeSubView @loadingView
    @loadingView = null
    unless @isEditorPreview
      @loadEndTime = new Date()
      loadDuration = @loadEndTime - @loadStartTime
      console.debug "Level unveiled after #{(loadDuration / 1000).toFixed(2)}s"
      application.tracker?.trackEvent 'Finished Level Load', level: @levelID, label: @levelID, loadDuration: loadDuration, ['Google Analytics']
      application.tracker?.trackTiming loadDuration, 'Level Load Time', @levelID, @levelID

  onSurfaceSetUpNewWorld: ->
    return if @alreadyLoadedState
    @alreadyLoadedState = true
    state = @originalSessionState
    if state.frame and @level.get('type') isnt 'ladder'  # https://github.com/codecombat/codecombat/issues/714
      Backbone.Mediator.publish 'level:set-time', time: 0, frameOffset: state.frame
    if state.selected
      # TODO: Should also restore selected spell here by saving spellName
      Backbone.Mediator.publish 'level:select-sprite', thangID: state.selected, spellName: null
    else if @isIPadApp()
      Backbone.Mediator.publish 'tome:select-primary-sprite', {}
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

  onInventoryChanged: (e) ->
    # Doesn't work because the new inventory ThangTypes may not be loaded.
    #@setLevel @level, @supermodel
    #Backbone.Mediator.publish 'tome:cast-spell', {}
    # We'll just make a new PlayLevelView instead
    Backbone.Mediator.publish 'router:navigate', {
      route: window.location.pathname,
      viewClass: PlayLevelView,
      viewArgs: [{supermodel: @supermodel}, @levelID]}

  onWindowResize: (s...) ->
    $('#pointer').css('opacity', 0.0)

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
    $('#level-done-button').show()
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
    docs = new VictoryModal(options)
    @openModalView(docs)
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

  onHighlightDom: (e) ->
    if e.delay
      delay = e.delay
      delete e.delay
      @pointerInterval = _.delay((=> @onHighlightDom e), delay)
      return
    @addPointer()
    selector = e.selector + ':visible'
    dom = $(selector)
    return if parseFloat(dom.css('opacity')) is 0.0
    offset = dom.offset()
    return if not offset
    target_left = offset.left + dom.outerWidth() * 0.5
    target_top = offset.top + dom.outerHeight() * 0.5

    if e.sides
      if 'left' in e.sides then target_left = offset.left
      if 'right' in e.sides then target_left = offset.left + dom.outerWidth()
      if 'top' in e.sides then target_top = offset.top
      if 'bottom' in e.sides then target_top = offset.top + dom.outerHeight()
    else
      # aim to hit the side if the target is entirely on one side of the screen
      if offset.left > @$el.outerWidth()*0.5
        target_left = offset.left
      else if offset.left + dom.outerWidth() < @$el.outerWidth()*0.5
        target_left = offset.left + dom.outerWidth()

      # aim to hit the bottom or top if the target is entirely on the top or bottom of the screen
      if offset.top > @$el.outerWidth()*0.5
        target_top = offset.top
      else if  offset.top + dom.outerHeight() < @$el.outerHeight()*0.5
        target_top = offset.top + dom.outerHeight()

    if e.offset
      target_left += e.offset.x
      target_top += e.offset.y

    @pointerRadialDistance = -47 # - Math.sqrt(Math.pow(dom.outerHeight()*0.5, 2), Math.pow(dom.outerWidth()*0.5))
    @pointerRotation = e.rotation ? Math.atan2(@$el.outerWidth()*0.5 - target_left, target_top - @$el.outerHeight()*0.5)
    pointer = $('#pointer')
    pointer
      .css('opacity', 1.0)
      .css('transition', 'none')
      .css('transform', "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance}px)")
      .css('top', target_top - 50)
      .css('left', target_left - 50)
    setTimeout(()=>
      return if @destroyed
      @animatePointer()
      clearInterval(@pointerInterval)
      @pointerInterval = setInterval(@animatePointer, 1200)
    , 1)

  animatePointer: =>
    pointer = $('#pointer')
    pointer.css('transition', 'all 0.6s ease-out')
    pointer.css('transform', "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance-50}px)")
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'dom_highlight', volume: 0.75
    setTimeout((=>
      pointer.css('transform', "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance}px)").css('transition', 'all 0.4s ease-in')), 800)

  onFocusDom: (e) -> $(e.selector).focus()

  onEndHighlight: ->
    $('#pointer').css('opacity', 0.0)
    clearInterval(@pointerInterval)

  onMultiplayerChanged: (e) ->
    if @session.get('multiplayer')
      @bus.connect()
    else
      @bus.removeFirebaseData =>
        @bus.disconnect()

  addPointer: ->
    p = $('#pointer')
    return if p.length
    @$el.append($('<img src="/images/level/pointer.png" id="pointer">'))

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
    session.save {screenshot: screenshot}, {patch: true}

  # Dynamic sound loading

  onNewWorld: (e) ->
    return if @headless
    scripts = @world.scripts  # Since these worlds don't have scripts, preserve them.
    @world = e.world
    @world.scripts = scripts
    thangTypes = @supermodel.getModels(ThangType)
    startFrame = @lastWorldFramesLoaded ? 0
    if @world.frames.length is @world.totalFrames  # Finished loading
      @lastWorldFramesLoaded = 0
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
    @$el.removeClass 'real-time'
    @onWindowResize()
    @onRealTimeMultiplayerPlaybackEnded()

  destroy: ->
    @levelLoader?.destroy()
    @surface?.destroy()
    @god?.destroy()
    @goalManager?.destroy()
    @scriptManager?.destroy()
    $(window).off 'resize', @onWindowResize
    delete window.world # not sure where this is set, but this is one way to clean it up
    clearInterval(@pointerInterval)
    @bus?.destroy()
    #@instance.save() unless @instance.loading
    delete window.nextLevelURL
    console.profileEnd?() if PROFILE_ME
    super()

  # Real-time Multiplayer ######################################################

  onRealTimeMultiplayerPlaybackEnded: ->
    if @multiplayerSession
      @multiplayerSession.set 'state', 'coding'
      players = new RealTimeCollection('multiplayer_level_sessions/' + @multiplayerSession.id + '/players')
      players.each (player) -> player.set 'state', 'coding' if player.id is me.id

  onJoinedRealTimeMultiplayerGame: (e) ->
    @multiplayerSession = new RealTimeModel('multiplayer_level_sessions/' + e.session.id)

  onLeftRealTimeMultiplayerGame: (e) ->
    if @multiplayerSession
      @multiplayerSession.off()
      @multiplayerSession = null

  onRealTimeMultiplayerCast: (e) ->
    unless @multiplayerSession
      console.error 'onRealTimeMultiplayerCast without a multiplayerSession'
      return
    players = new RealTimeCollection('multiplayer_level_sessions/' + @multiplayerSession.id + '/players')
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
        @onOpponentSubmitted(opponentPlayer, myPlayer)
      else
        # Wait for opponent to submit their code
        opponentPlayer.on 'change', (e) =>
          state = opponentPlayer.get('state')
          if state in ['submitted', 'ready']
            @onOpponentSubmitted(opponentPlayer, myPlayer)

  onOpponentSubmitted: (opponentPlayer, myPlayer) =>
    # Save opponent's code
    Backbone.Mediator.publish 'real-time-multiplayer:new-opponent-code', {codeLanguage: opponentPlayer.get('codeLanguage'), code: opponentPlayer.get('code'), team: opponentPlayer.get('team')}
    # I'm ready to rumble
    myPlayer.set 'state', 'ready'
    if opponentPlayer.get('state') is 'ready'
      console.info 'All real-time multiplayer players are ready!'
      @multiplayerSession.set 'state', 'running'
    else
      # Wait for opponent to be ready
      opponentPlayer.on 'change', (e) =>
        if opponentPlayer.get('state') is 'ready'
          opponentPlayer.off()
          console.info 'All real-time multiplayer players are ready!'
          @multiplayerSession.set 'state', 'running'
