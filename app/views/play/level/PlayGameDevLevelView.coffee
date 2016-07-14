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
{createAetherOptions} = require 'lib/aether_utils'
State = require 'models/State'

TEAM = 'humans'

module.exports = class PlayGameDevLevelView extends RootView
  id: 'play-game-dev-level-view'
  template: require 'templates/play/level/play-game-dev-level-view'
  
  events:
    'click #play-btn': 'onClickPlayButton'

  initialize: (@options, @levelID, @sessionID) ->
    @state = new State({
      loading: true
      progress: 0
    })
    
    @supermodel.on 'update-progress', (progress) =>
      @state.set({progress: (progress*100).toFixed(1)+'%'})
    @level = new Level()
    @session = new LevelSession()
    @gameUIState = new GameUIState()
    @courseID = @getQueryVariable 'course'
    @god = new God({ @gameUIState })
    @levelLoader = new LevelLoader({ @supermodel, @levelID, @sessionID, observing: true, team: TEAM, @courseID })
    @listenTo @state, 'change', _.debounce(-> @renderSelectors('#info-col'))

    @levelLoader.loadWorldNecessities()

    .then (levelLoader) =>
      { @level, @session, @world } = levelLoader
      @god.setLevel(@level.serialize(@supermodel, @session))
      @god.setWorldClassMap(@world.classMap)
      @goalManager = new GoalManager(@world, @level.get('goals'), @team)
      @god.setGoalManager(@goalManager)
      @god.angelsShare.firstWorld = false # HACK
      me.team = TEAM
      @session.set 'team', TEAM
      @scriptManager = new ScriptManager({
        scripts: @world.scripts or [], view: @, @session, levelID: @level.get('slug')})
      @scriptManager.loadFromSession() # Should we? TODO: Figure out how scripts work for game dev levels
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
      })
      worldBounds = @world.getBounds()
      bounds = [{x: worldBounds.left, y: worldBounds.top}, {x: worldBounds.right, y: worldBounds.bottom}]
      @surface.camera.setBounds(bounds)
      @surface.camera.zoomTo({x: 0, y: 0}, 0.1, 0)
      @surface.setWorld(@world)
      @scriptManager.initializeCamera()
      @renderSelectors '#info-col'
      @spells = @session.generateSpellsObject()
      @state.set('loading', false)

    .catch ({message}) =>
      @state.set('errorMessage', message) 

  onClickPlayButton: ->
    @god.createWorld(@spells, false, true)
    Backbone.Mediator.publish('playback:real-time-playback-started', {})
    Backbone.Mediator.publish('level:set-playing', {playing: true})
    @state.set('playing', true)

  destroy: ->
    @levelLoader?.destroy()
    @surface?.destroy()
    @god?.destroy()
    @goalManager?.destroy()
    @scriptManager?.destroy()
    delete window.world # not sure where this is set, but this is one way to clean it up
    super()
