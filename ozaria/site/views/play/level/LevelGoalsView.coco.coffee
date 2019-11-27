require('ozaria/site/styles/play/level/goals.sass')
CocoView = require 'views/core/CocoView'
template = require 'ozaria/site/templates/play/level/goals.jade'
{me} = require 'core/auth'
utils = require 'core/utils'
LevelSession = require 'models/LevelSession'
Level = require 'models/Level'
LevelGoals = require('./LevelGoals').default
store = require 'core/store'


module.exports = class LevelGoalsView extends CocoView
  id: 'goals-view'
  template: template
  className: 'secret expanded'

  subscriptions:
    'goal-manager:new-goal-states': 'onNewGoalStates'
    'tome:cast-spells': 'onTomeCast'

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

    @previousGoalStatus ?= {}
    @succeeded = e.overallStatus is 'success'
    for goal in e.goals
      state = e.goalStates[goal.id] or { status: 'incomplete' }
      @previousGoalStatus[goal.id] = state.status
    if e.goals.length > 0 and @$el.hasClass 'secret'
      @$el.removeClass('secret')

  onTomeCast: (e) ->
    return if e.preload
    @levelGoalsComponent.casting = true
