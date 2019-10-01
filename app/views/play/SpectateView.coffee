require('app/styles/play/spectate.sass')
RootView = require 'views/core/RootView'
template = require 'templates/play/spectate'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'
utils = require 'core/utils'

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
createjs = require 'lib/createjs-parts'

# subviews
LoadingView = require './level/LevelLoadingView'
TomeView = require './level/tome/TomeView'
ChatView = require './level/LevelChatView'
HUDView = require './level/LevelHUDView'
ControlBarView = require './level/ControlBarView'
PlaybackView = require './level/LevelPlaybackView'
GoalsView = require './level/LevelGoalsView'
GoldView = require './level/LevelGoldView'
DuelStatsView = require './level/DuelStatsView'
VictoryModal = require './level/modal/VictoryModal'
InfiniteLoopModal = require './level/modal/InfiniteLoopModal'

require 'lib/game-libraries'

PROFILE_ME = false

module.exports = class SpectateLevelView extends RootView
  id: 'spectate-level-view'
  template: template
  cache: false
  isEditorPreview: false

  subscriptions:
    'level:set-volume': (e) -> createjs.Sound.volume = if e.volume is 1 then 0.6 else e.volume  # Quieter for now until individual sound FX controls work again.
    'god:new-world-created': 'onNewWorld'
    'god:streaming-world-updated': 'onNewWorld'
    'god:infinite-loop': 'onInfiniteLoop'
    'level:next-game-pressed': 'onNextGamePressed'
    'level:started': 'onLevelStarted'
    'level:loading-view-unveiled': 'onLoadingViewUnveiled'

  constructor: (options, @levelID) ->
    console.profile?() if PROFILE_ME
    super options

    @sessionOne = utils.getQueryVariable 'session-one'
    @sessionTwo = utils.getQueryVariable 'session-two'
    if options.spectateSessions
      @sessionOne = options.spectateSessions.sessionOne
      @sessionTwo = options.spectateSessions.sessionTwo

    if not @sessionOne or not @sessionTwo
      @fetchRandomSessionPair (err, data) =>
        if err? then return console.log "There was an error fetching the random session pair: #{data}"
        @setSessions(data[0]._id, data[1]._id)
        @load()
    else
      @load()

  setLevel: (@level, @supermodel) ->
    serializedLevel = @level.serialize {@supermodel, @session, @otherSession, headless: false, sessionless: false}
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
      team: utils.getQueryVariable('team')
    @god = new God maxAngels: 1, spectate: true

  getRenderData: ->
    c = super()
    c.world = @world
    c

  afterRender: ->
    window.onPlayLevelViewLoaded? @  # still a hack
    @insertSubView @loadingView = new LoadingView autoUnveil: true, level: @levelLoader?.level ? @level
    @$el.find('#level-done-button').hide()
    super()
    $('body').addClass('is-playing')

  onLoaded: ->
    _.defer => @onLevelLoaderLoaded()

  onLevelLoaderLoaded: ->
    @grabLevelLoaderData()
    #at this point, all requisite data is loaded, and sessions are not denormalized
    team = @world.teamForPlayer(0)
    @loadOpponentTeam(team)
    @god.setLevel @level.serialize {@supermodel, @session, @otherSession, headless: false, sessionless: false}
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

  grabLevelLoaderData: ->
    @session = @levelLoader.session
    @world = @levelLoader.world
    @level = @levelLoader.level
    @otherSession = @levelLoader.opponentSession
    @levelLoader.destroy()
    @levelLoader = null

  loadOpponentTeam: (myTeam) ->
    if myTeam != @session.get('team')
      console.error("Team mismatch. Expected session one to be '#{myTeam}'. Got '#{@session.get('team')}'");

    opponentSpells = []
    for spellTeam, spells of @session.get('teamSpells') ? @otherSession?.get('teamSpells') ? {}
      continue if spellTeam is myTeam or not myTeam
      opponentSpells = opponentSpells.concat spells

    opponentCode = @otherSession?.get('code') or {}
    myCode = @session.get('code') or {}
    for spell in opponentSpells
      [thang, spell] = spell.split '/'
      c = opponentCode[thang]?[spell]
      myCode[thang] ?= {}
      if c then myCode[thang][spell] = c else delete myCode[thang][spell]

    @session.set('code', myCode)

  onLevelStarted: (e) ->
    go = =>
      @loadingView?.startUnveiling()
      @loadingView?.unveil true
    _.delay go, 1000

  onLoadingViewUnveiled: (e) ->
    # Don't remove it; we want its decoration around on large screens.
    #@removeSubView @loadingView
    #@loadingView = null
    Backbone.Mediator.publish 'level:set-playing', playing: false
    Backbone.Mediator.publish 'level:set-time', time: 1  # Helps to have perhaps built a few Thangs and gotten a good list of spritesheets we need to render for our initial paused frame

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
    @insertSubView @tome = new TomeView levelID: @levelID, session: @session, otherSession: @otherSession, thangs: @world.thangs, supermodel: @supermodel, spectateView: true, spectateOpponentCodeLanguage: @otherSession?.get('submittedCodeLanguage'), level: @level, god: @god
    @insertSubView new PlaybackView session: @session, level: @level

    goldInDuelStatsView = @level.get('slug') in ['wakka-maul', 'cross-bones']
    @insertSubView new GoldView {} unless goldInDuelStatsView
    @insertSubView new HUDView {level: @level}
    @insertSubView new DuelStatsView level: @level, session: @session, otherSession: @otherSession, supermodel: @supermodel, thangs: @world.thangs, showsGold: goldInDuelStatsView if @level.isType('hero-ladder', 'course-ladder')
    @insertSubView @controlBar = new ControlBarView {worldName: utils.i18n(@level.attributes, 'name'), session: @session, level: @level, supermodel: @supermodel, spectateGame: true}

  # callbacks

  onInfiniteLoop: (e) ->
    return unless e.firstWorld and e.god is @god
    @openModalView new InfiniteLoopModal()
    window.tracker?.trackEvent 'Saw Initial Infinite Loop', level: @world.name, label: @world.name

  # initialization

  initSurface: ->
    webGLSurface = $('canvas#webgl-surface', @$el)
    normalSurface = $('canvas#normal-surface', @$el)
    @surface = new Surface @world, normalSurface, webGLSurface, thangTypes: @supermodel.getModels(ThangType), spectateGame: true, playerNames: @findPlayerNames(), levelType: @level.get('type', true)
    worldBounds = @world.getBounds()
    bounds = [{x:worldBounds.left, y:worldBounds.top}, {x:worldBounds.right, y:worldBounds.bottom}]
    @surface.camera.setBounds(bounds)
    zoom = =>
      @surface?.camera.zoomTo({x: (worldBounds.right - worldBounds.left) / 2, y: (worldBounds.top - worldBounds.bottom) / 2}, 0.1, 0)
    _.delay zoom, 4000  # call it later for some reason (TODO: figure this out)

  findPlayerNames: ->
    playerNames = {}
    for session in [@session, @otherSession] when session?.get('team')
      playerNames[session.get('team')] = session.get('creatorName') or 'Anonymous'
    playerNames

  initGoalManager: ->
    @goalManager = new GoalManager(@world, @level.get('goals'))
    @god.setGoalManager @goalManager

  initScriptManager: ->
    if @world.scripts
      nonVictoryPlaybackScripts = _.reject @world.scripts, (script) ->
        not /(Set Camera Boundaries|Introduction)/.test script.id
    else
      console.log 'World scripts don\'t exist!'
      nonVictoryPlaybackScripts = []
    @scriptManager = new ScriptManager({scripts: nonVictoryPlaybackScripts, view:@, session: @session})
    @scriptManager.loadFromSession()

  initVolume: ->
    volume = me.get('volume')
    volume = 1.0 unless volume?
    Backbone.Mediator.publish 'level:set-volume', volume: volume

  register: -> return

  onSessionWillSave: (e) ->
    # Something interesting has happened, so (at a lower frequency), we'll save a screenshot.
    console.log 'Session is saving but shouldn\'t save!!!!!!!'

  # Throttled
  saveScreenshot: (session) =>
    return unless screenshot = @surface?.screenshot()
    session.save {screenshot: screenshot}, {patch: true, type: 'PUT'}

  setTeam: (team) ->
    team = team?.team unless _.isString team
    team ?= 'humans'
    me.team = team
    Backbone.Mediator.publish 'level:team-set', team: team

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
      unless utils.getQueryVariable('autoplay') is false
        Backbone.Mediator.publish 'level:set-playing', playing: true  # Since we paused at first, now we autostart playback.
    else
      @lastWorldFramesLoaded = @world.frames.length
    for [spriteName, message] in @world.thangDialogueSounds startFrame
      continue unless thangType = _.find thangTypes, (m) -> m.get('name') is spriteName
      continue unless sound = AudioPlayer.soundForDialogue message, thangType.get('soundTriggers')
      AudioPlayer.preloadSoundReference sound

  setSessions: (sessionOne, sessionTwo) ->
    @sessionOne = sessionOne
    @sessionTwo = sessionTwo
    # The order of the sessions depends on the playable teams. The API endpoint always returns
    # the human team as session 1 and the ogre team as session 2.
    # However the playable team order defined in the level editor must match the sessions.
    # Zero Sum has specified Ogres before Humans, thus causing the wrong sessions to be placed.
    # This can be confirmed in the level editor: zero sum -> Systems -> Alliance -> config -> teams.
    # TODO: Investigate if there is a cleaner fix, maybe by modifying Zero Sum config.
    if @levelID == "zero-sum"
      @sessionOne = sessionTwo
      @sessionTwo = sessionOne

  onNextGamePressed: (e) ->
    @fetchRandomSessionPair (err, data) =>
      return if @destroyed
      if err? then return console.log "There was an error fetching the random session pair: #{data}"
      @setSessions(data[0]._id, data[1]._id)
      url = "/play/spectate/#{@levelID}?session-one=#{@sessionOne}&session-two=#{@sessionTwo}"
      if leagueID = utils.getQueryVariable 'league'
        url += "&league=" + leagueID
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
    if leagueID = utils.getQueryVariable 'league'
      randomSessionPairURL += "?league=" + leagueID
    $.ajax
      url: randomSessionPairURL
      type: 'GET'
      cache: false
      complete: (jqxhr, textStatus) ->
        if textStatus isnt 'success'
          cb('error', jqxhr.statusText)
        else
          cb(null, $.parseJSON(jqxhr.responseText))

  destroy: ()->
    @levelLoader?.destroy()
    @surface?.destroy()
    @god?.destroy()
    @goalManager?.destroy()
    @scriptManager?.destroy()
    delete window.world # not sure where this is set, but this is one way to clean it up
    console.profileEnd?() if PROFILE_ME
    super()
