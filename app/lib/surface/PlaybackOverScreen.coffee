CocoClass = require 'core/CocoClass'
createjs = require 'lib/createjs-parts'

module.exports = class PlaybackOverScreen extends CocoClass
  subscriptions:
    'goal-manager:new-goal-states': 'onNewGoalStates'

  constructor: (options) ->
    super()
    options ?= {}
    @camera = options.camera
    @layer = options.layer
    @playerNames = options.playerNames
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

  makeVictoryText: ->
    s = ''
    size = Math.ceil @camera.canvasHeight / 6
    text = new createjs.Text s, "#{size}px Open Sans Condensed", '#F7B42C'
    text.shadow = new createjs.Shadow '#000', Math.ceil(@camera.canvasHeight / 300), Math.ceil(@camera.canvasHeight / 300), Math.ceil(@camera.canvasHeight / 120)
    text.textAlign = 'center'
    text.textBaseline = 'middle'
    text.x = 0.5 * @camera.canvasWidth
    text.y = 0.75 * @camera.canvasHeight
    @dimLayer.addChild text
    @text = text

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
    @updateText e

  updateColor: (color) ->
    return if color is @color
    @dimScreen.graphics.clear().beginFill(color).rect 0, 0, @camera.canvasWidth, @camera.canvasHeight
    if @color
      @dimLayer.updateCache()
    else
      @dimLayer.cache 0, 0, @camera.canvasWidth, @camera.canvasHeight
    @color = color

  updateText: (goalEvent) ->
    return unless _.size @playerNames  # Only on multiplayer levels
    teamOverallStatuses = {}

    goals = if goalEvent.goalStates then _.values goalEvent.goalStates else []
    goals = (g for g in goals when not g.optional)
    for team in ['humans', 'ogres']
      teamGoals = (g for g in goals when g.team in [undefined, team])
      statuses = (goal.status for goal in teamGoals)
      overallStatus = 'success' if statuses.length > 0 and _.every(statuses, (s) -> s is 'success')
      overallStatus = 'failure' if statuses.length > 0 and 'failure' in statuses
      teamOverallStatuses[team] = overallStatus

    @makeVictoryText() unless @text
    if teamOverallStatuses.humans is 'success'
      @text.color = '#E62B1E'
      @text.text = ((@playerNames.humans ? $.i18n.t('ladder.red_ai')) + ' ' + $.i18n.t('ladder.wins')).toLocaleUpperCase()
    else if teamOverallStatuses.ogres is 'success'
      @text.color = '#0597FF'
      @text.text = ((@playerNames.ogres ? $.i18n.t('ladder.blue_ai')) + ' ' + $.i18n.t('ladder.wins')).toLocaleUpperCase()
    else
      @text.color = '#F7B42C'
      if goalEvent.timedOut
        @text.text = 'TIMED OUT'
      else
        @text.text = 'INCOMPLETE'
    defaultSize = Math.ceil @camera.canvasHeight / 6
    textScaleFactor = Math.min 1, Math.max(0.5, "PLAYERNAME WINS".length / @text.text.length)
    @text.scaleX = @text.scaleY = textScaleFactor
    @dimLayer.updateCache()
