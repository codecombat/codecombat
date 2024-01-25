require('ozaria/site/styles/play/level/goals.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/play/level/goals'
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
    'level:gather-chat-message-context': 'onGatherChatMessageContext'

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
    _.assign(@levelGoalsComponent, _.pick(e, 'overallStatus', 'timedOut', 'goals', 'goalStates', 'capstoneStage'))
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

  destroy: ->
    silentStore = { commit: _.noop, dispatch: _.noop }
    @levelGoalsComponent?.$destroy()
    @levelGoalsComponent?.$store = silentStore
    super()

  onGatherChatMessageContext: (e) ->
    context = e.chat.context
    context.goalStates = {}
    for goal in @levelGoalsComponent.goals
      continue if goal.optional or (goal.team and goal.team isnt me.team)
      goalState = @levelGoalsComponent.goalStates[goal.id]
      context.goalStates[goal.id] = name: goal.name, status: goalState?.status or 'incomplete'
      if e.chat.example
        # Add translation info, for generating permutations
        context.goalStates[goal.id].i18n = _.cloneDeep(goal.i18n ? {})
      else
        # Bake the translation in
        context.goalStates[goal.id].name = utils.i18n @goal, 'name'
        statusKey = { success: 'success', failure: 'failing', incomplete: 'incomplete' }[context.goalStates[goal.id].status]
        context.goalStates[goal.id].status = $.i18n.t("play_level.#{statusKey}")
    null
