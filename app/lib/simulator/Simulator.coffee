SuperModel = require 'models/SuperModel'
CocoClass = require 'lib/CocoClass'
LevelLoader = require 'lib/LevelLoader'
GoalManager = require 'lib/world/GoalManager'
God = require 'lib/God'

Aether.addGlobal 'Vector', require 'lib/world/vector'
Aether.addGlobal '_', _

module.exports = class Simulator extends CocoClass

  constructor: (@options) ->
    @options ?= {}
    _.extend @, Backbone.Events
    @trigger 'statusUpdate', 'Starting simulation!'
    @retryDelayInSeconds = 10
    @taskURL = '/queue/scoring'
    @simulatedByYou = 0
    @god = new God maxAngels: 1, workerCode: @options.workerCode, headless: true  # Start loading worker.

  destroy: ->
    @off()
    @cleanupSimulation()
    @god?.destroy()
    super()

  fetchAndSimulateTask: =>
    return if @destroyed

    if @options.headlessClient
      if @dumpThisTime # The first heapdump would be useless to find leaks.
        console.log "Writing snapshot."
        @options.heapdump.writeSnapshot()
      @dumpThisTime = true if @options.heapdump

      if @options.testing
        _.delay @setupSimulationAndLoadLevel, 0, @options.testFile, "Testing...", status: 400
        return

    @trigger 'statusUpdate', 'Fetching simulation data!'
    $.ajax
      url: @taskURL
      type: "GET"
      parse: true
      error: @handleFetchTaskError
      success: @setupSimulationAndLoadLevel

  handleFetchTaskError: (errorData) =>
    console.error "There was a horrible Error: #{JSON.stringify errorData}"
    @trigger 'statusUpdate', 'There was an error fetching games to simulate. Retrying in 10 seconds.'
    @simulateAnotherTaskAfterDelay()

  handleNoGamesResponse: ->
    info = 'There were no games to simulate--all simulations are done or in process. Retrying in 10 seconds.'
    console.log info
    @trigger 'statusUpdate', info
    @simulateAnotherTaskAfterDelay()
    application.tracker?.trackEvent 'Simulator Result', label: "No Games"

  simulateAnotherTaskAfterDelay: =>
    console.log "Retrying in #{@retryDelayInSeconds}"
    retryDelayInMilliseconds = @retryDelayInSeconds * 1000
    _.delay @fetchAndSimulateTask, retryDelayInMilliseconds

  setupSimulationAndLoadLevel: (taskData, textStatus, jqXHR) =>
    return @handleNoGamesResponse() if jqXHR.status is 204
    @trigger 'statusUpdate', 'Setting up simulation!'
    @task = new SimulationTask(taskData)
    try
      levelID = @task.getLevelName()
    catch err
      console.error err
      @trigger 'statusUpdate', "Error simulating game: #{err}. Trying another game in #{@retryDelayInSeconds} seconds."
      @simulateAnotherTaskAfterDelay()
      return

    @supermodel ?= new SuperModel()
    @supermodel.resetProgress()
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: levelID, sessionID: @task.getFirstSessionID(), headless: true
    if @supermodel.finished()
      @simulateGame()
    else
      @listenToOnce @supermodel, 'loaded-all', @simulateGame

  simulateGame: ->
    return if @destroyed
    info = 'All resources loaded, simulating!'
    console.log info
    @trigger 'statusUpdate', info, @task.getSessions()
    @assignWorldAndLevelFromLevelLoaderAndDestroyIt()
    @setupGod()

    try
      @commenceSimulationAndSetupCallback()
    catch err
      console.log "There was an error in simulation(#{err}). Trying again in #{@retryDelayInSeconds} seconds"
      @simulateAnotherTaskAfterDelay()

  assignWorldAndLevelFromLevelLoaderAndDestroyIt: ->
    @world = @levelLoader.world
    @task.setWorld(@world)
    @level = @levelLoader.level
    @levelLoader.destroy()
    @levelLoader = null

  setupGod: ->
    @god.setLevel @level.serialize @supermodel
    @god.setLevelSessionIDs (session.id for session in @task.getSessions())
    @god.setWorldClassMap @world.classMap
    @god.setGoalManager new GoalManager(@world, @level.get 'goals')

  commenceSimulationAndSetupCallback: ->
    @god.createWorld @generateSpellsObject()
    Backbone.Mediator.subscribeOnce 'god:infinite-loop', @onInfiniteLoop, @
    Backbone.Mediator.subscribeOnce 'god:goals-calculated', @processResults, @

    #Search for leaks, headless-client only.
    if @options.headlessClient and @options.leakTest and not @memwatch?
      leakcount = 0
      maxleakcount = 0
      console.log "Setting leak callbacks."
      @memwatch = require 'memwatch'

      @memwatch.on 'leak', (info) =>
        console.warn "LEAK!!\n" + JSON.stringify(info)

        unless @hd?
          if (leakcount++ is maxleakcount)
            @hd = new @memwatch.HeapDiff()

            @memwatch.on 'stats', (stats) =>
              console.warn "stats callback: " + stats
              diff = @hd.end()
              console.warn "HeapDiff:\n" + JSON.stringify(diff)

              if @options.exitOnLeak
                console.warn "Exiting because of Leak."
                process.exit()
              @hd = new @memwatch.HeapDiff()

  onInfiniteLoop: ->
    console.warn "Skipping infinitely looping game."
    @trigger 'statusUpdate', "Infinite loop detected; grabbing a new game in #{@retryDelayInSeconds} seconds."
    _.delay @cleanupAndSimulateAnotherTask, @retryDelayInSeconds * 1000

  processResults: (simulationResults) ->
    taskResults = @formTaskResultsObject simulationResults
    @sendResultsBackToServer taskResults

  sendResultsBackToServer: (results) ->
    @trigger 'statusUpdate', 'Simulation completed, sending results back to server!'
    console.log "Sending result back to server!", results

    if @options.headlessClient and @options.testing
      return @fetchAndSimulateTask()

    $.ajax
      url: "/queue/scoring"
      data: results
      type: "PUT"
      parse: true
      success: @handleTaskResultsTransferSuccess
      error: @handleTaskResultsTransferError
      complete: @cleanupAndSimulateAnotherTask

  handleTaskResultsTransferSuccess: (result) =>
    console.log "Task registration result: #{JSON.stringify result}"
    @trigger 'statusUpdate', 'Results were successfully sent back to server!'
    console.log "Simulated by you: " + @simulatedByYou
    @simulatedByYou++
    unless @options.headlessClient
      simulatedBy = parseInt($('#simulated-by-you').text(), 10) + 1
      $('#simulated-by-you').text(simulatedBy)
    application.tracker?.trackEvent 'Simulator Result', label: "Success"

  handleTaskResultsTransferError: (error) =>
    @trigger 'statusUpdate', 'There was an error sending the results back to the server.'
    console.log "Task registration error: #{JSON.stringify error}"

  cleanupAndSimulateAnotherTask: =>
    @cleanupSimulation()
    @fetchAndSimulateTask()

  cleanupSimulation: ->
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
    ogreGoals = (goalState for key, goalState of goalStates when goalState.team is 'ogres')
    humanGoals = (goalState for key, goalState of goalStates when goalState.team is 'humans')
    ogresWon = _.all ogreGoals, {status: 'success'}
    humansWon = _.all humanGoals, {status: 'success'}
    if ogresWon is humansWon
      return 0
    else if ogresWon and teamSessionMap["ogres"] is sessionID
      return 0
    else if ogresWon and teamSessionMap["ogres"] isnt sessionID
      return 1
    else if humansWon and teamSessionMap["humans"] is sessionID
      return 0
    else
      return 1

  generateSpellsObject: ->
    @currentUserCodeMap = @task.generateSpellKeyToSourceMap()
    @spells = {}
    for thang in @level.attributes.thangs
      continue if @thangIsATemplate thang
      @generateSpellKeyToSourceMapPropertiesFromThang thang
    @spells

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
    spellTeam = @task.getSpellKeyToTeamMap()[spellKey]
    playerTeams = @task.getPlayerTeams()
    useProtectAPI = true
    if spellTeam not in playerTeams then useProtectAPI = false
    @spells[spellKey].thangs[thang.id].aether = @createAether @spells[spellKey].name, method, useProtectAPI


  transpileSpell: (thang, spellKey, methodName) ->
    slugifiedThangID = _.string.slugify thang.id
    generatedSpellKey = [slugifiedThangID,methodName].join '/'
    source = @currentUserCodeMap[generatedSpellKey] ? ""
    aether = @spells[spellKey].thangs[thang.id].aether
    unless _.contains(@task.spellKeysToTranspile, generatedSpellKey)
      aether.pure = source
    else
      try
        aether.transpile source
      catch e
        console.log "Couldn't transpile #{spellKey}:\n#{source}\n", e
        aether.transpile ''

  createAether: (methodName, method, useProtectAPI) ->
    aetherOptions =
      functionName: methodName
      protectAPI: useProtectAPI
      includeFlow: false
      yieldConditionally: methodName is "plan"
      globals: ['Vector', '_']
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
    @spellKeyToTeamMap = {}
    @spellKeysToTranspile = []

  getLevelName: ->
    levelName = @rawData.sessions?[0]?.levelID
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

  getSpellKeyToTeamMap: -> @spellKeyToTeamMap

  getPlayerTeams: -> _.pluck @rawData.sessions, 'team'

  setWorld: (@world) ->


  generateSpellKeyToSourceMap: ->
    playerTeams = _.pluck @rawData.sessions, 'team'
    spellKeyToSourceMap = {}
    for session in @rawData.sessions
      teamSpells = session.teamSpells[session.team]
      allTeams = _.keys session.teamSpells
      nonPlayerTeams = _.difference allTeams, playerTeams
      for team in allTeams
        for spell in session.teamSpells[team]
          @spellKeyToTeamMap[spell] = team
      for nonPlayerTeam in nonPlayerTeams
        for spell in session.teamSpells[nonPlayerTeam]
          spellKeyToSourceMap[spell] ?= @getWorldProgrammableSource(spell, @world)
          @spellKeysToTranspile.push spell
      teamCode = {}

      for thangName, thangSpells of session.transpiledCode
        for spellName, spell of thangSpells
          fullSpellName = [thangName,spellName].join '/'
          if _.contains(teamSpells, fullSpellName)
            teamCode[fullSpellName]=spell

      _.merge spellKeyToSourceMap, teamCode

    spellKeyToSourceMap

  getWorldProgrammableSource: (desiredSpellKey ,world) ->
    programmableThangs = _.filter world.thangs, 'isProgrammable'
    language = @getSessions()[0]['codeLanguage'] ? me.get('aceConfig')?.language ? 'javascript'
    @spells ?= {}
    @thangSpells ?= {}
    for thang in programmableThangs
      continue if @thangSpells[thang.id]?
      @thangSpells[thang.id] = []
      for methodName, method of thang.programmableMethods
        pathComponents = [thang.id, methodName]
        if method.cloneOf
          pathComponents[0] = method.cloneOf  # referencing another Thang's method
        pathComponents[0] = _.string.slugify pathComponents[0]
        spellKey = pathComponents.join '/'
        @thangSpells[thang.id].push spellKey
        if not method.cloneOf and spellKey is desiredSpellKey
          console.log "Setting #{desiredSpellKey} from world!"

          return method.source
