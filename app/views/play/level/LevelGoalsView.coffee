CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/goals'
{me} = require 'core/auth'
utils = require 'core/utils'

stateIconMap =
  success: 'glyphicon-ok'
  failure: 'glyphicon-remove'

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
      @mouseEntered = true
      @updatePlacement()

    'mouseleave': ->
      @mouseEntered = false
      @updatePlacement()

  constructor: (options) ->
    super options
    @level = options.level

  onNewGoalStates: (e) ->
    firstRun = not @previousGoalStatus?
    @previousGoalStatus ?= {}
    @$el.find('.goal-status').addClass 'secret'
    classToShow = null
    classToShow = 'success' if e.overallStatus is 'success'
    classToShow = 'failure' if e.overallStatus is 'failure'
    classToShow ?= 'timed-out' if e.timedOut
    classToShow ?= 'incomplete'
    @$el.find('.goal-status.'+classToShow).removeClass 'secret'
    list = $('#primary-goals-list', @$el)
    list.empty()
    goals = []
    for goal in e.goals
      state = e.goalStates[goal.id]
      continue if goal.optional and @level.get('type', true) is 'course' and state.status isnt 'success'
      if goal.hiddenGoal
        continue if goal.optional and state.status isnt 'success'
        continue if not goal.optional and state.status isnt 'failure'
      continue if goal.team and me.team isnt goal.team
      text = utils.i18n goal, 'name'
      if state.killed
        dead = _.filter(_.values(state.killed)).length
        targeted = _.values(state.killed).length
        if targeted > 1
          # Does this make sense?
          if goal.isPositive
            completed = dead
          else
            completed = targeted - dead
          text = text + " (#{completed}/#{targeted})"
      # This should really get refactored, along with GoalManager, so that goals have a standard
      # representation of how many are done, how many are needed, what that means, etc.
      li = $('<li></li>').addClass("status-#{state.status}").text(text)
      iconClass = stateIconMap[state.status]
      li.prepend($('<i></i>').addClass("glyphicon #{iconClass or ''}"))  # If empty, insert a .glyphicon to take up space
      list.append(li)
      goals.push goal
      if not firstRun and state.status is 'success' and @previousGoalStatus[goal.id] isnt 'success'
        @soundToPlayWhenPlaybackEnded = 'goal-success'
      else if not firstRun and state.status isnt 'success' and @previousGoalStatus[goal.id] is 'success'
        @soundToPlayWhenPlaybackEnded = 'goal-incomplete-again'
      else
        @soundToPlayWhenPlaybackEnded = null
      @previousGoalStatus[goal.id] = state.status
    if goals.length > 0 and @$el.hasClass 'secret'
      @$el.removeClass('secret')
      @lastSizeTweenTime = new Date()
    @updatePlacement()

  onTomeCast: (e) ->
    return if e.preload
    @$el.find('.goal-status').addClass('secret')
    @$el.find('.goal-status.running').removeClass('secret')

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
    @playSound sound
    @soundTimeout = null

  onSetLetterbox: (e) ->
    @$el.toggle not e.on
    @updatePlacement()
