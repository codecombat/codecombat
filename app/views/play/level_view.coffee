View = require 'views/kinds/RootView'
template = require 'templates/play/level'
{me} = require('lib/auth')
ThangType = require 'models/ThangType'

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
Camera = require 'lib/surface/Camera'
AudioPlayer = require 'lib/AudioPlayer'

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
      window.tracker?.trackEvent 'Hour of Code Begin', {}

    @isEditorPreview = @getQueryVariable 'dev'
    @sessionID = @getQueryVariable 'session'

    $(window).on('resize', @onWindowResize)
    @supermodel.once 'error', @onLevelLoadError
    @saveScreenshot = _.throttle @saveScreenshot, 30000

    if @isEditorPreview
      f = =>
        @supermodel.shouldSaveBackups = (model) ->
          model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem']
        @load() unless @levelLoader
      setTimeout f, 100
    else
      @load()

  onLevelLoadError: (e) =>
    application.router.navigate "/play?not_found=#{@levelID}", {trigger: true}

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
    if me.get('hourOfCode') and me.lang() is 'en-US'
      # Show the Hour of Code footer explanation until it's been more than a day
      elapsed = (new Date() - new Date(me.get('dateCreated')))
      c.explainHourOfCode = elapsed < 86400 * 1000
    c

  afterRender: ->
    window.onPlayLevelViewLoaded? @  # still a hack
    @loadingScreen = new LoadingScreen(@$el.find('canvas')[0])
    @loadingScreen.show()
    @$el.find('#level-done-button').hide()
    super()

  onLevelLoaderLoaded: =>
    # Save latest level played in local storage
    if localStorage?
      localStorage["lastLevel"] = @levelID

    @session = @levelLoader.session
    @world = @levelLoader.world
    @level = @levelLoader.level
    team = @getQueryVariable("team") ? @world.teamForPlayer(0)

    opponentSpells = []
    for spellTeam, spells of @session.get('teamSpells') ? otherSession?.get('teamSpells') ? {}
      continue if spellTeam is team or not team
      opponentSpells = opponentSpells.concat spells

    otherSession = @levelLoader.opponentSession
    opponentCode = otherSession?.get('submittedCode') or {}
    myCode = @session.get('code') or {}
    for spell in opponentSpells
      [thang, spell] = spell.split '/'
      c = opponentCode[thang]?[spell]
      myCode[thang] ?= {}
      if c then myCode[thang][spell] = c else delete myCode[thang][spell]
    @session.set('code', myCode)
    if @session.get('multiplayer') and otherSession?
      # For now, ladderGame will disallow multiplayer, because session code combining doesn't play nice yet.
      @session.set 'multiplayer', false

    @levelLoader.destroy()
    @levelLoader = null
    @loadingScreen.destroy()
    @god.level = @level.serialize @supermodel
    @god.worldClassMap = @world.classMap
    @setTeam team
    @initSurface()
    @initGoalManager()
    @initScriptManager()
    @insertSubviews ladderGame: otherSession?
    @initVolume()
    @session.on 'change:multiplayer', @onMultiplayerChanged, @
    @originalSessionState = _.cloneDeep(@session.get('state'))
    @register()
    @controlBar.setBus(@bus)
    @surface.showLevel()
    if otherSession
      # TODO: colorize name and cloud by team, colorize wizard by user's color config
      @surface.createOpponentWizard id: otherSession.get('creator'), name: otherSession.get('creatorName'), team: otherSession.get('team')

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
    worldName = @level.get('i18n')?[me.lang()]?.name ? @level.get('name')
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

  showVictory: ->
    options = {level: @level, supermodel: @supermodel, session:@session}
    docs = new VictoryModal(options)
    @openModalView(docs)
    window.tracker?.trackEvent 'Saw Victory', level: @world.name, label: @world.name

  onRestartLevel: ->
    @tome.reloadAllCode()
    Backbone.Mediator.publish 'level:restarted'
    $('#level-done-button', @$el).hide()
    window.tracker?.trackEvent 'Confirmed Restart', level: @world.name, label: @world.name

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
    if state.frame
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
    @supermodel?.off 'error', @onLevelLoadError
    @levelLoader?.off 'loaded-all', @onLevelLoaderLoaded
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
    @session?.off 'change:multiplayer', @onMultiplayerChanged, @
    @onLevelLoadError = null
    @onLevelLoaderLoaded = null
    @onSupermodelLoadedOne = null
    @preloadNextLevel = null
    @saveScreenshot = null
    super()
