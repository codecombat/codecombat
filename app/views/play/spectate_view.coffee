View = require 'views/kinds/RootView'
template = require 'templates/play/spectate'
{me} = require('lib/auth')
ThangType = require 'models/ThangType'

# temp hard coded data
World = require 'lib/world/world'
docs = require 'lib/world/docs'

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
Camera = require 'lib/surface/Camera'

# subviews
TomeView = require './level/tome/tome_view'
ChatView = require './level/level_chat_view'
HUDView = require './level/hud_view'
ControlBarView = require './level/control_bar_view'
PlaybackView = require './level/playback_view'
GoalsView = require './level/goals_view'
GoldView = require './level/gold_view'
VictoryModal = require './level/modal/victory_modal'
InfiniteLoopModal = require './level/modal/infinite_loop_modal'

LoadingScreen = require 'lib/LoadingScreen'

PROFILE_ME = false

PlayLevelView = require './level_view'

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
    'edit-wizard-settings': 'showWizardSettingsModal'
    'surface:world-set-up': 'onSurfaceSetUpNewWorld'
    'level:session-will-save': 'onSessionWillSave'
    'level:set-team': 'setTeam'

  events:
    'click #level-done-button': 'onDonePressed'


  constructor: (options, @levelID) ->
    console.profile?() if PROFILE_ME
    super options
    console.log @levelID

    @ogreSessionID = @getQueryVariable 'ogres'
    @humanSessionID = @getQueryVariable 'humans'


    $(window).on('resize', @onWindowResize)
    @supermodel.once 'error', =>
      msg = $.i18n.t('play_level.level_load_error', defaultValue: "Level could not be loaded.")
      @$el.html('<div class="alert">' + msg + '</div>')


    @load()



  setLevel: (@level, @supermodel) ->
    @god?.level = @level.serialize @supermodel
    if @world
      serializedLevel = @level.serialize(@supermodel)
      @world.loadFromLevel serializedLevel, false
    else
      @load()

  load: ->
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @levelID, sessionID: @sessionID, opponentSessionID: @getQueryVariable('opponent'), team: @getQueryVariable("team")
    @levelLoader.once 'loaded-all', @onLevelLoaderLoaded
    @god = new God()

  getRenderData: ->
    c = super()
    c.world = @world
    c

  afterRender: ->
    window.onPlayLevelViewLoaded? @  # still a hack
    @loadingScreen = new LoadingScreen(@$el.find('canvas')[0])
    @loadingScreen.show()
    super()

  onLevelLoaderLoaded: =>
    #needs editing
    @session = @levelLoader.session
    @world = @levelLoader.world
    @level = @levelLoader.level
    @levelLoader.destroy()
    @levelLoader = null
    @loadingScreen.destroy()
    @god.level = @level.serialize @supermodel
    @god.worldClassMap = @world.classMap
    #@setTeam @world.teamForPlayer _.size @session.get 'players'   # TODO: players aren't initialized yet?
    @setTeam @getQueryVariable("team") ? @world.teamForPlayer(0)
    @initSurface()
    @initGoalManager()
    @initScriptManager()
    @insertSubviews()
    @initVolume()
    @session.on 'change:multiplayer', @onMultiplayerChanged, @
    @originalSessionState = _.cloneDeep(@session.get('state'))
    @register()
    @controlBar.setBus(@bus)
    @surface.showLevel()

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

  insertSubviews: ->
    #needs editing
    @insertSubView @tome = new TomeView levelID: @levelID, session: @session, thangs: @world.thangs, supermodel: @supermodel
    @insertSubView new PlaybackView {}
    @insertSubView new GoalsView {}
    @insertSubView new GoldView {}
    @insertSubView new HUDView {}
    @insertSubView new ChatView levelID: @levelID, sessionID: @session.id, session: @session
    worldName = @level.get('i18n')?[me.lang()]?.name ? @level.get('name')
    @controlBar = @insertSubView new ControlBarView {worldName: worldName, session: @session, level: @level, supermodel: @supermodel, playableTeams: @world.playableTeams}
  #Backbone.Mediator.publish('level-set-debug', debug: true) if me.displayName() is 'Nick!'

  afterInsert: ->
    super()


  onWindowResize: (s...) ->
    $('#pointer').css('opacity', 0.0)

  onDisableControls: (e) =>
    return if e.controls and not ('level' in e.controls)
    @shortcutsEnabled = false
    @wasFocusedOn = document.activeElement
    $('body').focus()

  onEnableControls: (e) =>
    return if e.controls? and not ('level' in e.controls)
    @shortcutsEnabled = true
    $(@wasFocusedOn).focus() if @wasFocusedOn
    @wasFocusedOn = null

  onDonePressed: => @showVictory()

  onNewWorld: (e) ->
    @world = e.world

  onInfiniteLoop: (e) ->
    return unless e.firstWorld
    @openModalView new InfiniteLoopModal()
    window.tracker?.trackEvent 'Saw Initial Infinite Loop', level: @world.name, label: @world.name


  getNextLevel: ->
    nextLevelOriginal = @level.get('nextLevel')?.original
    levels = @supermodel.getModels(Level)
    return l for l in levels when l.get('original') is nextLevelOriginal

  onHighlightDom: (e) =>
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


  animatePointer: =>
    pointer = $('#pointer')
    pointer.css('transition', 'all 0.6s ease-out')
    pointer.css('transform', "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance-50}px)")
    setTimeout((=>
      pointer.css('transform', "rotate(#{@pointerRotation}rad) translate(-3px, #{@pointerRadialDistance}px)").css('transition', 'all 0.4s ease-in')), 800)

  onFocusDom: (e) => $(e.selector).focus()

  onEndHighlight: =>
    $('#pointer').css('opacity', 0.0)
    clearInterval(@pointerInterval)


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
    @goalManager = new GoalManager(@world)
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
    if state.frame
      Backbone.Mediator.publish 'level-set-time', { time: 0, frameOffset: state.frame }
    if state.selected
      # TODO: Should also restore selected spell here by saving spellName
      Backbone.Mediator.publish 'level-select-sprite', { thangID: state.selected, spellName: null }
    if state.playing?
      Backbone.Mediator.publish 'level-set-playing', { playing: state.playing }


  register: ->
    @bus = LevelBus.get(@levelID, @session.id)
    @bus.setSession(@session)
    @bus.setTeamSpellMap @tome.teamSpellMap
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

  destroy: ->
    @levelLoader?.destroy()
    @surface?.destroy()
    @god?.destroy()
    @goalManager?.destroy()
    @scriptManager?.destroy()
    $(window).off('resize', @onWindowResize)
    delete window.world # not sure where this is set, but this is one way to clean it up

    clearInterval(@pointerInterval)
    @bus?.destroy()
    #@instance.save() unless @instance.loading
    console.profileEnd?() if PROFILE_ME
    @session.off 'change:multiplayer', @onMultiplayerChanged, @
    super()
