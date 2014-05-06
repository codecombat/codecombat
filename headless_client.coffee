###
This file will simulate games on node.js by emulating the browser environment.
At some point, most of the code can be merged with Simulator.coffee
###

# SETTINGS
debug = false # Enable logging of ajax calls mainly
testing = false # Instead of simulating 'real' games, use the same one over and over again. Good for leak hunting.
leaktest = false # Install callback that tries to find leaks automatically
exitOnLeak = false # Exit if leak is found. Only useful if leaktest is set to true, obviously.
heapdump = false # Dumps the whole heap after every pass. The heap dumps can then be viewed in Chrome browser.

server = if testing then "http://127.0.0.1:3000" else "http://codecombat.com"

# Disabled modules
disable = [
  'lib/AudioPlayer'
  'locale/locale'
  '../locale/locale'
]

bowerComponents = "./bower_components/"
headlessClient = "./headless_client/"


# Start of the actual code. Setting up the enivronment to match the environment of the browser
heapdump = require('heapdump') if heapdump

# the path used for the loader. __dirname is module dependent.
path = __dirname

m = require 'module'
request = require 'request'

originalLoader = m._load

unhook = () ->
  m._load = originalLoader

hook = () ->
  m._load = hookedLoader


JASON = require 'jason'

# Global emulated stuff
GLOBAL.window = GLOBAL
GLOBAL.Worker = require('webworker-threads').Worker
Worker::removeEventListener = (what) ->
  if what is 'message'
    @onmessage = -> #This webworker api has only one event listener at a time.

GLOBAL.tv4 = require('tv4').tv4

GLOBAL.marked = setOptions: ->

GLOBAL.navigator =
#  userAgent: "nodejs"
  platform: "headless_client"
  vendor: "codecombat"
  opera: false

store = {}
GLOBAL.localStorage =
    getItem: (key) => store[key]
    setItem: (key, s) => store[key] = s
    removeItem: (key) => delete store[key]

# Hook node.js require. See https://github.com/mfncooper/mockery/blob/master/mockery.js
# The signature of this function *must* match that of Node's Module._load,
# since it will replace that.
# (Why is there no easier way?)
hookedLoader = (request, parent, isMain) ->
  #if request is 'lib/god'
  #  console.log 'I choose you, SimpleGod.'
  #  request = './headless_client/SimpleGod'
  #else
  if request in disable or ~request.indexOf('templates')
    console.log 'Ignored ' + request if debug
    return class fake
  else if '/' in request and not (request[0] is '.') or request is 'application'
    request = path + '/app/' + request
  else if request is 'underscore'
    request = 'lodash'

  console.log "loading " + request if debug
  originalLoader request, parent, isMain


#jQuery wrapped for compatibility purposes. Poorly.
GLOBAL.$ = GLOBAL.jQuery = (input) ->
  console.log 'Ignored jQuery: ' + input if debug
  append: (input)-> exports: ()->

cookies = request.jar()

$.ajax = (options) ->
  responded = false
  url = options.url
  if url.indexOf('http')
    url = '/' + url unless url[0] is '/'
    url = server + url

  data = options.data


  #if (typeof data) is 'object'
    #console.warn JSON.stringify data
    #data = JSON.stringify data

  console.log "Requesting: " + JSON.stringify options if debug
  console.log "URL: " + url if debug
  request
    url: url
    jar: cookies
    json: options.parse
    method: options.type
    body: data
    , (error, response, body) ->
      console.log "HTTP Request:" + JSON.stringify options if debug and not error

      if responded
        console.log "\t↳Already returned before." if debug
        return

      if (error)
        console.warn "\t↳Returned: error: #{error}"
        options.error(error) if options.error?
      else
        console.log "\t↳Returned: statusCode #{response.statusCode}: #{if options.parse then JSON.stringify body else body}" if debug
        options.success(body, response, status: response.statusCode) if options.success?


      statusCode = response.statusCode if response?
      options.complete(status: statusCode) if options.complete?
      responded = true

$.extend = (deep, into, from) ->
  copy = _.clone(from, deep);
  if into
    _.assign into, copy
    copy = into
  copy

$.isArray = (object) ->
  _.isArray object

$.isPlainObject = (object) ->
  _.isPlainObject object


do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.string = _.str
  _.mixin _.str.exports()


# load Backbone. Needs hooked loader to reroute underscore to lodash.
hook()
GLOBAL.Backbone = require bowerComponents + 'backbone/backbone'
unhook()
Backbone.$ = $

require bowerComponents + 'validated-backbone-mediator/backbone-mediator'
# Instead of mediator, dummy might be faster yet suffice?
#Mediator = class Mediator
#  publish: (id, object) ->
#    console.Log "Published #{id}: #{object}"
#  @subscribe: () ->
#  @unsubscribe: () ->

GLOBAL.Aether = require 'aether'

# Set up new loader.
hook()

login = require './login.coffee' #should contain an object containing they keys 'username' and 'password'


#Login user and start the code.
$.ajax
  url: '/auth/login'
  type: "POST"
  data: login
  parse: true
  error: (error) -> "Bad Error. Can't connect to server or something. " + error
  success: (response) ->
    console.log "User: " + response
    GLOBAL.window.userObject = response # JSON.parse response

    User = require 'models/User'

    World = require 'lib/world/world'
    LevelLoader = require 'lib/LevelLoader'
    GoalManager = require 'lib/world/GoalManager'

    God = require 'lib/Buddha'

    workerCode = require headlessClient + 'worker_world'

    SuperModel = require 'models/SuperModel'

    log = require 'winston'

    CocoClass = require 'lib/CocoClass'

    class Simulator extends CocoClass

      constructor: ->
        _.extend @, Backbone.Events
        @trigger 'statusUpdate', 'Starting simulation!'
        @retryDelayInSeconds = 10
        @taskURL = 'queue/scoring'
        @simulatedByYou = 0

        @god = new God maxWorkerPoolSize: 1, maxAngels: 1, workerCode: workerCode # Start loading worker.

      destroy: ->
        @off()
        @cleanupSimulation()
        super()

      fetchAndSimulateTask: =>
        return if @destroyed

        if testing
          test = require headlessClient + 'test.js'
          console.log test
          _.delay @setupSimulationAndLoadLevel, 0, test, "Testing...", status: 400
          return

        if @ranonce and heapdump
          console.log "Writing snapshot."
          heapdump.writeSnapshot()
        @ranonce = true

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
        console.log "Nothing to do."
        @trigger 'statusUpdate', 'There were no games to simulate--nice. Retrying in 10 seconds.'
        @simulateAnotherTaskAfterDelay()

      simulateAnotherTaskAfterDelay: =>
        console.log "Retrying..."
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

        #console.log "Creating loader with levelID: " + levelID + " and SessionID: " + @task.getFirstSessionID() + " - task: " + JSON.stringify(@task)

        @levelLoader = new LevelLoader supermodel: @supermodel, levelID: levelID, sessionID: @task.getFirstSessionID(), headless: true

        console.log "Waiting for loaded game"

        @listenToOnce(@levelLoader, 'loaded-all', @simulateGame)

      simulateGame: ->
        console.warn "Simulate game."
        return if @destroyed
        @trigger 'statusUpdate', 'All resources loaded, simulating!', @task.getSessions()
        console.log "assignWorld"
        @assignWorldAndLevelFromLevelLoaderAndDestroyIt()
        console.log "SetupGod"
        @setupGod()
        try
          @commenceSimulationAndSetupCallback()
        catch err
          console.log "There was an error in simulation(#{err}). Trying again in #{@retryDelayInSeconds} seconds"

          #TODO: Comment out.
          throw err

          @simulateAnotherTaskAfterDelay()

      assignWorldAndLevelFromLevelLoaderAndDestroyIt: ->
        console.log "Assigning world and level"
        @world = @levelLoader.world
        @level = @levelLoader.level
        @levelLoader.destroy()
        @levelLoader = null

      setupGod: ->
        @god.level = @level.serialize @supermodel
        @god.setWorldClassMap @world.classMap
        @setupGoalManager()

      setupGoalManager: ->
        goalManager = new GoalManager @world
        goalManager.goals = @god.level.goals
        goalManager.goalStates = @manuallyGenerateGoalStates()
        @god.setGoalManager goalManager

      commenceSimulationAndSetupCallback: ->
        console.log "Creating World."
        @god.createWorld(@generateSpellsObject())
        Backbone.Mediator.subscribeOnce 'god:infinite-loop', @onInfiniteLoop, @
        Backbone.Mediator.subscribeOnce 'god:goals-calculated', @processResults, @

        #Search for leaks
        if leaktest and not @memwatch?
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

                  if exitOnLeak
                    console.warn "Exiting because of Leak."
                    process.exit()
                  @hd = new @memwatch.HeapDiff()



      onInfiniteLoop: ->
        console.warn "Skipping infinitely looping game."
        @trigger 'statusUpdate', "Infinite loop detected; grabbing a new game in #{@retryDelayInSeconds} seconds."
        _.delay @cleanupAndSimulateAnotherTask, @retryDelayInSeconds * 1000

      processResults: (simulationResults) ->

        console.log "Processing Results"

        taskResults = @formTaskResultsObject simulationResults
        console.warn taskResults
        @sendResultsBackToServer taskResults

      sendResultsBackToServer: (results) =>
        @trigger 'statusUpdate', 'Simulation completed, sending results back to server!'
        console.log "Sending result back to server"

        if testing
          return @fetchAndSimulateTask()

        $.ajax
          url: "queue/scoring"
          data: results
          parse: true
          type: "PUT"
          success: @handleTaskResultsTransferSuccess
          error: @handleTaskResultsTransferError
          complete: @cleanupAndSimulateAnotherTask

      handleTaskResultsTransferSuccess: (result) =>
        console.log "Task registration result: #{JSON.stringify result}"
        @trigger 'statusUpdate', 'Results were successfully sent back to server!'
        console.log "Simulated by you: " + @simulatedByYou
        @simulatedByYou++

      handleTaskResultsTransferError: (error) =>
        @trigger 'statusUpdate', 'There was an error sending the results back to the server.'
        console.log "Task registration error: #{JSON.stringify error}"

      cleanupAndSimulateAnotherTask: =>
        #@cleanupSimulation()      Not needed for Buddha.
        @fetchAndSimulateTask()

      cleanupSimulation: ->
        @god?.destroy()
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
        aether = @spells[spellKey].thangs[thang.id].aether
        try
          aether.transpile source
        catch e
          console.log "Couldn't transpile #{spellKey}:\n#{source}\n", e
          aether.transpile ''

      createAether: (methodName, method) ->
        aetherOptions =
          functionName: methodName
          protectAPI: true
          includeFlow: false
          requiresThis: true
          yieldConditionally: false
          problems:
            jshint_W040: {level: "ignore"}
            jshint_W030: {level: "ignore"}  # aether_NoEffect instead
            aether_MissingThis: {level: 'error'}
        if methodName is 'hear'
          aetherOptions.functionParameters = ['speaker', 'message', 'data']
        #console.log "creating aether with options", aetherOptions

        return new Aether aetherOptions

    class SimulationTask
      constructor: (@rawData) ->
        #console.log 'Simulating sessions', (session for session in @getSessions())

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

    sim = new Simulator()


    sim.fetchAndSimulateTask()