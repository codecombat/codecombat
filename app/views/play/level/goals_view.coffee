View = require 'views/kinds/CocoView'
template = require 'templates/play/level/goals'
{me} = require 'lib/auth'

stateIconMap =
  incomplete: 'icon-minus'
  success: 'icon-ok'
  failure: 'icon-remove'

module.exports = class GoalsView extends View
  id: "goals-view"
  template: template

  subscriptions:
    'goal-manager:new-goal-states': 'onNewGoalStates'
    'level-set-letterbox': 'onSetLetterbox'

  events:
    'click': 'toggleCollapse'

  toggleCollapse: (e) =>
    @$el.toggleClass('expanded').toggleClass('collapsed')

  onNewGoalStates: (e) ->
    list = $('#primary-goals-list', @$el)
    list.empty()
    goals = []
    for goal in e.goals
      state = e.goalStates[goal.id]
      continue if goal.hiddenGoal and state.status isnt 'failure'
      text = goal.i18n?[me.lang()]?.name ? goal.name
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
    if goals.length then @$el.removeClass('hide') else @$el.addClass('hide')

  render: ->
    super()
    @$el.addClass('hide').addClass('expanded')

  onSetLetterbox: (e) ->
    if e.on then @$el.hide() else @$el.show()
