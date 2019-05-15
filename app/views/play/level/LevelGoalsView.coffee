require('app/styles/play/level/goals.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/goals'
{me} = require 'core/auth'
utils = require 'core/utils'
LevelSession = require 'models/LevelSession'
Level = require 'models/Level'
LevelConstants = require 'lib/LevelConstants'
LevelGoals = require('./LevelGoals').default
store = require 'core/store'


module.exports = class LevelGoalsView extends CocoView
  id: 'goals-view'
  template: template
  className: 'secret expanded'
  playbackEnded: false

  subscriptions:
    'goal-manager:new-goal-states': 'onNewGoalStates'
    'tome:cast-spells': 'onTomeCast'
    'level:set-letterbox': 'onSetLetterbox'
    'level:set-playing': 'onSetPlaying'
    'surface:playback-restarted': 'onSurfacePlaybackRestarted'
    'surface:playback-ended': 'onSurfacePlaybackEnded'

  events:
    'mouseenter': ->
      return @onSurfacePlaybackRestarted() if @playbackEnded
      @mouseEntered = true
      @updatePlacement()

    'mouseleave': ->
      @mouseEntered = false
      @updatePlacement()

  constructor: (options) ->
    super options
    @level = options.level
    
  afterRender: ->
    @levelGoalsComponent = new LevelGoals({
      el: @$('.goals-component')[0],
      store
      propsData: { showStatus: true }
    })

  onNewGoalStates: (e) ->
    _.assign(@levelGoalsComponent, _.pick(e, 'overallStatus', 'timedOut', 'goals', 'goalStates'))
    @levelGoalsComponent.casting = false

    firstRun = not @previousGoalStatus?
    @previousGoalStatus ?= {}
    @succeeded = e.overallStatus is 'success'
    for goal in e.goals
      state = e.goalStates[goal.id] or { status: 'incomplete' }
      if not firstRun and state.status is 'success' and @previousGoalStatus[goal.id] isnt 'success'
        @soundToPlayWhenPlaybackEnded = 'goal-success'
      else if not firstRun and state.status isnt 'success' and @previousGoalStatus[goal.id] is 'success'
        @soundToPlayWhenPlaybackEnded = 'goal-incomplete-again'
      else
        @soundToPlayWhenPlaybackEnded = null
      @previousGoalStatus[goal.id] = state.status
    if e.goals.length > 0 and @$el.hasClass 'secret'
      @$el.removeClass('secret')
      @lastSizeTweenTime = new Date()
    @updatePlacement()

  onTomeCast: (e) ->
    return if e.preload
    @levelGoalsComponent.casting = true

  onSetPlaying: (e) ->
    return unless e.playing
    # Automatically hide it while we replay
    @mouseEntered = false
    @expanded = true
    @updatePlacement()

  onSurfacePlaybackRestarted: ->
    @playbackEnded = false
    @$el.removeClass 'brighter'
    @lastSizeTweenTime = new Date()
    @updatePlacement()

  onSurfacePlaybackEnded: ->
    return if @level.isType('game-dev')
    @playbackEnded = true
    @updateHeight()
    @$el.addClass 'brighter'
    @lastSizeTweenTime = new Date()
    @updatePlacement()
    if @soundToPlayWhenPlaybackEnded
      @playSound @soundToPlayWhenPlaybackEnded

  updateHeight: ->
    return if @$el.hasClass('brighter') or @$el.hasClass('secret')
    return if (new Date() - @lastSizeTweenTime) < 500  # Don't measure this while still animating, might get the wrong value. Should match sass transition time.
    @normalHeight = @$el.outerHeight()

  updatePlacement: ->
    # Expand it if it's at the end. Mousing over reverses this.
    expand = @playbackEnded isnt @mouseEntered
    return if expand is @expanded
    @updateHeight()
    sound = if expand then 'goals-expand' else 'goals-collapse'
    if expand
      top = -5
    else
      height = @normalHeight
      height = @$el.outerHeight() if not height or @playbackEnded
      top = 41 - height
    @$el.css 'top', top
    if @soundTimeout
      # Don't play the sound we were going to play after all; the transition has reversed.
      clearTimeout @soundTimeout
      @soundTimeout = null
    else if @expanded?
      # Play it when the transition ends, not when it begins.
      @soundTimeout = _.delay @playToggleSound, 500, sound
    @expanded = expand

  playToggleSound: (sound) =>
    return if @destroyed
    @playSound sound unless @options.level.isType('game-dev')
    @soundTimeout = null

  onSetLetterbox: (e) ->
    @$el.toggle not e.on
    @updatePlacement()
