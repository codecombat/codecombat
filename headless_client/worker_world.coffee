# function to use inside a webworker.
# This function needs to run inside an environment that has a 'self'.
# This specific worker is targeted towards the node.js headless_client environment.

JASON = require 'jason'
fs = require 'fs'

betterConsole = () ->

  self.logLimit = 200;
  self.logsLogged = 0;

  self.transferableSupported = () -> true

  self.console = log: ->
    if self.logsLogged++ is self.logLimit
      self.postMessage
        type: "console-log"
        args: ["Log limit " + self.logLimit + " reached; shutting up."]
        id: self.workerID

    else if self.logsLogged < self.logLimit
      args = [].slice.call(arguments)
      i = 0

      while i < args.length
        args[i] = args[i].toString()  if args[i].constructor.className is "Thang" or args[i].isComponent  if args[i] and args[i].constructor
        ++i
      try
        self.postMessage
          type: "console-log"
          args: args
          id: self.workerID

      catch error
        self.postMessage
          type: "console-log"
          args: [
              "Could not post log: " + args
              error.toString()
              error.stack
              error.stackTrace
          ]
          id: self.workerID

  # so that we don't crash when debugging statements happen
  self.console.error = self.console.info = self.console.log
  GLOBAL.console = console = self.console
  self.console


work = () ->
  console.log "starting..."

  console.log = ->

  World = self.require('lib/world/world');
  GoalManager = self.require('lib/world/GoalManager');

  self.cleanUp = ->
    self.world = null
    self.goalManager = null
    self.postedErrors = {}
    self.t0 = null
    self.logsLogged = 0

  self.runWorld = (args) ->
    console.log "Running world inside worker."
    self.postedErrors = {}
    self.t0 = new Date()
    self.postedErrors = false
    self.logsLogged = 0

    try
      self.world = new World(args.worldName, args.userCodeMap)
      self.world.loadFromLevel args.level, true  if args.level
      self.goalManager = new GoalManager(self.world)
      self.goalManager.setGoals args.goals
      self.goalManager.setCode args.userCodeMap
      self.goalManager.worldGenerationWillBegin()
      self.world.setGoalManager self.goalManager
    catch error
      console.log "There has been an error inside the worker."
      self.onWorldError error
      return
    Math.random = self.world.rand.randf # so user code is predictable
    console.log "Loading frames."

    self.postMessage type: "start-load-frames"


    self.world.loadFrames self.onWorldLoaded, self.onWorldError, self.onWorldLoadProgress, true


  self.onWorldLoaded = onWorldLoaded = ->
    self.postMessage type: "end-load-frames"

    self.goalManager.worldGenerationEnded()
    t1 = new Date()
    diff = t1 - self.t0
    transferableSupported = self.transferableSupported()
    try
      serialized = serializedWorld: undefined # self.world.serialize()
      transferableSupported = false
    catch error
      console.log "World serialization error:", error.toString() + "\n" + error.stack or error.stackTrace
    t2 = new Date()

    # console.log("About to transfer", serialized.serializedWorld.trackedPropertiesPerThangValues, serialized.transferableObjects);
    try
      if transferableSupported
        self.postMessage
          type: "new-world"
          serialized: serialized.serializedWorld
          goalStates: self.goalManager.getGoalStates()
        , serialized.transferableObjects
      else
        self.postMessage
          type: "new-world"
          serialized: serialized.serializedWorld
          goalStates: self.goalManager.getGoalStates()

    catch error
      console.log "World delivery error:", error.toString() + "\n" + error.stack or error.stackTrace
    t3 = new Date()
    console.log "And it was so: (" + (diff / self.world.totalFrames).toFixed(3) + "ms per frame,", self.world.totalFrames, "frames)\nSimulation   :", diff + "ms \nSerialization:", (t2 - t1) + "ms\nDelivery     :", (t3 - t2) + "ms"
    self.cleanUp()


  self.onWorldError = onWorldError = (error) ->
    self.postMessage type: "end-load-frames"
    if error instanceof Aether.problems.UserCodeProblem
      #console.log "Aether userCodeProblem occured."
      unless self.postedErrors[error.key]
        problem = error.serialize()
        self.postMessage
          type: "user-code-problem"
          problem: problem

        self.postedErrors[error.key] = problem
    else
      console.log "Non-UserCodeError:", error.toString() + "\n" + error.stack or error.stackTrace
    self.cleanUp()

  self.onWorldLoadProgress = onWorldLoadProgress = (progress) ->
    #console.log "Worker onWorldLoadProgress"
    self.postMessage
      type: "world-load-progress-changed"
      progress: progress

  self.abort = abort = ->
    #console.log "Abort called for worker."
    if self.world and self.world.name
      #console.log "About to abort:", self.world.name, typeof self.world.abort
      self.world.abort()  if typeof self.world isnt "undefined"
      self.world = null
    self.postMessage type: "abort"
    self.cleanUp()

  self.reportIn = reportIn = ->
    console.log "Reporting in."
    self.postMessage type: "reportIn"

  self.addEventListener "message", (event) ->
    #console.log JSON.stringify event
    self[event.data.func] event.data.args

  self.postMessage type: "worker-initialized"

world = fs.readFileSync "./public/javascripts/world.js", 'utf8'


#window.BOX2D_ENABLED = true;

newConsole = "newConsole = #{}JASON.stringify newConsole}()";

ret = """

  GLOBAL = root = window = self;
  GLOBAL.window = window;

  self.workerID = "Worker";

  console = #{JASON.stringify betterConsole}();

  try {
    // the world javascript file
    #{world};

    // Don't let user generated code access stuff from our file system!
    self.importScripts = importScripts = null;
    self.native_fs_ = native_fs_ = null;

    // the actual function
    #{JASON.stringify work}();
  }catch (error) {
    self.postMessage({"type": "console-log", args: ["An unhandled error occured: ", error.toString(), error.stack], id: -1});
  }
"""


#console = #{JASON.stringify createConsole}();
#
#  console.error = console.info = console.log;
#self.console = console;
#GLOBAL.console = console;


module.exports = new Function(ret)
