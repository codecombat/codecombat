# NOTE: Dependencies for this may not be cache-busted properly by webpack; take this into account when making changes.

# function to use inside a webworker.
# This function needs to run inside an environment that has a 'self'.
# This specific worker is targeted towards the node.js headless_client environment.

fs = require 'fs'
# GLOBAL.Aether = Aether = require 'aether' # TODO: fix with webpack
GLOBAL._ = _ = require 'lodash'
GLOBAL.CoffeeScript = require 'coffee-script'

betterConsole = () ->

  self.logLimit = 200
  self.logsLogged = 0

  self.transferableSupported = () -> true

  self.console = log: (args...) ->
    if self.logsLogged++ is self.logLimit
      self.postMessage
        type: 'console-log'
        args: ['Log limit ' + self.logLimit + ' reached; shutting up.']
        id: self.workerID

    else if self.logsLogged < self.logLimit
      i = 0

      while i < args.length
        args[i] = args[i].toString() if args[i].constructor.className is 'Thang' or args[i].isComponent if args[i] and args[i].constructor
        ++i
      try
        self.postMessage
          type: 'console-log'
          args: args
          id: self.workerID

      catch error
        self.postMessage
          type: 'console-log'
          args: [
              'Could not post log: ' + args
              error.toString()
              error.stack
              error.stackTrace
          ]
          id: self.workerID

  # so that we don't crash when debugging statements happen
  self.console.error = self.console.warn = self.console.info = self.console.debug = self.console.log
  GLOBAL.console = console = self.console
  self.console

work = () ->
  console.log 'starting...'

  console.log = ->

  World = self.require('lib/world/world')
  GoalManager = self.require('lib/world/GoalManager')

  Aether.addGlobal('Vector', require('lib/world/vector'))
  Aether.addGlobal('_', _)

  self.cleanUp = ->
    self.world = null
    self.goalManager = null
    self.postedErrors = {}
    self.t0 = null
    self.logsLogged = 0

  self.runWorld = (args) ->
    console.log 'Running world inside worker.'
    self.postedErrors = {}
    self.t0 = new Date()
    self.postedErrors = false
    self.logsLogged = 0

    try
      self.world = new World(args.userCodeMap)
      self.world.levelSessionIDs = args.levelSessionIDs
      self.world.submissionCount = args.submissionCount
      self.world.flagHistory = args.flagHistory
      self.world.difficulty = args.difficulty
      self.world.loadFromLevel args.level, true if args.level
      self.world.headless = args.headless
      self.goalManager = new GoalManager(self.world)
      self.goalManager.setGoals args.goals
      self.goalManager.setCode args.userCodeMap
      self.goalManager.worldGenerationWillBegin()
      self.world.setGoalManager self.goalManager
    catch error
      console.log 'There has been an error inside the worker.'
      self.onWorldError error
      return
    Math.random = self.world.rand.randf # so user code is predictable
    Aether.replaceBuiltin('Math', Math)
    replacedLoDash = _.runInContext(self)
    _[key] = replacedLoDash[key] for key, val of replacedLoDash
    console.log 'Loading frames.'

    self.postMessage type: 'start-load-frames'

    self.world.loadFrames self.onWorldLoaded, self.onWorldError, self.onWorldLoadProgress, null, true

  self.onWorldLoaded = onWorldLoaded = ->
    self.goalManager.worldGenerationEnded()
    goalStates = self.goalManager.getGoalStates()
    self.postMessage type: 'end-load-frames', goalStates: goalStates, overallStatus: goalManager.checkOverallStatus()

    t1 = new Date()
    diff = t1 - self.t0
    if (self.world.headless)
      return console.log("Headless simulation completed in #{diff}ms.")

    transferableSupported = self.transferableSupported()
    try
      serialized = serializedWorld: self.world.serialize()
      transferableSupported = false
    catch error
      console.log 'World serialization error:', error.toString() + "\n" + error.stack or error.stackTrace
    t2 = new Date()

    # console.log('About to transfer', serialized.serializedWorld.trackedPropertiesPerThangValues, serialized.transferableObjects);
    try
      message =
        type: 'new-world'
        serialized: serialized.serializedWorld
        goalStates: goalStates
      if transferableSupported
        self.postMessage message, serialized.transferableObjects
      else
        self.postMessage message

    catch error
      console.log 'World delivery error:', error.toString() + "\n" + error.stack or error.stackTrace
    t3 = new Date()
    console.log 'And it was so: (' + (diff / self.world.totalFrames).toFixed(3) + 'ms per frame,', self.world.totalFrames, "frames)\nSimulation   :", diff + "ms \nSerialization:", (t2 - t1) + "ms\nDelivery     :", (t3 - t2) + 'ms'
    self.cleanUp()


  self.onWorldError = onWorldError = (error) ->
    if error.isUserCodeProblem
      errorKey = error.userInfo.key
      if not errorKey or not self.postedErrors[errorKey]
        self.postMessage
          type: 'user-code-problem'
          problem: error
        self.postedErrors[errorKey] = error
    else
      console.log 'Non-UserCodeError:', error.toString() + "\n" + error.stack or error.stackTrace
      self.postMessage type: 'non-user-code-problem', problem: {message: error.toString()}
      self.cleanUp()
      return false
    return true

  self.onWorldLoadProgress = onWorldLoadProgress = (progress) ->
    #console.log 'Worker onWorldLoadProgress'
    self.postMessage
      type: 'world-load-progress-changed'
      progress: progress

  self.abort = abort = ->
    #console.log 'Abort called for worker.'
    if self.world
      #console.log 'About to abort:', self.world.name, typeof self.world.abort
      self.world.abort()
      self.world = null
    self.postMessage type: 'abort'
    self.cleanUp()

  self.reportIn = reportIn = ->
    console.log 'Reporting in.'
    self.postMessage type: 'report-in'

  self.addEventListener 'message', (event) ->
    #console.log JSON.stringify event
    self[event.data.func] event.data.args

  self.postMessage type: 'worker-initialized'

codeFileContents = []
for codeFile in [
    'lodash.js'
    'world.js'
    'aether.js'
    'app/vendor/aether-clojure.js'
    'app/vendor/aether-coffeescript.js'
    'app/vendor/aether-io.js'
    'app/vendor/aether-javascript.js'
    'app/vendor/aether-lua.js'
    'app/vendor/aether-python.js'
    'app/vendor/aether-java.js'
  ]
  codeFileContents.push fs.readFileSync(__dirname + "/../public/javascripts/#{codeFile}", 'utf8')

#window.BOX2D_ENABLED = true;

ret = """

  GLOBAL = root = window = self;
  GLOBAL.window = window;

  self.workerID = 'Worker';

  console = (#{betterConsole.toString()})();

  try {
    // the world javascript file
    #{codeFileContents.join(';\n    ')};

    // Don't let user generated code access stuff from our file system!
    self.importScripts = importScripts = null;
    self.native_fs_ = native_fs_ = null;

    // the actual function
    (#{work.toString()})();
  } catch (error) {
    self.postMessage({'type': 'console-log', args: ['An unhandled error occured: ', error.toString(), error.stack], id: -1});
  }
"""

#console = #{JASON.stringify createConsole}();
#
#  console.error = console.info = console.log;
#self.console = console;
#GLOBAL.console = console;

module.exports = new Function(ret)
