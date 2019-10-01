SuperModel = require 'models/SuperModel'
CocoClass = require 'core/CocoClass'
LevelLoader = require 'lib/LevelLoader'
GoalManager = require 'lib/world/GoalManager'
God = require 'lib/God'
{createAetherOptions} = require 'lib/aether_utils'
LZString = require 'lz-string'

SIMULATOR_VERSION = 4

simulatorInfo = {}
if $.browser
  simulatorInfo['desktop'] = $.browser.desktop if $.browser.desktop
  simulatorInfo['name'] = $.browser.name if $.browser.name
  simulatorInfo['platform'] = $.browser.platform if $.browser.platform
  simulatorInfo['version'] = $.browser.versionNumber if $.browser.versionNumber

module.exports = class Simulator extends CocoClass
  constructor: (@options) ->
    @options ?= {}
    simulatorType = if @options.headlessClient then 'headless' else 'browser'
    @simulator =
      type: simulatorType
      version: SIMULATOR_VERSION
      info: simulatorInfo
    _.extend @, Backbone.Events
    @trigger 'statusUpdate', 'Starting simulation!'
    @retryDelayInSeconds = 2
    @taskURL = '/queue/scoring'
    @simulatedByYou = 0
    @god = new God maxAngels: 1, workerCode: @options.workerCode, headless: true  # Start loading worker.

  destroy: ->
    @off()
    @cleanupSimulation()
    @god?.destroy()
    super()

  fetchAndSimulateOneGame: (humanGameID, ogresGameID) =>
    return if @destroyed
    $.ajax
      url: '/queue/scoring/getTwoGames'
      type: 'POST'
      parse: true
      data:
        humansGameID: humanGameID
        ogresGameID: ogresGameID
        simulator: @simulator
        background: Boolean(@options.background)
        levelID: @options.levelID
        leagueID: @options.leagueID
      error: (errorData) ->
        console.warn "There was an error fetching two games! #{JSON.stringify errorData}"
        if errorData?.responseText?.indexOf("Old simulator") isnt -1
          noty {
            text: errorData.responseText
            layout: 'center'
            type: 'error'
          }
      success: (taskData) =>
        return if @destroyed
        unless taskData
          @retryDelayInSeconds = 10
          @trigger 'statusUpdate', "No games to simulate. Trying another game in #{@retryDelayInSeconds} seconds."
          @simulateAnotherTaskAfterDelay()
          return
        @simulatingPlayerStrings = {}
        for team in ['humans', 'ogres']
          session = _.find(taskData.sessions, {team: team})
          @simulatingPlayerStrings[team] = "#{session.creatorName or session.creator} #{session.team}"
        @trigger 'statusUpdate', "Setting up #{taskData.sessions[0].levelID} simulation between #{@simulatingPlayerStrings.humans} and #{@simulatingPlayerStrings.ogres}"
        #refactor this
        @task = new SimulationTask(taskData)

        @supermodel ?= new SuperModel()
        @supermodel.resetProgress()
        @stopListening @supermodel, 'loaded-all'
        @levelLoader = new LevelLoader supermodel: @supermodel, levelID: @task.getLevelName(), sessionID: @task.getFirstSessionID(), opponentSessionID: @task.getSecondSessionID(), headless: true

        if @supermodel.finished()
          @simulateSingleGame()
        else
          @listenToOnce @supermodel, 'loaded-all', @simulateSingleGame

  simulateSingleGame: ->
    return if @destroyed
    @assignWorldAndLevelFromLevelLoaderAndDestroyIt()
    @trigger 'statusUpdate', "Simulating match between #{@simulatingPlayerStrings.humans} and #{@simulatingPlayerStrings.ogres}"
    @setupGod()
    try
      @commenceSingleSimulation()
    catch error
      @handleSingleSimulationError error

  commenceSingleSimulation: ->
    @listenToOnce @god, 'infinite-loop', @handleSingleSimulationInfiniteLoop
    @listenToOnce @god, 'goals-calculated', @processSingleGameResults
    @god.createWorld {spells: @generateSpellsObject()}

  handleSingleSimulationError: (error) ->
    console.error 'There was an error simulating a single game!', error
    return if @destroyed
    if @options.headlessClient and @options.simulateOnlyOneGame
      console.log 'GAMERESULT:tie'
      process.exit(0)
    @cleanupAndSimulateAnotherTask()

  handleSingleSimulationInfiniteLoop: (e) ->
    console.log 'There was an infinite loop in the single game!'
    return if @destroyed
    if @options.headlessClient and @options.simulateOnlyOneGame
      console.log 'GAMERESULT:tie'
      process.exit(0)
    @cleanupAndSimulateAnotherTask()

  processSingleGameResults: (simulationResults) ->
    try
      taskResults = @formTaskResultsObject simulationResults
    catch error
      console.log "Failed to form task results:", error
      return @cleanupAndSimulateAnotherTask()
    humanSessionRank = taskResults.sessions[0].metrics.rank
    ogreSessionRank = taskResults.sessions[1].metrics.rank
    if @options.headlessClient and @options.simulateOnlyOneGame
      if humanSessionRank is ogreSessionRank
        console.log 'GAMERESULT:tie'
      else if humanSessionRank < ogreSessionRank
        console.log 'GAMERESULT:humans'
      else if ogreSessionRank < humanSessionRank
        console.log 'GAMERESULT:ogres'
      process.exit(0)
    else
      @sendSingleGameBackToServer(taskResults)

  sendSingleGameBackToServer: (results) ->
    status = 'Recording:'
    for session in results.sessions
      states = ['wins', if _.find(results.sessions, (s) -> s.metrics.rank is 0) then 'loses' else 'draws']
      status += " #{session.name} #{states[session.metrics.rank]}"
    console.log status
    @trigger 'statusUpdate', status

    $.ajax
      url: '/queue/scoring/recordTwoGames'
      data: results
      type: 'PUT'
      parse: true
      success: @handleTaskResultsTransferSuccess
      error: @handleTaskResultsTransferError
      complete: @cleanupAndSimulateAnotherTask

  fetchAndSimulateTask: =>
    return if @destroyed
    # Because there's some bug where the chained rankings don't work, let's just do getTwoGames until we fix it.
    return @fetchAndSimulateOneGame()

    if @options.headlessClient
      if @dumpThisTime # The first heapdump would be useless to find leaks.
        console.log 'Writing snapshot.'
        @options.heapdump.writeSnapshot()
      @dumpThisTime = true if @options.heapdump

      if @options.testing
        _.delay @setupSimulationAndLoadLevel, 0, @options.testFile, 'Testing...', status: 400
        return

    @trigger 'statusUpdate', 'Fetching simulation data!'
    $.ajax
      url: @taskURL
      type: 'GET'
      parse: true
      error: @handleFetchTaskError
      success: @setupSimulationAndLoadLevel
      cache: false

  handleFetchTaskError: (errorData) =>
    console.error "There was a horrible Error: #{JSON.stringify errorData}"
    @trigger 'statusUpdate', 'There was an error fetching games to simulate. Retrying in 10 seconds.'
    @simulateAnotherTaskAfterDelay()

  handleNoGamesResponse: ->
    @noTasks = true
    info = 'Finding game to simulate...'
    console.log info
    @trigger 'statusUpdate', info
    @fetchAndSimulateOneGame()

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
    @stopListening @supermodel, 'loaded-all'
    @levelLoader = new LevelLoader supermodel: @supermodel, levelID: levelID, sessionID: @task.getFirstSessionID(), opponentSessionID: @task.getSecondSessionID(), headless: true
    if @supermodel.finished()
      @simulateGame()
    else
      @listenToOnce @supermodel, 'loaded-all', @simulateGame

  simulateGame: ->
    return if @destroyed
    info = 'All resources loaded, simulating!'
    console.log info
    @assignWorldAndLevelFromLevelLoaderAndDestroyIt()
    @trigger 'statusUpdate', info, @task.getSessions()
    @setupGod()

    try
      @commenceSimulationAndSetupCallback()
    catch err
      console.error 'There was an error in simulation:', err, err.stack, "-- trying again in #{@retryDelayInSeconds} seconds"
      @simulateAnotherTaskAfterDelay()

  assignWorldAndLevelFromLevelLoaderAndDestroyIt: ->
    @world = @levelLoader.world
    @task.setWorld(@world)
    @level = @levelLoader.level
    @session = @levelLoader.session
    @otherSession = @levelLoader.opponentSession
    @levelLoader.destroy()
    @levelLoader = null

  setupGod: ->
    @god.setLevel @level.serialize {@supermodel, @session, @otherSession, headless: true, sessionless: false}
    @god.setLevelSessionIDs (session.sessionID for session in @task.getSessions())
    @god.setWorldClassMap @world.classMap
    @god.setGoalManager new GoalManager @world, @level.get('goals'), null, {
      headless: true
      additionalGoals: @level.additionalGoals
      session: @session
    }
    humanFlagHistory = _.filter @session.get('state')?.flagHistory ? [], (event) => event.source isnt 'code' and event.team is (@session.get('team') ? 'humans')
    ogreFlagHistory = _.filter @otherSession.get('state')?.flagHistory ? [], (event) => event.source isnt 'code' and event.team is (@otherSession.get('team') ? 'ogres')
    @god.lastFlagHistory = humanFlagHistory.concat ogreFlagHistory
    #console.log 'got flag history', @god.lastFlagHistory, 'from', humanFlagHistory, ogreFlagHistory, @session.get('state'), @otherSession.get('state')
    @god.lastSubmissionCount = 0  # TODO: figure out how to combine submissionCounts from both players so we can use submissionCount random seeds again.
    @god.lastDifficulty = 0

  commenceSimulationAndSetupCallback: ->
    @listenToOnce @god, 'infinite-loop', @onInfiniteLoop
    @listenToOnce @god, 'goals-calculated', @processResults
    @god.createWorld {spells: @generateSpellsObject()}

    # Search for leaks, headless-client only.
    # NOTE: Memwatch currently being ignored by Webpack, because it's only used by the server.
    if @options.headlessClient and @options.leakTest and not @memwatch?
      leakcount = 0
      maxleakcount = 0
      console.log 'Setting leak callbacks.'
      @memwatch = require 'memwatch'

      @memwatch.on 'leak', (info) =>
        console.warn "LEAK!!\n" + JSON.stringify(info)

        unless @hd?
          if (leakcount++ is maxleakcount)
            @hd = new @memwatch.HeapDiff()

            @memwatch.on 'stats', (stats) =>
              console.warn 'stats callback: ' + stats
              diff = @hd.end()
              console.warn "HeapDiff:\n" + JSON.stringify(diff)

              if @options.exitOnLeak
                console.warn 'Exiting because of Leak.'
                process.exit()
              @hd = new @memwatch.HeapDiff()

  onInfiniteLoop: (e) ->
    return if @destroyed
    console.warn 'Skipping infinitely looping game.'
    @trigger 'statusUpdate', "Infinite loop detected; grabbing a new game in #{@retryDelayInSeconds} seconds."
    _.delay @cleanupAndSimulateAnotherTask, @retryDelayInSeconds * 1000

  processResults: (simulationResults) ->
    try
      taskResults = @formTaskResultsObject simulationResults
    catch error
      console.log "Failed to form task results:", error
      return @cleanupAndSimulateAnotherTask()
    unless taskResults.taskID
      console.error "*** Error: taskResults has no taskID ***\ntaskResults:", taskResults
      @cleanupAndSimulateAnotherTask()
    else
      @sendResultsBackToServer taskResults

  sendResultsBackToServer: (results) ->
    status = 'Recording:'
    for session in results.sessions
      states = ['wins', if _.find(results.sessions, (s) -> s.metrics.rank is 0) then 'loses' else 'draws']
      status += " #{session.name} #{states[session.metrics.rank]}"
    @trigger 'statusUpdate', status
    console.log 'Sending result back to server:'
    console.log JSON.stringify results

    if @options.headlessClient and @options.testing
      return @fetchAndSimulateTask()

    $.ajax
      url: '/queue/scoring'
      data: results
      type: 'PUT'
      parse: true
      success: @handleTaskResultsTransferSuccess
      error: @handleTaskResultsTransferError
      complete: @cleanupAndSimulateAnotherTask

  handleTaskResultsTransferSuccess: (result) =>
    return if @destroyed
    #console.log "Task registration result: #{JSON.stringify result}"
    @trigger 'statusUpdate', 'Results were successfully sent back to server!'
    @simulatedByYou++
    unless @options.headlessClient
      simulatedBy = parseInt($('#simulated-by-you').text(), 10) + 1
      $('#simulated-by-you').text(simulatedBy)

  handleTaskResultsTransferError: (error) =>
    return if @destroyed
    @trigger 'statusUpdate', 'There was an error sending the results back to the server.'
    console.log "Task registration error: #{JSON.stringify error}"

  cleanupAndSimulateAnotherTask: =>
    return if @destroyed
    @cleanupSimulation()
    if @options.background or @noTasks
      @fetchAndSimulateOneGame()
    else
      @fetchAndSimulateTask()

  cleanupSimulation: ->
    @stopListening @god
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
      simulator: @simulator
      randomSeed: @task.world.randomSeed

    for session in @task.getSessions()
      sessionResult =
        sessionID: session.sessionID
        submitDate: session.submitDate
        creator: session.creator
        name: session.creatorName
        totalScore: session.totalScore
        metrics:
          rank: @calculateSessionRank session.sessionID, simulationResults.goalStates, @task.generateTeamToSessionMap()
        shouldUpdateLastOpponentSubmitDateForLeague: session.shouldUpdateLastOpponentSubmitDateForLeague
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
    else if ogresWon and teamSessionMap['ogres'] is sessionID
      return 0
    else if ogresWon and teamSessionMap['ogres'] isnt sessionID
      return 1
    else if humansWon and teamSessionMap['humans'] is sessionID
      return 0
    else
      return 1

  generateSpellsObject: ->
    spells = {}
    for {hero, team} in [{hero: 'Hero Placeholder', team: 'humans'}, {hero: 'Hero Placeholder 1', team: 'ogres'}]
      sessionInfo = _.filter(@task.getSessions(), {team: team})[0]
      fullSpellName = _.string.slugify(hero) + '/plan'
      submittedCodeLanguage = sessionInfo?.submittedCodeLanguage ? 'javascript'
      submittedCodeLanguage = 'javascript' if submittedCodeLanguage in ['clojure', 'io']  # No longer supported
      submittedCode = LZString.decompressFromUTF16 sessionInfo?.submittedCode?[_.string.slugify(hero)]?.plan ? ''
      aether = new Aether createAetherOptions functionName: 'plan', codeLanguage: submittedCodeLanguage, skipProtectAPI: false
      try
        aether.transpile submittedCode
      catch e
        console.log "Couldn't transpile #{fullSpellName}:\n#{submittedCode}\n", e
        aether.transpile ''
      spells[fullSpellName] = name: 'plan', team: team, thang: {thang: {id: hero}, aether: aether}
    spells


class SimulationTask
  constructor: (@rawData) ->

  getLevelName: ->
    levelName = @rawData.sessions?[0]?.levelID
    return levelName if levelName?
    @throwMalformedTaskError 'The level name couldn\'t be deduced from the task.'

  generateTeamToSessionMap: ->
    teamSessionMap = {}
    for session in @rawData.sessions
      @throwMalformedTaskError 'Two players share the same team' if teamSessionMap[session.team]?
      teamSessionMap[session.team] = session.sessionID

    teamSessionMap

  throwMalformedTaskError: (errorString) ->
    throw new Error "The task was malformed, reason: #{errorString}"

  getFirstSessionID: -> @rawData.sessions[0].sessionID

  getSecondSessionID: -> @rawData.sessions[1].sessionID

  getTaskID: -> @rawData.taskID

  getReceiptHandle: -> @rawData.receiptHandle

  getSessions: -> @rawData.sessions

  setWorld: (@world) ->
