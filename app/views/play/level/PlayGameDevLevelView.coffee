RootView = require 'views/core/RootView'

GameUIState = require 'models/GameUIState'
God = require 'lib/God'
LevelLoader = require 'lib/LevelLoader'
GoalManager = require 'lib/world/GoalManager'
Surface = require 'lib/surface/Surface'
ThangType = require 'models/ThangType'

module.exports = class PlayGameDevLevelView extends RootView
  id: 'play-game-dev-level-view'
  template: require 'templates/play/level/play-game-dev-level-view'

  subscriptions:
    'level:started': 'onLevelStarted'
  
  initialize: (@options, @levelID, @sessionID) ->
    @gameUIState = new GameUIState()
    @god = new God({ @gameUIState })
    @levelLoader = new LevelLoader({ @supermodel, @levelID, @sessionID, observing: true })
    @listenToOnce @levelLoader, 'world-necessities-loaded', @onWorldNecessitiesLoaded
    @listenTo @levelLoader, 'world-necessity-load-failed', @onWorldNecessityLoadFailed

  onWorldNecessitiesLoaded: ->
    { @level, @session, @world, @classMap } = @levelLoader
    levelObject = @level.serialize(@supermodel, @session)
    @god.setLevel(levelObject)
    @god.setWorldClassMap(@classMap)
    @goalManager = new GoalManager(@world, @level.get('goals'), @team)
    @god.setGoalManager(@goalManager)

  onWorldNecessityLoadFailed: ->
    # TODO: handle these and other failures with Promises

  onLoaded: ->
    _.defer => @onLevelLoaderLoaded()

  onLevelLoaderLoaded: ->
    return unless @levelLoader.progress() is 1  # double check, since closing the guide may trigger this early
    @levelLoader.destroy()
    @levelLoader = null
    @initSurface()

  initSurface: ->
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

  onLevelStarted: ->
    console.log 'level started'
