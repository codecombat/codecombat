require('app/styles/play/level/play-game-dev-level-view.sass')
RootView = require 'views/core/RootView'

GameUIState = require 'models/GameUIState'
God = require 'lib/God'
LevelLoader = require 'lib/LevelLoader'
GoalManager = require 'lib/world/GoalManager'
ScriptManager = require 'lib/scripts/ScriptManager'
Surface = require 'lib/surface/Surface'
ThangType = require 'models/ThangType'
Level = require 'models/Level'
LevelSession = require 'models/LevelSession'
State = require 'models/State'
utils = require 'core/utils'
urls = require 'core/urls'
Course = require 'models/Course'
GameDevVictoryModal = require './modal/GameDevVictoryModal'
aetherUtils = require 'lib/aether_utils'
GameDevTrackView = require './GameDevTrackView'
api = require 'core/api'

require 'lib/game-libraries'
window.Box2D = require('exports-loader?Box2D!vendor/scripts/Box2dWeb-2.1.a.3')

TEAM = 'humans'

module.exports = class PlayGameDevLevelView extends RootView
  id: 'play-game-dev-level-view'
  template: require 'templates/play/level/play-game-dev-level-view'

  subscriptions:
    'god:new-world-created': 'onNewWorld'
    'god:streaming-world-updated': 'onStreamingWorldUpdated'

  events:
    'click #edit-level-btn': 'onEditLevelButton'
    'click #play-btn': 'onClickPlayButton'
    'click #copy-url-btn': 'onClickCopyURLButton'
    'click #play-more-codecombat-btn': 'onClickPlayMoreCodeCombatButton'

  initialize: (@options, @sessionID) ->
    super(@options)

    @state = new State({
      loading: true
      progress: 0
      creatorString: ''
      isOwner: false
    })

    $(window).keydown (event) ->
      # prevent space from scrolling on the page since it can be used as a control in the game.
      if (event.keyCode == 32 && event.target == document.body)
        event.preventDefault()

    if utils.getQueryVariable 'dev'
      @supermodel.shouldSaveBackups = (model) ->  # Make sure to load possibly changed things from localStorage.
        model.constructor.className in ['Level', 'LevelComponent', 'LevelSystem', 'ThangType']
    @supermodel.on 'update-progress', (progress) =>
      @state.set({progress: (progress*100).toFixed(1)+'%'})
    @level = new Level()
    @session = new LevelSession({ _id: @sessionID })
    @gameUIState = new GameUIState()
    @courseID = utils.getQueryVariable 'course'
    @courseInstanceID = utils.getQueryVariable 'course-instance'
    @god = new God({ @gameUIState, indefiniteLength: true })

    @supermodel.registerModel(@session)
    new Promise((accept,reject) => @session.fetch({ cache: false }).then(accept, reject)).then (sessionData) =>
      api.levels.getByOriginal(sessionData.level.original)
    .then (levelData) =>
      @levelID = levelData.slug
      @levelLoader = new LevelLoader({ @supermodel, @levelID, @sessionID, observing: true, team: TEAM, @courseID })
      @supermodel.setMaxProgress 1 # Hack, why are we setting this to 0.2 in LevelLoader?
      @listenTo @state, 'change', _.debounce @renderAllButCanvas
      @updateDb = _.throttle(@updateDb, 1000)

      @levelLoader.loadWorldNecessities()

    .then (levelLoader) =>
      { @level, @session, @world } = levelLoader

      @setMeta({
        title: $.i18n.t 'play.game_development_title', { level: @level.get('name') }
      })

      @god.setLevel(@level.serialize {@supermodel, @session})
      @god.setWorldClassMap(@world.classMap)
      @goalManager = new GoalManager(@world, @level.get('goals'), @team)
      @god.setGoalManager(@goalManager)
      @god.angelsShare.firstWorld = false # HACK
      me.team = TEAM
      @session.set 'team', TEAM
      @scriptManager = new ScriptManager({
        scripts: @world.scripts or [], view: @, @session, levelID: @level.get('slug')})
      @scriptManager.loadFromSession() # Should we? TODO: Figure out how scripts work for game dev levels
      @howToPlayText = utils.i18n(@level.attributes, 'studentPlayInstructions')
      @howToPlayText ?= $.i18n.t('play_game_dev_level.default_student_instructions')
      @howToPlayText = marked(@howToPlayText, { sanitize: true })
      @renderAllButCanvas()
      @supermodel.finishLoading()

    .then (supermodel) =>
      @levelLoader.destroy()
      @levelLoader = null
      webGLSurface = @$('canvas#webgl-surface')
      normalSurface = @$('canvas#normal-surface')
      @surface = new Surface(@world, normalSurface, webGLSurface, {
        thangTypes: @supermodel.getModels(ThangType)
        levelType: @level.get('type', true)
        @gameUIState
        resizeStrategy: 'wrapper-size'
      })
      @listenTo @surface, 'resize', @onSurfaceResize
      worldBounds = @world.getBounds()
      bounds = [{x: worldBounds.left, y: worldBounds.top}, {x: worldBounds.right, y: worldBounds.bottom}]
      @surface.camera.setBounds(bounds)
      @surface.camera.zoomTo({x: 0, y: 0}, 0.1, 0)
      @surface.setWorld(@world)
      @scriptManager.initializeCamera()
      @renderSelectors '#info-col'
      @spells = aetherUtils.generateSpellsObject level: @level, levelSession: @session
      goalNames = (utils.i18n(goal, 'name') for goal in @goalManager.goals)

      course = if @courseID then new Course({_id: @courseID}) else null
      shareURL = urls.playDevLevel({@level, @session, course})

      creatorString = if @session.get('creatorName')
        $.i18n.t('play_game_dev_level.created_by').replace('{{name}}', @session.get('creatorName'))
      else
        $.i18n.t('play_game_dev_level.created_during_hoc')

      @state.set({
        loading: false
        goalNames
        shareURL
        creatorString
        isOwner: me.id is @session.get('creator')
      })
      @eventProperties = {
        category: 'Play GameDev Level'
        @courseID
        sessionID: @session.id
        levelID: @level.id
        levelSlug: @level.get('slug')
      }
      window.tracker?.trackEvent 'Play GameDev Level - Load', @eventProperties, ['Mixpanel']
      @insertSubView new GameDevTrackView {} if @level.isType('game-dev')
      # Load a realtime, synchronous world to get uiText properties off the world object.
      # We don't want the world to be playable immediately so calling updateStudentGoals
      # replaces this world with the first frame of the world level.
      worldCreationOptions = {spells: @spells, preload: false, realTime: true, justBegin: false, keyValueDb: @session.get('keyValueDb') ? {}, synchronous: true}
      @god.createWorld(worldCreationOptions)
      @willUpdateFrontEnd = true

    .catch (e) =>
      throw e if e.stack
      @state.set('errorMessage', e.message)

  getMeta: ->
    return {
      links: [
        { vmid: 'rel-canonical', rel: 'canonical', href: '/play'}
      ]
    }

  onEditLevelButton: ->
    viewClass = 'views/play/level/PlayLevelView'
    route = "/play/level/#{@level.get('slug')}"
    if @courseID and @courseInstanceID
      route += "?course=#{@courseID}&course-instance=#{@courseInstanceID}"
    Backbone.Mediator.publish 'router:navigate', {
      route, viewClass
      viewArgs: [{}, @levelID]
    }

  onClickPlayButton: ->
    $('#play-btn').blur()   # Removes focus from the button after clicking on it.
    worldCreationOptions = {spells: @spells, preload: false, realTime: true, justBegin: false, keyValueDb: @session.get('keyValueDb') ? {}, synchronous: true}
    @god.createWorld(worldCreationOptions)
    Backbone.Mediator.publish('playback:real-time-playback-started', {})
    Backbone.Mediator.publish('level:set-playing', {playing: true})
    action = if @state.get('playing') then 'Play GameDev Level - Restart Level' else 'Play GameDev Level - Start Level'
    window.tracker?.trackEvent(action, @eventProperties, ['Mixpanel'])
    @state.set('playing', true)

  onClickCopyURLButton: ->
    @$('#copy-url-input').val(@state.get('shareURL')).select()
    @tryCopy()
    window.tracker?.trackEvent('Play GameDev Level - Copy URL', @eventProperties, ['Mixpanel'])

  onClickPlayMoreCodeCombatButton: ->
    window.tracker?.trackEvent('Play GameDev Level - Click Play More CodeCombat', @eventProperties, ['Mixpanel'])

  onSurfaceResize: ({height}) ->
    @state.set('surfaceHeight', height)

  renderAllButCanvas: ->
    @renderSelectors('#info-col', '#share-row')
    height = @state.get('surfaceHeight')
    if height
      @$el.find('#info-col').css('height', @state.get('surfaceHeight'))

  onNewWorld: (e) ->
    if @goalManager.checkOverallStatus() is 'success'
      modal = new GameDevVictoryModal({ shareURL: @state.get('shareURL'), @eventProperties, @victoryMessage })
      @openModalView(modal)
      modal.once 'replay', @onClickPlayButton, @

  updateStudentGoals: ->
    return if @studentGoals
    # Set by users. Defined in `game.GameUI` component in the level editor.
    if @world.uiText?.directions?.length
      @studentGoals = @world.uiText.directions.map((direction) -> {type: "user_defined", direction})
    else
      @studentGoals = @world.thangMap['Hero Placeholder'].stringGoals?.map((g) -> JSON.parse(g))
    return unless _.size(@studentGoals)
    @updateRealTimeGoals()
    worldCreationOptions = {spells: @spells, preload: false, realTime: false, justBegin: true, keyValueDb: @session.get('keyValueDb') ? {}}
    @god.createWorld(worldCreationOptions)

  updateRealTimeGoals: (goals) ->
    if goals?
      @studentGoals = goals?.map((g) -> JSON.parse(g))
    @renderSelectors '#directions'

  onStreamingWorldUpdated: (e) ->
    @world = e.world
    if @world.age > 0 and @willUpdateFrontEnd
      @willUpdateFrontEnd = false
      @updateStudentGoals()
      @updateLevelName()
      @updateVictoryMessage()
    @updateDb()

  updateLevelName: ->
    if @world.uiText?.levelName
      @levelName = @world.uiText.levelName
      @renderSelectors '#directions'

  updateVictoryMessage: ->
    if @world.uiText?.victoryMessage
      @victoryMessage = @world.uiText?.victoryMessage

  getLevelName: () ->
    @levelName ? @level.get('name')

  updateDb: ->
    return unless @state?.get('playing')
    if @surface.world.keyValueDb and not _.isEqual(@surface.world.keyValueDb, @session.attributes.keyValueDb)
      @session.updateKeyValueDb(_.cloneDeep(@surface.world.keyValueDb))
      @session.saveKeyValueDb()

  destroy: ->
    @levelLoader?.destroy()
    @surface?.destroy()
    @god?.destroy()
    @goalManager?.destroy()
    @scriptManager?.destroy()
    delete window.world # not sure where this is set, but this is one way to clean it up
    $(window).off("keydown")
    super()
