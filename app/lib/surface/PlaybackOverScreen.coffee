CocoClass = require 'core/CocoClass'

module.exports = class PlaybackOverScreen extends CocoClass
  subscriptions:
    'goal-manager:new-goal-states': 'onNewGoalStates'

  constructor: (options) ->
    super()
    options ?= {}
    @camera = options.camera
    @layer = options.layer
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @build()

  toString: -> '<PlaybackOverScreen>'

  build: ->
    @dimLayer = new createjs.Container()
    @dimLayer.mouseEnabled = @dimLayer.mouseChildren = false
    @dimLayer.addChild @dimScreen = new createjs.Shape()
    @dimLayer.alpha = 0
    @layer.addChild @dimLayer

  show: ->
    return if @showing
    @showing = true
    @updateColor 'rgba(212, 212, 212, 0.4)' unless @color  # If we haven't caught the goal state for the first run, just do something neutral.
    @dimLayer.alpha = 0
    createjs.Tween.removeTweens @dimLayer
    createjs.Tween.get(@dimLayer).to({alpha: 1}, 500)

  hide: ->
    return unless @showing
    @showing = false
    createjs.Tween.removeTweens @dimLayer
    createjs.Tween.get(@dimLayer).to({alpha: 0}, 500)

  onNewGoalStates: (e) ->
    success = e.overallStatus is 'success'
    failure = e.overallStatus is 'failure'
    timedOut = e.timedOut
    incomplete = not success and not failure and not timedOut
    color = if failure then 'rgba(255, 128, 128, 0.4)' else 'rgba(255, 255, 255, 0.4)'
    @updateColor color

  updateColor: (color) ->
    return if color is @color
    @dimScreen.graphics.clear().beginFill(color).rect 0, 0, @camera.canvasWidth, @camera.canvasHeight
    if @color
      @dimLayer.updateCache()
    else
      @dimLayer.cache 0, 0, @camera.canvasWidth, @camera.canvasHeight  # I wonder if caching is even worth it for just a rect fill.
    @color = color
