View = require 'views/kinds/RootView'
template = require 'templates/play/level'
{me} = require('lib/auth')
ThangType = require 'models/ThangType'
utils = require 'lib/utils'

# temp hard coded data
World = require 'lib/world/world'

# tools
Surface = require 'lib/surface/Surface'
God = require 'lib/God'
GoalManager = require 'lib/world/GoalManager'
ScriptManager = require 'lib/scripts/ScriptManager'
LevelBus = require('lib/LevelBus')
LevelLoader = require 'lib/LevelLoader'
LevelSession = require 'models/LevelSession'
Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
Article = require 'models/Article'
Camera = require 'lib/surface/Camera'
AudioPlayer = require 'lib/AudioPlayer'

# subviews
LoadingView = require './level/level_loading_view'
TomeView = require './level/tome/tome_view'
ChatView = require './level/level_chat_view'
HUDView = require './level/hud_view'
ControlBarView = require './level/control_bar_view'
PlaybackView = require './level/playback_view'
GoalsView = require './level/goals_view'
GoldView = require './level/gold_view'
VictoryModal = require './level/modal/victory_modal'
InfiniteLoopModal = require './level/modal/infinite_loop_modal'

PROFILE_ME = false

module.exports = class PlayLevelView extends View
  id: 'level-view'
  template: template
  cache: false
  shortcutsEnabled: true
  startsLoading: true
  isEditorPreview: false

  subscriptions:
    'level-set-volume': (e) -> createjs.Sound.setVolume(e.volume)
    'level-show-victory': 'onShowVictory'
    'restart-level': 'onRestartLevel'
    'level-highlight-dom': 'onHighlightDom'
    'end-level-highlight-dom': 'onEndHighlight'
    'level-focus-dom': 'onFocusDom'
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'
    'god:new-world-created': 'onNewWorld'
    'god:infinite-loop': 'onInfiniteLoop'
    'level-reload-from-data': 'onLevelReloadFromData'
    'play-next-level': 'onPlayNextLevel'
    'edit-wizard-settings': 'showWizardSettingsModal'
    'surface:world-set-up': 'onSurfaceSetUpNewWorld'
    'level:session-will-save': 'onSessionWillSave'
    'level:set-team': 'setTeam'
    'god:new-world-created': 'loadSoundsForWorld'
    'level:started': 'onLevelStarted'
    'level:loading-view-unveiled': 'onLoadingViewUnveiled'

  events:
    'click #level-done-button': 'onDonePressed'

  shortcuts:
    'ctrl+s': 'onCtrlS'

  constructor: (options, @levelID) ->
    console.profile?() if PROFILE_ME
    super options
    if not me.get('hourOfCode') and @getQueryVariable "hour_of_code"
      me.set 'hourOfCode', true
      me.save()
      $('body').append($("<img src='http://code.org/api/hour/begin_codecombat.png' style='visibility: hidden;'>"))
      application.tracker?.trackEvent 'Hour of Code Begin', {}

    @isEditorPreview = @getQueryVariable 'dev'
    @sessionID = @getQueryVariable 'session'

    $(window).on('resize', @onWindowResize)
    @listenToOnce(@supermodel, 'error', @onLevelLoadError)
    @saveScreenshot = _.throttle @saveScreenshot, 30000

    if @isEditorPreview
      f = =>
        @supermodel.shouldSaveBackups = (model) ->
          model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem']
        @load() unless @levelLoader
      setTimeout f, 100
    else
      @load()
      application.tracker?.trackEvent 'Started Level Load', level: @levelID, label: @levelID

  onLevelLoadError: (e) ->
    application.router.navigate "/play?not_found=#{@levelID}", {trigger: true}

  setLevel: (@level, @supermodel) ->
    @god?.level = @level.serialize @supermodel
    if @world
      serializedLevel = @level.serialize(@supermodel)
      @world.loadFromLevel serializedLevel, false
    else
      @load()

  load: ->
    @loadStartTime = new Date()
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, sessionID: @sessionID, opponentSessionID: @getQueryVariable('opponent'), team: @getQueryVariable("team")
    @listenToOnce(@levelLoader, 'loaded-all', @onLevelLoaderLoaded)
    @listenTo(@levelLoader, 'progress', @onLevelLoaderProgressChanged)
    @god = new God()

  getRenderData: ->
    c = super()
    c.world = @world
    if me.get('hourOfCode') and me.lang() is 'en-US'
      # Show the Hour of Code footer explanation until it's been more than a day
      elapsed = (new Date() - new Date(me.get('dateCreated')))
      c.explainHourOfCode = elapsed < 86400 * 1000
    c

  afterRender: ->
    window.onPlayLevelViewLoaded? @  # still a hack
    @insertSubView @loadingView = new LoadingView {}
    @$el.find('#level-done-button').hide()
    super()
    $('body').addClass('is-playing')

  onLevelLoaderProgressChanged: ->
    return if @seenDocs
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
    DocsModal = require './level/modal/docs_modal'
    options = {docs: @levelLoader.level.get('documentation'), supermodel: @supermodel}
    @openModalView(new DocsModal(options), true)
    Backbone.Mediator.subscribeOnce 'modal-closed', @onLevelLoaderLoaded, @
    return true

  onLevelLoaderLoaded: ->
    return unless @levelLoader.progress() is 1 # double check, since closing the guide may trigger this early
    @loadingView.showReady()
    if window.currentModal and not window.currentModal.destroyed
      return Backbone.Mediator.subscribeOnce 'modal-closed', @onLevelLoaderLoaded, @

    # Save latest level played in local storage
    if not (@levelLoader.level.get('type') in ['ladder', 'ladder-tutorial'])
      me.set('lastLevel', @levelID)
      me.save()
    @grabLevelLoaderData()
    team = @getQueryVariable("team") ? @world.teamForPlayer(0)
    @loadOpponentTeam(team)
    @god.level = @level.serialize @supermodel
    @god.worldClassMap = @world.classMap
    @setTeam team
    @initSurface()
    @initGoalManager()
    @initScriptManager()
    @insertSubviews ladderGame: (@level.get('type') is "ladder")
    @initVolume()
    @listenTo(@session, 'change:multiplayer', @onMultiplayerChanged)
    @originalSessionState = $.extend(true, {}, @session.get('state'))
    @register()
    @controlBar.setBus(@bus)
    @surface.showLevel()
    if @otherSession
      # TODO: colorize name and cloud by team, colorize wizard by user's color config
      @surface.createOpponentWizard id: @otherSession.get('creator'), name: @otherSession.get('creatorName'), team: @otherSession.get('team')

  grabLevelLoaderData: ->
    @session = @levelLoader.session
    @world = @levelLoader.world
    @level = @levelLoader.level
    @otherSession = @levelLoader.opponentSession
    @levelLoader.destroy()
    @levelLoader = null

  loadOpponentTeam: (myTeam) ->
    opponentSpells = []
    for spellTeam, spells of @session.get('teamSpells') ? @otherSession?.get('teamSpells') ? {}
      continue if spellTeam is myTeam or not myTeam
      opponentSpells = opponentSpells.concat spells

    opponentCode = @otherSession?.get('submittedCode') or {}
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

  onLevelStarted: (e) ->
    @loadingView?.unveil()

  onLoadingViewUnveiled: (e) ->
    @removeSubView @loadingView
    @loadingView = null
    unless @isEditorPreview
      @loadEndTime = new Date()
      loadDuration = @loadEndTime - @loadStartTime
      application.tracker?.trackEvent 'Finished Level Load', level: @levelID, label: @levelID, loadDuration: loadDuration
      application.tracker?.trackTiming loadDuration, 'Level Load Time', @levelID, @levelID

  onSupermodelLoadedOne: =>
    @modelsLoaded ?= 0
    @modelsLoaded += 1
    @updateInitString()

  updateInitString: ->
    return if @surface
    @modelsLoaded ?= 0
    canvas = @$el.find('#surface')[0]
    ctx = canvas.getContext('2d')
    ctx.font="20px Georgia"
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.fillText("Loaded #{@modelsLoaded} thingies",50,50)

  insertSubviews: (subviewOptions) ->
    @insertSubView @tome = new TomeView levelID: @levelID, session: @session, thangs: @world.thangs, supermodel: @supermodel, ladderGame: subviewOptions.ladderGame
    @insertSubView new PlaybackView {}
    @insertSubView new GoalsView {}
    @insertSubView new GoldView {}
    @insertSubView new HUDView {}
    @insertSubView new ChatView levelID: @levelID, sessionID: @session.id, session: @session
    worldName = utils.i18n @level.attributes, 'name'
    @controlBar = @insertSubView new ControlBarView {worldName: worldName, session: @session, level: @level, supermodel: @supermodel, playableTeams: @world.playableTeams, ladderGame: subviewOptions.ladderGame}
    #Backbone.Mediator.publish('level-set-debug', debug: true) if me.displayName() is 'Nick!'

  afterInsert: ->
    super()
    @showWizardSettingsModal() if not me.get('name')

  # callbacks

  onCtrlS: (e) ->
    e.preventDefault()

  onLevelReloadFromData: (e) ->
    isReload = Boolean @world
    @setLevel e.level, e.supermodel
    if isReload
      @scriptManager.setScripts(e.level.get('scripts'))
      Backbone.Mediator.publish 'tome:cast-spell'  # a bit hacky

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
      application.tracker?.trackEvent 'Saw Victory', level: @world.name, label: @world.name
      application.tracker?.trackTiming victoryTime, 'Level Victory Time', @levelID, @levelID, 100

  showVictory: ->
    options = {level: @level, supermodel: @supermodel, session: @session}
    docs = new VictoryModal(options)
    @openModalView(docs)
    if me.get('anonymous')
      window.nextLevelURL = @getNextLevelID()  # Signup will go here on completion instead of reloading.

  onRestartLevel: ->
    @tome.reloadAllCode()
    Backbone.Mediator.publish 'level:restarted'
    $('#level-done-button', @$el).hide()
    application.tracker?.trackEvent 'Confirmed Restart', level: @world.name, label: @world.name

  onNewWorld: (e) ->
    @world = e.world

  onInfiniteLoop: (e) ->
    return unless e.firstWorld
    @openModalView new InfiniteLoopModal()
    application.tracker?.trackEvent 'Saw Initial Infinite Loop', level: @world.name, label: @world.name

  onPlayNextLevel: ->
    nextLevelID = @getNextLevelID()
    nextLevelURL = @getNextLevelURL()
    Backbone.Mediator.publish 'router:navigate', {
      route: nextLevelURL,
      viewClass: PlayLevelView,
      viewArgs: [{supermodel:@supermodel}, nextLevelID]}

  getNextLevel: ->
    nextLevelOriginal = @level.get('nextLevel')?.original
    levels = @supermodel.getModels(Level)
    return l for l in levels when l.get('original') is nextLevelOriginal

  getNextLevelID: ->
    nextLevel = @getNextLevel()
    nextLevelID = nextLevel.get('slug') or nextLevel.id

  getNextLevelURL: -> "/play/level/#{@getNextLevelID()}"

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
    body = $('#level-view')

    if e.sides
      if 'left' in e.sides then target_left = offset.left
      if 'right' in e.sides then target_left = offset.left + dom.outerWidth()
      if 'top' in e.sides then target_top = offset.top
      if 'bottom' in e.sides then target_top = offset.top + dom.outerHeight()
    else
      # aim to hit the side if the target is entirely on one side of the screen
      if offset.left > body.outerWidth()*0.5
        target_left = offset.left
      else if offset.left + dom.outerWidth() < body.outerWidth()*0.5
        target_left = offset.left + dom.outerWidth()

      # aim to hit the bottom or top if the target is entirely on the top or bottom of the screen
      if offset.top > body.outerWidth()*0.5
        target_top = offset.top
      else if  offset.top + dom.outerHeight() < body.outerHeight()*0.5
        target_top = offset.top + dom.outerHeight()

    if e.offset
      target_left += e.offset.x
      target_top += e.offset.y

    @pointerRadialDistance = -47 # - Math.sqrt(Math.pow(dom.outerHeight()*0.5, 2), Math.pow(dom.outerWidth()*0.5))
    @pointerRotation = e.rotation ? Math.atan2(body.outerWidth()*0.5 - target_left, target_top - body.outerHeight()*0.5)
    pointer = $('#pointer')
    pointer
      .css('opacity', 1.0)
      .css('transition', 'none')
      .css('transform', "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance}px)")
      .css('top', target_top - 50)
      .css('left', target_left - 50)
    setTimeout((=>
      @animatePointer()
      clearInterval(@pointerInterval)
      @pointerInterval = setInterval(@animatePointer, 1200)
    ), 1)


  animatePointer: ->
    pointer = $('#pointer')
    pointer.css('transition', 'all 0.6s ease-out')
    pointer.css('transform', "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance-50}px)")
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

  # initialization

  addPointer: ->
    p = $('#pointer')
    return if p.length
    @$el.append($('<img src="/images/level/pointer.png" id="pointer">'))

  initSurface: ->
    surfaceCanvas = $('canvas#surface', @$el)
    @surface = new Surface(@world, surfaceCanvas, thangTypes: @supermodel.getModels(ThangType), playJingle: not @isEditorPreview)
    worldBounds = @world.getBounds()
    bounds = [{x:worldBounds.left, y:worldBounds.top}, {x:worldBounds.right, y:worldBounds.bottom}]
    @surface.camera.setBounds(bounds)
    @surface.camera.zoomTo({x:0, y:0}, 0.1, 0)

  initGoalManager: ->
    @goalManager = new GoalManager(@world, @level.get('goals'))
    @god.goalManager = @goalManager

  initScriptManager: ->
    @scriptManager = new ScriptManager({scripts: @world.scripts or [], view:@, session: @session})
    @scriptManager.loadFromSession()

  initVolume: ->
    volume = me.get('volume')
    volume = 1.0 unless volume?
    Backbone.Mediator.publish 'level-set-volume', volume: volume

  onSurfaceSetUpNewWorld: ->
    return if @alreadyLoadedState
    @alreadyLoadedState = true
    state = @originalSessionState
    if state.frame and @level.get('type') isnt 'ladder'  # https://github.com/codecombat/codecombat/issues/714
      Backbone.Mediator.publish 'level-set-time', { time: 0, frameOffset: state.frame }
    if state.selected
      # TODO: Should also restore selected spell here by saving spellName
      Backbone.Mediator.publish 'level-select-sprite', { thangID: state.selected, spellName: null }
    if state.playing?
      Backbone.Mediator.publish 'level-set-playing', { playing: state.playing }

  preloadNextLevel: =>
    # TODO: Loading models in the middle of gameplay causes stuttering. Most of the improvement in loading time is simply from passing the supermodel from this level to the next, but if we can find a way to populate the level early without it being noticeable, that would be even better.
#    return if @destroyed
#    return if @preloaded
#    nextLevel = @getNextLevel()
#    @supermodel.populateModel nextLevel
#    @preloaded = true

  register: ->
    @bus = LevelBus.get(@levelID, @session.id)
    @bus.setSession(@session)
    @bus.setSpells @tome.spells
    @bus.connect() if @session.get('multiplayer')

  onSessionWillSave: (e) ->
    # Something interesting has happened, so (at a lower frequency), we'll save a screenshot.
    @saveScreenshot e.session

  # Throttled
  saveScreenshot: (session) =>
    return unless screenshot = @surface?.screenshot()
    session.save {screenshot: screenshot}, {patch: true}

  setTeam: (team) ->
    team = team?.team unless _.isString team
    team ?= 'humans'
    me.team = team
    Backbone.Mediator.publish 'level:team-set', team: team

  # Dynamic sound loading

  loadSoundsForWorld: (e) ->
    return if @headless
    world = e.world
    thangTypes = @supermodel.getModels(ThangType)
    for [spriteName, message] in world.thangDialogueSounds()
      continue unless thangType = _.find thangTypes, (m) -> m.get('name') is spriteName
      continue unless sound = AudioPlayer.soundForDialogue message, thangType.get('soundTriggers')
      AudioPlayer.preloadSoundReference sound

  destroy: ->
    @levelLoader?.destroy()
    @surface?.destroy()
    @god?.destroy()
    @goalManager?.destroy()
    @scriptManager?.destroy()
    delete window.world # not sure where this is set, but this is one way to clean it up
    clearInterval(@pointerInterval)
    @bus?.destroy()
    #@instance.save() unless @instance.loading
    delete window.nextLevelURL
    console.profileEnd?() if PROFILE_ME
    super()
