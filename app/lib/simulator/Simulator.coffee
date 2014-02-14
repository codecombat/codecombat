SuperModel = require 'models/SuperModel'
LevelLoader = require 'lib/LevelLoader'
GoalManager = require 'lib/world/GoalManager'
God = require 'lib/God'

module.exports = class Simulator

  constructor: ->
    @retryDelayInSeconds = 10
    @taskURL = '/queue/scoring'

  fetchAndSimulateTask: =>
    $.ajax
      url: @taskURL
      type: "GET"
      error: @handleFetchTaskError
      success: @setupSimulationAndLoadLevel

  handleFetchTaskError: (errorData) =>
    console.log "There were no games to score. Error: #{JSON.stringify errorData}"
    console.log "Retrying in #{@retryDelayInSeconds}"

    @simulateAnotherTaskAfterDelay()

  simulateAnotherTaskAfterDelay: =>
    retryDelayInMilliseconds = @retryDelayInSeconds * 1000
    _.delay @fetchAndSimulateTask, retryDelayInMilliseconds

  setupSimulationAndLoadLevel: (taskData) =>
    @task = new SimulationTask(taskData)
    @supermodel = new SuperModel()
    @god = new God()

    @levelLoader = new LevelLoader @task.getLevelName(), @supermodel, @task.getFirstSessionID()
    @levelLoader.once 'loaded-all', @simulateGame

  simulateGame: =>
    @assignWorldAndLevelFromLevelLoaderAndDestroyIt()
    @setupGod()

    try
      @commenceSimulationAndSetupCallback()
    catch err
      console.log "There was an error in simulation(#{err}). Trying again in #{retryDelayInSeconds} seconds"
      @simulateAnotherTaskAfterDelay()

  assignWorldAndLevelFromLevelLoaderAndDestroyIt: ->
    @world = @levelLoader.world
    @level = @levelLoader.level
    @levelLoader.destroy()

  setupGod: ->
    @god.level = @level.serialize @supermodel
    @god.worldClassMap = @world.classMap
    @setupGoalManager()
    @setupGodSpells()

  setupGoalManager: ->
    @god.goalManager = new GoalManager @world
    @god.goalManager.goals = @fetchGoalsFromWorldNoteChain()
    @god.goalManager.goalStates = @manuallyGenerateGoalStates()

  commenceSimulationAndSetupCallback: ->
    @god.createWorld()
    Backbone.Mediator.subscribeOnce 'god:new-world-created', @processResults, @

  processResults: (simulationResults) ->
    taskResults = @formTaskResultsObject simulationResults
    @sendResultsBackToServer taskResults

  sendResultsBackToServer: (results) =>
    $.ajax
      url: @taskURL
      data: results
      type: "PUT"
      success: @handleTaskResultsTransferSuccess
      error: @handleTaskResultsTransferError
      complete: @cleanupAndSimulateAnotherTask()

  handleTaskResultsTransferSuccess: (result) ->
    console.log "Task registration result: #{JSON.stringify result}"

  handleTaskResultsTransferError: (error) ->
    console.log "Task registration error: #{JSON.stringify error}"

  cleanupAndSimulateAnotherTask: =>
    @cleanupSimulation()
    @fetchAndSimulateTask()

  cleanupSimulation: ->

  formTaskResultsObject: (simulationResults) ->
    taskResults =
      taskID: @task.getTaskID()
      receiptHandle: @task.getReceiptHandle()
      calculationTime: 500
      sessions: []

    for session in @task.getSessions()
      sessionResult =
        sessionID: session.sessionID
        sessionChangedTime: session.sessionChangedTime
        metrics:
          rank: @calculateSessionRank session.sessionID, simulationResults.goalStates, @task.generateTeamToSessionMap()

      taskResults.sessions.push sessionResult

    return taskResults

  calculateSessionRank: (sessionID, goalStates, teamSessionMap) ->
    humansDestroyed = goalStates["destroy-humans"].status is "success"
    ogresDestroyed = goalStates["destroy-ogres"].status is "success"
    if humansDestroyed is ogresDestroyed
      return 0
    else if humansDestroyed and teamSessionMap["ogres"] is sessionID
      return 0
    else if humansDestroyed and teamSessionMap["ogres"] isnt sessionID
      return 1
    else if ogresDestroyed and teamSessionMap["humans"] is sessionID
      return 0
    else
      return 1

  fetchGoalsFromWorldNoteChain: -> return @god.goalManager.world.scripts[0].noteChain[0].goals.add

  manuallyGenerateGoalStates: ->
    goalStates =
      "destroy-humans":
        keyFrame: 0
        killed:
          "Human Base": false
        status: "incomplete"
      "destroy-ogres":
        keyFrame:0
        killed:
          "Ogre Base": false
        status: "incomplete"

  setupGodSpells: ->
    @generateSpellsObject()
    @god.spells = @spells

  generateSpellsObject: ->
    @currentUserCodeMap = @task.generateSpellKeyToSourceMap()
    @spells = {}
    for thang in @level.attributes.thangs
      continue if @thangIsATemplate thang
      @generateSpellKeyToSourceMapPropertiesFromThang thang

  thangIsATemplate: (thang) ->
    for component in thang.components
      continue unless @componentHasProgrammableMethods component
      for methodName, method of component.config.programmableMethods
        return true if @methodBelongsToTemplateThang method

    return false

  componentHasProgrammableMethods: (component) -> component.config? and _.has component.config, 'programmableMethods'

  methodBelongsToTemplateThang: (method) -> typeof method is 'string'

  generateSpellKeyToSourceMapPropertiesFromThang: (thang) =>
    for component in thang.components
      continue unless @componentHasProgrammableMethods component

      for methodName, method of component.config.programmableMethods
        spellKey = @generateSpellKeyFromThangIDAndMethodName thang.id, methodName

        @createSpellAndAssignName spellKey, methodName
        @createSpellThang thang, method, spellKey
        @transpileSpell thang, spellKey, methodName

  generateSpellKeyFromThangIDAndMethodName: (thang, methodName) ->
    spellKeyComponents = [thang.id, methodName]
    spellKeyComponents[0] = _.string.slugify spellKeyComponents[0]
    spellKeyComponents.join '/'

  createSpellAndAssignName: (spellKey, spellName) ->
    @spells[spellKey] ?= {}
    @spells[spellKey].name = spellName

  createSpellThang: (thang, method, spellKey) ->
    @spells[spellKey].thangs ?= {}
    @spells[spellKey].thangs[thang.id] ?= {}
    @spells[spellKey].thangs[thang.id].aether = @createAether @spells[spellKey].name, method

  transpileSpell: (thang, spellKey, methodName) ->
    slugifiedThangID = _.string.slugify thang.id
    source = @currentUserCodeMap[slugifiedThangID]?[methodName] ? ""
    @spells[spellKey].thangs[thang.id].aether.transpile source

  createAether: (methodName, method) ->
    aetherOptions =
      functionName: methodName
      protectAPI: false
      includeFlow: false
    return new Aether aetherOptions

class SimulationTask
  constructor: (@rawData) ->

  getLevelName: ->
    levelName =  @rawData.sessions?[0]?.levelID
    return levelName if levelName?
    @throwMalformedTaskError "The level name couldn't be deduced from the task."

  generateTeamToSessionMap: ->
    teamSessionMap = {}
    for session in @rawData.sessions
      @throwMalformedTaskError "Two players share the same team" if teamSessionMap[session.team]?
      teamSessionMap[session.team] = session.sessionID

    teamSessionMap

  throwMalformedTaskError: (errorString) ->
    throw new Error "The task was malformed, reason: #{errorString}"

  getFirstSessionID: -> @rawData.sessions[0].sessionID

  getTaskID: -> @rawData.taskID

  getReceiptHandle: -> @rawData.receiptHandle

  getSessions: -> @rawData.sessions

  generateSpellKeyToSourceMap: ->
    spellKeyToSourceMap = {}

    for session in @rawData.sessions
      teamSpells = session.teamSpells[session.team]
      _.merge spellKeyToSourceMap, _.pick(session.code, teamSpells)

      commonSpells = session.teamSpells["common"]
      _.merge spellKeyToSourceMap, _.pick(session.code, commonSpells) if commonSpells?

    spellKeyToSourceMap

