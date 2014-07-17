View = require 'views/kinds/RootView'
template = require 'templates/play/spectate'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
utils = require 'lib/utils'

World = require 'lib/world/world'

# tools
Surface = require 'lib/surface/Surface'
God = require 'lib/God' # 'lib/Buddha'
GoalManager = require 'lib/world/GoalManager'
ScriptManager = require 'lib/scripts/ScriptManager'
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

module.exports = class SpectateLevelView extends View
  id: 'spectate-level-view'
  template: template
  cache: false
  shortcutsEnabled: true
  startsLoading: true
  isEditorPreview: false

  subscriptions:
    'level-set-volume': (e) -> createjs.Sound.setVolume(e.volume)
    'level-highlight-dom': 'onHighlightDom'
    'end-level-highlight-dom': 'onEndHighlight'
    'level-focus-dom': 'onFocusDom'
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'
    'god:new-world-created': 'onNewWorld'
    'god:infinite-loop': 'onInfiniteLoop'
    'level-reload-from-data': 'onLevelReloadFromData'
    'play-next-level': 'onPlayNextLevel'
    'surface:world-set-up': 'onSurfaceSetUpNewWorld'
    'level:set-team': 'setTeam'
    'god:new-world-created': 'loadSoundsForWorld'
    'next-game-pressed': 'onNextGamePressed'
    'level:started': 'onLevelStarted'
    'level:loading-view-unveiled': 'onLoadingViewUnveiled'

  events:
    'click #level-done-button': 'onDonePressed'

  shortcuts:
    'ctrl+s': 'onCtrlS'

  constructor: (options, @levelID) ->
    console.profile?() if PROFILE_ME
    super options
    $(window).on('resize', @onWindowResize)
    @listenToOnce(@supermodel, 'error', @onLevelLoadError)

    @sessionOne = @getQueryVariable 'session-one'
    @sessionTwo = @getQueryVariable 'session-two'
    if options.spectateSessions
      @sessionOne = options.spectateSessions.sessionOne
      @sessionTwo = options.spectateSessions.sessionTwo

    if not @sessionOne or not @sessionTwo
      @fetchRandomSessionPair (err, data) =>
        if err? then return console.log "There was an error fetching the random session pair: #{data}"
        @sessionOne = data[0]._id
        @sessionTwo = data[1]._id
        @load()
    else
      @load()

  onLevelLoadError: (e) =>
    application.router.navigate "/play?not_found=#{@levelID}", {trigger: true}

  setLevel: (@level, @supermodel) ->
    serializedLevel = @level.serialize @supermodel
    @god?.setLevel serializedLevel
    if @world
      @world.loadFromLevel serializedLevel, false
    else
      @load()

  load: ->
    @levelLoader = new LevelLoader
      supermodel: @supermodel
      levelID: @levelID
      sessionID: @sessionOne
      opponentSessionID: @sessionTwo
      spectateMode: true
      team: @getQueryVariable('team')
    @listenToOnce(@levelLoader, 'loaded-all', @onLevelLoaderLoaded)
    @god = new God maxAngels: 1

  getRenderData: ->
    c = super()
    c.world = @world
    c

  afterRender: ->
    window.onPlayLevelViewLoaded? @  # still a hack
    @insertSubView @loadingView = new LoadingView {}
    @$el.find('#level-done-button').hide()
    super()
    $('body').addClass('is-playing')

  updateProgress: (progress) ->
    super(progress)
    return if @seenDocs
    return unless showFrequency = @levelLoader.level.get('showGuide')
    session = @levelLoader.session
    diff = new Date().getTime() - new Date(session.get('created')).getTime()
    return if showFrequency is 'first-time' and diff > (5 * 60 * 1000)
    return unless @levelLoader.level.loaded
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

  onLoaded: ->
    _.defer => @onLevelLoaded()

  onLevelLoaded: ->
    return unless @levelLoader.progress() is 1 # double check, since closing the guide may trigger this early
    # Save latest level played in local storage
    if window.currentModal and not window.currentModal.destroyed
      @loadingView.showReady()
      return Backbone.Mediator.subscribeOnce 'modal-closed', @onLevelLoaderLoaded, @

    @grabLevelLoaderData()
    #at this point, all requisite data is loaded, and sessions are not denormalized
    team = @world.teamForPlayer(0)
    @loadOpponentTeam(team)
    @god.setLevel @level.serialize @supermodel
    @god.setLevelSessionIDs if @otherSession then [@session.id, @otherSession.id] else [@session.id]
    @god.setWorldClassMap @world.classMap
    @setTeam team
    @initSurface()
    @initGoalManager()
    @initScriptManager()
    @insertSubviews()
    @initVolume()

    @originalSessionState = $.extend(true, {}, @session.get('state'))
    @register()
    @controlBar.setBus(@bus)
    @surface.showLevel()
    if me.id isnt @session.get 'creator'
      @surface.createOpponentWizard
        id: @session.get('creator')
        name: @session.get('creatorName')
        team: @session.get('team')
        levelSlug: @level.get('slug')

    @surface.createOpponentWizard
      id: @otherSession.get('creator')
      name: @otherSession.get('creatorName')
      team: @otherSession.get('team')
      levelSlug: @level.get('slug')

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

    opponentCode = @otherSession?.get('transpiledCode') or {}
    myCode = @session.get('transpiledCode') or {}
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
    # Don't remove it; we want its decoration around on large screens.
    #@removeSubView @loadingView
    #@loadingView = null

  onSupermodelLoadedOne: =>
    @modelsLoaded ?= 0
    @modelsLoaded += 1
    @updateInitString()

  updateInitString: ->
    return if @surface
    @modelsLoaded ?= 0
    canvas = @$el.find('#surface')[0]
    ctx = canvas.getContext('2d')
    ctx.font='20px Georgia'
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    ctx.fillText("Loaded #{@modelsLoaded} thingies",50,50)

  insertSubviews: ->
    @insertSubView @tome = new TomeView levelID: @levelID, session: @session, thangs: @world.thangs, supermodel: @supermodel, spectateView: true
    @insertSubView new PlaybackView {}

    @insertSubView new GoldView {}
    @insertSubView new HUDView {}
    worldName = utils.i18n @level.attributes, 'name'
    @controlBar = @insertSubView new ControlBarView {worldName: worldName, session: @session, level: @level, supermodel: @supermodel, playableTeams: @world.playableTeams, spectateGame: true}
  #Backbone.Mediator.publish('level-set-debug', debug: true) if me.displayName() is 'Nick!'

  afterInsert: ->
    super()

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

  onDonePressed: -> return


  onNewWorld: (e) ->
    @world = e.world

  onInfiniteLoop: (e) ->
    return unless e.firstWorld
    @openModalView new InfiniteLoopModal()
    window.tracker?.trackEvent 'Saw Initial Infinite Loop', level: @world.name, label: @world.name

  onPlayNextLevel: ->
    nextLevel = @getNextLevel()
    nextLevelID = nextLevel.get('slug') or nextLevel.id
    url = "/play/level/#{nextLevelID}"
    Backbone.Mediator.publish 'router:navigate', {
      route: url,
      viewClass: PlayLevelView,
      viewArgs: [{supermodel:@supermodel}, nextLevelID]}

  getNextLevel: ->
    nextLevelOriginal = @level.get('nextLevel')?.original
    levels = @supermodel.getModels(Level)
    return l for l in levels when l.get('original') is nextLevelOriginal

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
    @surface = new Surface(@world, surfaceCanvas, thangTypes: @supermodel.getModels(ThangType), playJingle: not @isEditorPreview, spectateGame: true)
    worldBounds = @world.getBounds()
    bounds = [{x:worldBounds.left, y:worldBounds.top}, {x:worldBounds.right, y:worldBounds.bottom}]
    @surface.camera.setBounds(bounds)
    zoom = =>
      @surface.camera.zoomTo({x: (worldBounds.right - worldBounds.left) / 2, y: (worldBounds.top - worldBounds.bottom) / 2}, 0.1, 0)
    _.delay zoom, 4000  # call it later for some reason (TODO: figure this out)

  initGoalManager: ->
    @goalManager = new GoalManager(@world, @level.get('goals'))
    @god.setGoalManager @goalManager

  initScriptManager: ->
    if @world.scripts
      nonVictoryPlaybackScripts = _.reject @world.scripts, (script) ->
        script.id.indexOf('Set Camera Boundaries and Goals') == -1
    else
      console.log 'World scripts don\'t exist!'
      nonVictoryPlaybackScripts = []
    console.log nonVictoryPlaybackScripts
    @scriptManager = new ScriptManager({scripts: nonVictoryPlaybackScripts, view:@, session: @session})
    @scriptManager.loadFromSession()

  initVolume: ->
    volume = me.get('volume')
    volume = 1.0 unless volume?
    Backbone.Mediator.publish 'level-set-volume', volume: volume

  onSurfaceSetUpNewWorld: ->
    return if @alreadyLoadedState
    @alreadyLoadedState = true
    state = @originalSessionState
    if state.playing?
      Backbone.Mediator.publish 'level-set-playing', { playing: state.playing }

  register: -> return

  onSessionWillSave: (e) ->
    # Something interesting has happened, so (at a lower frequency), we'll save a screenshot.
    console.log 'Session is saving but shouldn\'t save!!!!!!!'

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

  onNextGamePressed: (e) ->
    console.log 'You want to see the next game!'
    @fetchRandomSessionPair (err, data) =>
      if err? then return console.log "There was an error fetching the random session pair: #{data}"
      @sessionOne = data[0]._id
      @sessionTwo = data[1]._id
      url = "/play/spectate/#{@levelID}?session-one=#{@sessionOne}&session-two=#{@sessionTwo}"
      Backbone.Mediator.publish 'router:navigate', {
        route: url,
        viewClass: SpectateLevelView,
        viewArgs: [
          {
            spectateSessions: {sessionOne: @sessionOne, sessionTwo: @sessionTwo}
            supermodel: @supermodel
          }
          @levelID
        ]
      }
      history?.pushState? {}, '', url  # Backbone won't update the URL if just query parameters change

  fetchRandomSessionPair: (cb) ->
    console.log 'Fetching random session pair!'
    randomSessionPairURL = "/db/level/#{@levelID}/random_session_pair"
    $.ajax
      url: randomSessionPairURL
      type: 'GET'
      complete: (jqxhr, textStatus) ->
        if textStatus isnt 'success'
          cb('error', jqxhr.statusText)
        else
          cb(null, $.parseJSON(jqxhr.responseText))

  destroy: ()->
    @levelLoader?.destroy()
    @surface?.destroy()
    @god?.destroy()
    $(window).off('resize', @onWindowResize)
    @goalManager?.destroy()
    @scriptManager?.destroy()
    delete window.world # not sure where this is set, but this is one way to clean it up
    clearInterval(@pointerInterval)
    console.profileEnd?() if PROFILE_ME
    super()
