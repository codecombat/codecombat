CocoClass = require 'core/CocoClass'
utils = require 'core/utils'

module.exports = class GoalManager extends CocoClass
  # The Goal Manager is created both on the main thread and
  # each time the world is generated. The one in world generation
  # records which code and world related goals
  # are completed or failed, and then the results are sent back
  # and saved to the main thread instance.
  # The main instance handles goals based on UI notifications,
  # and keeps track of what the goals are at any given point.

  # Goals can only have only one goal property. Otherwise who knows what will happen.
  # If you want weird goals or hybrid goals, make a custom goal.

  nextGoalID: 0
  nicks: ['GoalManager']

  constructor: (@world, @initialGoals, @team, options) ->
    super()
    @options = options or {}
    @init()

  init: ->
    @goals = []
    @goalStates = {} # goalID -> object (complete, frameCompleted)
    @userCodeMap = {} # @userCodeMap.thangID.methodName.aether.raw = codeString
    @thangTeams = {}
    @initThangTeams()
    @addGoal goal for goal in @initialGoals if @initialGoals
    if @options?.session and @options?.additionalGoals
      state = @options.session.get('state')
      capstoneStage = state.capstoneStage
      stages = _.filter(@options.additionalGoals, (ag) -> ag.stage <= capstoneStage)
      goals = _.map(stages, (stage) -> stage.goals)
      unwrappedGoals = _.flatten(goals)
      @addGoal goal for goal in unwrappedGoals

  initThangTeams: ->
    return unless @world
    for thang in @world.thangs when thang.team and thang.isAttackable
      continue unless thang.team
      @thangTeams[thang.team] = [] unless @thangTeams[thang.team]
      @thangTeams[thang.team].push(thang.id)

  subscriptions:
    'god:new-world-created': 'onNewWorldCreated'
    'god:new-html-goal-states': 'onNewHTMLGoalStates'
    'level:restarted': 'onLevelRestarted'

  backgroundSubscriptions:
    'world:thang-died': 'onThangDied'
    'world:thang-touched-goal': 'onThangTouchedGoal'
    'world:thang-left-map': 'onThangLeftMap'
    'world:thang-collected-item': 'onThangCollectedItem'
    'world:user-code-problem': 'onUserCodeProblem'
    'world:lines-of-code-counted': 'onLinesOfCodeCounted'

  onLevelRestarted: ->
    @goals = []
    @goalStates = {}
    @userCodeMap = {}
    @notifyGoalChanges()
    @addGoal goal for goal in @initialGoals if @initialGoals

  # INTERFACE AND LIFETIME OVERVIEW

  # world generator gets current goals from the main instance
  getGoals: -> @goals

  getRemainingGoals: -> _.filter(@goalStates, (state) -> state.status != 'success')

  # background instance created by world generator,
  # gets these goals and code, and is told to be all ears during world gen
  setGoals: (@goals) ->
  setCode: (@userCodeMap) -> @updateCodeGoalStates()
  worldGenerationWillBegin: ->
    @initGoalStates()
    @checkForInitialUserCodeProblems()

  # World generator feeds world events to the goal manager to keep track
  submitWorldGenerationEvent: (channel, event, frameNumber) ->
    func = @backgroundSubscriptions[channel]
    func = utils.normalizeFunc(func, @)
    return unless func
    func.call(@, event, frameNumber)

  # after world generation, generated goal states
  # are grabbed to send back to main instance
  worldGenerationEnded: (finalFrame) -> @wrapUpGoalStates(finalFrame)
  getGoalStates: -> @goalStates

  # main instance gets them and updates their existing goal states,
  # passes the word along
  onNewWorldCreated: (e) ->
    @world = e.world
    @updateGoalStates(e.goalStates) if e.goalStates?

  onNewHTMLGoalStates: (e) ->
    @updateGoalStates(e.goalStates) if e.goalStates?

  updateGoalStates: (newGoalStates) ->
    for goalID, goalState of newGoalStates
      continue unless @goalStates[goalID]?
      @goalStates[goalID] = goalState
    @notifyGoalChanges()

  # Adds any goals for the current capstoneStage
  # Returns the current capstoneStage
  addAdditionalGoals: (session, additionalGoals) ->
    capstoneStage = (session.get('state') or {}).capstoneStage
    if not capstoneStage
      # In daily speak, we think of initial goals as stage 1 and additional goals
      # as stage 2 and above. That is why we are starting from 2.
      capstoneStage = 2
    else
      # The capstoneStage will eventually end up being 1 above the final
      # additionalStage, when the entire level has been completed.
      capstoneStage += 1
    goalsAdded = false
    _.forEach(additionalGoals, (stageGoals) =>
      if stageGoals.stage == capstoneStage
        _.forEach(stageGoals.goals, (goal) =>
          if not _.find(@goals, (existingGoal) -> goal.id == existingGoal.id)
            @addGoal(goal)
            goalsAdded = true
        )
    )
    if goalsAdded
      state = session.get('state') ? {}
      state.capstoneStage = capstoneStage
      session.set('state', state)
      session.save(null, { success: -> }) # Save and move on, we don't have time to wait here

    return capstoneStage

  # Checks if the overall goal status is 'success', then progresses
  # capstone goals to the next stage if there are more goals
  finishLevel: ->
    stageFinished = @checkOverallStatus() is 'success'
    if @options.additionalGoals and stageFinished
      @addAdditionalGoals(@options.session, @options.additionalGoals)

    return stageFinished

  # IMPLEMENTATION DETAILS

  addGoal: (goal) ->
    goal = $.extend(true, {}, goal)
    goal.id = @nextGoalID++ if not goal.id
    return if @goalStates[goal.id]?
    @goals.push(goal)
    goal.isPositive = @goalIsPositive goal.id
    @goalStates[goal.id] = {status: 'incomplete', keyFrame: 0, team: goal.team}
    @notifyGoalChanges()
    return unless goal.notificationGoal
    f = (channel) => (event) => @onNote(channel, event)
    channel = goal.notificationGoal.channel
    @addNewSubscription(channel, f(channel))

  notifyGoalChanges: ->
    return if @options.headless
    overallStatus = @checkOverallStatus()
    event =
      goalStates: @goalStates
      goals: @goals
      overallStatus: overallStatus
      timedOut: @world? and (@world.totalFrames is @world.maxTotalFrames and overallStatus not in ['success', 'failure'])
    Backbone.Mediator.publish('goal-manager:new-goal-states', event)

  checkOverallStatus: (ignoreIncomplete=false) ->
    overallStatus = null
    goals = if @goalStates then _.values @goalStates else []
    goals = (g for g in goals when not g.optional)
    goals = (g for g in goals when g.team in [undefined, @team]) if @team
    statuses = (goal.status for goal in goals)
    isSuccess = (s) -> s is 'success' or (ignoreIncomplete and s is null)
    if _.any(goals.map((g) => g.concepts?.length))
      conceptStatuses = goals.filter((g) => g.concepts?.length).map((g) => g.status)
      levelStatuses = goals.filter((g) => !g.concepts?.length).map((g) => g.status)
      overallStatus = if _.all(levelStatuses, isSuccess) and _.any(conceptStatuses, isSuccess) then 'success' else 'failure'
    else
      overallStatus = 'success' if statuses.length > 0 and _.every(statuses, isSuccess)
      overallStatus = 'failure' if statuses.length > 0 and 'failure' in statuses
    overallStatus

  # WORLD GOAL TRACKING

  initGoalStates: ->
    @goalStates = {}
    return unless @goals
    for goal in @goals
      state = {
        status: null # should eventually be either 'success', 'failure', or 'incomplete'
        keyFrame: 0 # when it became a 'success' or 'failure'
        team: goal.team
        optional: goal.optional
        hiddenGoal: goal.hiddenGoal
        concepts: goal.concepts
      }
      @initGoalState(state, [goal.killThangs, goal.saveThangs], 'killed')
      for getTo in goal.getAllToLocations ? []
        @initGoalState(state, [getTo.getToLocation?.who, []], 'arrived')
      for keepFrom in goal.keepAllFromLocations ? []
        @initGoalState(state, [[], keepFrom.keepFromLocation?.who], 'arrived')
      @initGoalState(state, [goal.getToLocations?.who, goal.keepFromLocations?.who], 'arrived')
      @initGoalState(state, [goal.leaveOffSides?.who, goal.keepFromLeavingOffSides?.who], 'left')
      @initGoalState(state, [goal.collectThangs?.targets, goal.keepFromCollectingThangs?.targets], 'collected')
      @initGoalState(state, [goal.codeProblems], 'problems')
      @initGoalState(state, [_.keys(goal.linesOfCode ? {})], 'lines')
      @goalStates[goal.id] = state

  checkForInitialUserCodeProblems: ->
    # There might have been some user code problems reported before the goal manager started listening.
    return unless @world
    for thang in @world.thangs when thang.isProgrammable
      for message, problem of thang.publishedUserCodeProblems
        @onUserCodeProblem {thang: thang, problem: problem}, 0

  onThangDied: (e, frameNumber) ->
    for goal in @goals ? []
      @checkKillThangs(goal.id, goal.killThangs, e.thang, frameNumber) if goal.killThangs?
      @checkKillThangs(goal.id, goal.saveThangs, e.thang, frameNumber) if goal.saveThangs?

  checkKillThangs: (goalID, targets, thang, frameNumber) ->
    return unless thang.id in targets or thang.team in targets
    @updateGoalState(goalID, thang.id, 'killed', frameNumber)

  onThangTouchedGoal: (e, frameNumber) ->
    for goal in @goals ? []
      @checkArrived(goal.id, goal.getToLocations.who, goal.getToLocations.targets, e.actor, e.touched.id, frameNumber) if goal.getToLocations?
      if goal.getAllToLocations?
        for getTo in goal.getAllToLocations
          @checkArrived(goal.id, getTo.getToLocation.who, getTo.getToLocation.targets, e.actor, e.touched.id, frameNumber)
      @checkArrived(goal.id, goal.keepFromLocations.who, goal.keepFromLocations.targets, e.actor, e.touched.id, frameNumber) if goal.keepFromLocations?
      if goal.keepAllFromLocations?
        for keepFrom in goal.keepAllFromLocations
          @checkArrived(goal.id, keepFrom.keepFromLocation.who , keepFrom.keepFromLocation.targets, e.actor, e.touched.id, frameNumber )

  checkArrived: (goalID, who, targets, thang, touchedID, frameNumber) ->
    return unless touchedID in targets
    return unless thang.id in who or thang.team in who
    @updateGoalState(goalID, thang.id, 'arrived', frameNumber)

  onThangLeftMap: (e, frameNumber) ->
    for goal in @goals ? []
      @checkLeft(goal.id, goal.leaveOffSides.who, goal.leaveOffSides.sides, e.thang, e.side, frameNumber) if goal.leaveOffSides?
      @checkLeft(goal.id, goal.keepFromLeavingOffSides.who, goal.keepFromLeavingOffSides.sides, e.thang, e.side, frameNumber) if goal.keepFromLeavingOffSides?

  checkLeft: (goalID, who, sides, thang, side, frameNumber) ->
    return if sides and side and not (side in sides)
    return unless thang.id in who or thang.team in who
    @updateGoalState(goalID, thang.id, 'left', frameNumber)

  onThangCollectedItem: (e, frameNumber) ->
    for goal in @goals ? []
      @checkCollected(goal.id, goal.collectThangs.who, goal.collectThangs.targets, e.actor, e.item.id, frameNumber) if goal.collectThangs?
      @checkCollected(goal.id, goal.keepFromCollectingThangs.who, goal.keepFromCollectingThangs.targets, e.actor, e.item.id, frameNumber) if goal.keepFromCollectingThangs?

  checkCollected: (goalID, who, targets, thang, itemID, frameNumber) ->
    return unless itemID in targets
    return unless thang.id in who or thang.team in who
    @updateGoalState(goalID, itemID, 'collected', frameNumber)

  onUserCodeProblem: (e, frameNumber) ->
    for goal in @goals ? [] when goal.codeProblems
      @checkCodeProblem goal.id, goal.codeProblems, e.thang, frameNumber

  checkCodeProblem: (goalID, who, thang, frameNumber) ->
    return unless thang.id in who or thang.team in who
    @updateGoalState goalID, thang.id, 'problems', frameNumber

  onLinesOfCodeCounted: (e, frameNumber) ->
    for goal in @goals ? [] when goal.linesOfCode
      @checkLinesOfCode goal.id, goal.linesOfCode, e.thang, e.linesUsed, frameNumber

  checkLinesOfCode: (goalID, who, thang, linesUsed, frameNumber) ->
    return unless linesAllowed = who[thang.id] ? who[thang.team]
    @updateGoalState goalID, thang.id, 'lines', frameNumber if linesUsed > linesAllowed

  wrapUpGoalStates: (finalFrame) ->
    for goalID, state of @goalStates
      if state.status is null
        if @goalIsPositive(goalID)
          state.status = 'incomplete'
        else
          state.status = 'success'
          state.keyFrame = 'end' # special case for objective UI to handle

  # UI EVENT GOAL TRACKING

  onNote: (channel, e) ->
    # TODO for UI event related goals

  # HELPER FUNCTIONS

  # It's a pretty similar pattern for each of the above goals.
  # Once you determine a thang has done the thing, you mark it done in the progress object.
  initGoalState: (state, whos, progressObjectName) ->
    # 'whos' is an array of goal 'who' values.
    # This inits the progress object for the goal tracking.

    arrays = (prop for prop in whos when prop?.length)
    return unless arrays.length
    state[progressObjectName] ?= {}
    for array in arrays
      for thang in array
        if @thangTeams[thang]?
          for t in @thangTeams[thang]
            state[progressObjectName][t] = false
        else
          state[progressObjectName][thang] = false

  getGoalState: (goalID) ->
    @goalStates[goalID].status

  setGoalState: (goalID, status) ->
    state = @goalStates[goalID]
    if not state
      console.log('Could not set state for goalID ', goalID)
      return

    state.status = status
    if overallStatus = @checkOverallStatus true
      matchedGoals = (_.find(@goals, {id: goalID}) for goalID, goalState of @goalStates when goalState.status is overallStatus)
      mostEagerGoal = _.min matchedGoals, 'worldEndsAfter'
      victory = overallStatus is 'success'
      tentative = overallStatus is 'success'
      @world?.endWorld victory, mostEagerGoal.worldEndsAfter, tentative if mostEagerGoal isnt Infinity

  updateGoalState: (goalID, thangID, progressObjectName, frameNumber) ->
    # A thang has done something related to the goal!
    # Mark it down and update the goal state.
    goal = _.find @goals, {id: goalID}
    state = @goalStates[goalID]
    stateThangs = state[progressObjectName]
    stateThangs[thangID] = true
    success = @goalIsPositive goalID
    if success
      numNeeded = goal.howMany ? Math.max(1, _.size stateThangs)
    else
      # saveThangs: by default we would want to save all the Thangs, which means that we would want none of them to be 'done'
      numNeeded = _.size(stateThangs) - Math.max((goal.howMany ? 1), _.size stateThangs) + 1
    numDone = _.filter(stateThangs).length
    #console.log 'needed', numNeeded, 'done', numDone, 'of total', _.size(stateThangs), 'with how many', goal.howMany, 'and stateThangs', stateThangs, 'for', goalID, thangID, 'on frame', frameNumber, 'all Thangs', _.keys(stateThangs), _.values(stateThangs)
    return unless numDone >= numNeeded
    return if state.status and not success  # already failed it; don't wipe keyframe
    state.status = if success then 'success' else 'failure'
    state.keyFrame = frameNumber
    #console.log goalID, 'became', success, 'on frame', frameNumber, 'with overallStatus', @checkOverallStatus true
    if overallStatus = @checkOverallStatus true
      matchedGoals = (_.find(@goals, {id: goalID}) for goalID, goalState of @goalStates when goalState.status is overallStatus)
      mostEagerGoal = _.min matchedGoals, 'worldEndsAfter'
      victory = overallStatus is 'success'
      tentative = overallStatus is 'success'
      @world?.endWorld victory, mostEagerGoal.worldEndsAfter, tentative if mostEagerGoal isnt Infinity

  goalIsPositive: (goalID) ->
    # Positive goals are completed when all conditions are true (kill all these thangs)
    # Negative goals fail when any are true (keep all these thangs from being killed)
    goal = _.find(@goals, {id: goalID}) ? {}
    return false for prop of goal when @positiveGoalMap[prop] is 0
    true

  positiveGoalMap:
    killThangs: 1
    saveThangs: 0
    getToLocations: 1
    getAllToLocations: 1
    keepFromLocations: 0
    keepAllFromLocations: 0
    leaveOffSides: 1
    keepFromLeavingOffSides: 0
    collectThangs: 1
    keepFromCollectingThangs: 0
    linesOfCode: 0
    codeProblems: 0

  updateCodeGoalStates: ->
    # TODO

  # teardown

  destroy: ->
    super()
