View = require 'views/kinds/CocoView'
template = require 'templates/play/level/goals'
{me} = require 'lib/auth'
utils = require 'lib/utils'

stateIconMap =
  incomplete: 'icon-minus'
  success: 'icon-ok'
  failure: 'icon-remove'

module.exports = class GoalsView extends View
  id: 'goals-view'
  template: template

  subscriptions:
    'goal-manager:new-goal-states': 'onNewGoalStates'
    'level-set-letterbox': 'onSetLetterbox'
    'surface:playback-restarted': 'onSurfacePlaybackRestarted'
    'surface:playback-ended': 'onSurfacePlaybackEnded'

  events:
    'mouseenter': ->
      @mouseEntered = true
      @updatePlacement()

    'mouseleave': ->
      @mouseEntered = false
      @updatePlacement()

  toggleCollapse: (e) ->
    @$el.toggleClass('expanded').toggleClass('collapsed')

  onNewGoalStates: (e) ->
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
      continue if goal.hiddenGoal and state.status isnt 'failure'
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
      li.prepend($('<i></i>').addClass(stateIconMap[state.status]))
      list.append(li)
      goals.push goal
    @$el.removeClass('secret') if goals.length > 0

  onSurfacePlaybackRestarted: ->
    @playbackEnded = false
    @$el.removeClass 'brighter'
    @updatePlacement()

  onSurfacePlaybackEnded: ->
    @playbackEnded = true
    @$el.addClass 'brighter'
    @updatePlacement()

  render: ->
    super()
    @$el.addClass('secret').addClass('expanded')

  afterRender: ->
    super()
    @updatePlacement()

  updatePlacement: ->
    if @playbackEnded or @mouseEntered
      # expand
      @$el.css('top', -10)
    else
      # collapse
      @$el.css('top', 26 - @$el.outerHeight())

  onSetLetterbox: (e) ->
    @$el.toggle not e.on
    @updatePlacement()
