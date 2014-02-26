SuperModel = require 'models/SuperModel'
LevelLoader = require 'lib/LevelLoader'
GoalManager = require 'lib/world/GoalManager'
God = require 'lib/God'

module.exports = class Simulator

  constructor: ->
    _.extend @, Backbone.Events
    @trigger 'statusUpdate', 'Starting simulation!'
    @retryDelayInSeconds = 10
    @taskURL = '/queue/scoring'

  fetchAndSimulateTask: =>
    @trigger 'statusUpdate', 'Fetching simulation data!'
    $.ajax
      url: @taskURL
      type: "GET"
      error: @handleFetchTaskError
      success: @setupSimulationAndLoadLevel

  handleFetchTaskError: (errorData) =>
    console.log "There were no games to score. Error: #{JSON.stringify errorData}"
    console.log "Retrying in #{@retryDelayInSeconds}"
    @trigger 'statusUpdate', 'There were no games to simulate! Trying again in 10 seconds.'

    @simulateAnotherTaskAfterDelay()

  simulateAnotherTaskAfterDelay: =>
    retryDelayInMilliseconds = @retryDelayInSeconds * 1000
    _.delay @fetchAndSimulateTask, retryDelayInMilliseconds

  setupSimulationAndLoadLevel: (taskData) =>
    @trigger 'statusUpdate', 'Setting up simulation!'
    @task = new SimulationTask(taskData)
    @supermodel = new SuperModel()
    @god = new God maxWorkerPoolSize: 1, maxAngels: 1  # Start loading worker.

    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @task.getLevelName(), sessionID: @task.getFirstSessionID(), headless: true
    @levelLoader.once 'loaded-all', @simulateGame

  simulateGame: =>
    @trigger 'statusUpdate', 'All resources loaded, simulating!', @task.getSessions()
    @assignWorldAndLevelFromLevelLoaderAndDestroyIt()
    @setupGod()

    try
      @commenceSimulationAndSetupCallback()
    catch err
      console.log "There was an error in simulation(#{err}). Trying again in #{@retryDelayInSeconds} seconds"
      @simulateAnotherTaskAfterDelay()

  assignWorldAndLevelFromLevelLoaderAndDestroyIt: ->
    @world = @levelLoader.world
    @level = @levelLoader.level
    @levelLoader.destroy()
    @levelLoader = null

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
    @trigger 'statusUpdate', 'Simulation completed, sending results back to server!'
    console.log "Sending result back to server!"
    $.ajax
      url: "/queue/scoring"
      data: results
      type: "PUT"
      success: @handleTaskResultsTransferSuccess
      error: @handleTaskResultsTransferError
      complete: @cleanupAndSimulateAnotherTask

  handleTaskResultsTransferSuccess: (result) =>
    console.log "Task registration result: #{JSON.stringify result}"
    @trigger 'statusUpdate', 'Results were successfully sent back to server!'

  handleTaskResultsTransferError: (error) =>
    @trigger 'statusUpdate', 'There was an error sending the results back to the server.'
    console.log "Task registration error: #{JSON.stringify error}"

  cleanupAndSimulateAnotherTask: =>
    @cleanupSimulation()
    @fetchAndSimulateTask()

  cleanupSimulation: ->
    @god.destroy()
    @god = null
    @world = null
    @level = null

  formTaskResultsObject: (simulationResults) ->
    taskResults =
      taskID: @task.getTaskID()
      receiptHandle: @task.getReceiptHandle()
      originalSessionID: @task.getFirstSessionID()
      originalSessionRank: -1
      calculationTime: 500
      sessions: []

    for session in @task.getSessions()
      
      sessionResult =
        sessionID: session.sessionID
        submitDate: session.submitDate
        creator: session.creator
        metrics:
          rank: @calculateSessionRank session.sessionID, simulationResults.goalStates, @task.generateTeamToSessionMap()
      if session.sessionID is taskResults.originalSessionID
        taskResults.originalSessionRank = sessionResult.metrics.rank
        taskResults.originalSessionTeam = session.team
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
    spellKeyComponents = [thang, methodName]
    spellKeyComponents[0] = _.string.slugify spellKeyComponents[0]
    spellKey = spellKeyComponents.join '/'
    spellKey
    

  createSpellAndAssignName: (spellKey, spellName) ->
    @spells[spellKey] ?= {}
    @spells[spellKey].name = spellName

  createSpellThang: (thang, method, spellKey) ->
    @spells[spellKey].thangs ?= {}
    @spells[spellKey].thangs[thang.id] ?= {}
    @spells[spellKey].thangs[thang.id].aether = @createAether @spells[spellKey].name, method

  transpileSpell: (thang, spellKey, methodName) ->
    slugifiedThangID = _.string.slugify thang.id
    source = @currentUserCodeMap[[slugifiedThangID,methodName].join '/'] ? ""
    @spells[spellKey].thangs[thang.id].aether.transpile source

  createAether: (methodName, method) ->
    aetherOptions =
      functionName: methodName
      protectAPI: false
      includeFlow: false
      #includeFlow: true
      requiresThis: true
      yieldConditionally: false
      problems:
        jshint_W040: {level: "ignore"}
        jshint_W030: {level: "ignore"}  # aether_NoEffect instead
        aether_MissingThis: {level: 'error'}
      #functionParameters: # TODOOOOO
    if methodName is 'hear'
      aetherOptions.functionParameters = ['speaker', 'message', 'data']
    #console.log "creating aether with options", aetherOptions
    return new Aether aetherOptions

class SimulationTask
  constructor: (@rawData) ->
    console.log 'Simulating sessions', (session for session in @getSessions())

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
      teamCode = {}
      for thangName, thangSpells of session.code
        for spellName, spell of thangSpells
          fullSpellName = [thangName,spellName].join '/'
          if _.contains(teamSpells, fullSpellName)
            teamCode[fullSpellName]=spell
            
      _.merge spellKeyToSourceMap, teamCode
      commonSpells = session.teamSpells["common"]
      _.merge spellKeyToSourceMap, _.pick(session.code, commonSpells) if commonSpells?

    
    spellKeyToSourceMap
