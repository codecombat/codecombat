# function to use inside a webworker.
# This function needs to run inside an environment that has a 'self'.

JASON = require 'jason'
World = require 'lib/world/world'
GoalManager = require 'lib/world/GoalManager'

work = (self, World, GoalManager) ->
  require = null

  # Don't allow the thread to read files or eval stuff.
  native_fs_ = null
  self.eval = null
  # These are not needed for the currently used webworker library, but you never know...
  require = GLOBAL = global = window = null

  self.workerID = "Worker";

  self.logLimit = 200;
  self.logsLogged = 0;

  self.transferableSupported = () -> true

  console = log: ->
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
  console.error = console.info = console.log
  self.console = console


  self.runWorld = (args) ->
    console.log "Running world inside worker."
    self.postedErrors = {}
    self.t0 = new Date()
    self.firstWorld = args.firstWorld
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
      console.log "There has been an error inside thew worker... "
      self.onWorldError error
      return
    Math.random = self.world.rand.randf # so user code is predictable
    console.log "Loading frames."
    self.world.loadFrames self.onWorldLoaded, self.onWorldError, self.onWorldLoadProgress


  self.onWorldLoaded = onWorldLoaded = ->
    console.log "Worker.onWorldLoaded."
    self.goalManager.worldGenerationEnded()
    t1 = new Date()
    diff = t1 - self.t0
    transferableSupported = self.transferableSupported()
    try
      serialized = self.world.serialize()
    catch error
      console.log "World serialization error:", error.toString() + "\n" + error.stack or error.stackTrace
    t2 = new Date()

    console.log("About to transfer", serialized.serializedWorld.trackedPropertiesPerThangValues, serialized.transferableObjects);
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
    self.world = null

  self.onWorldError = onWorldError = (error) ->
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
    return

  self.reportIn = reportIn = ->
    console.log "reportIn"
    self.postMessage type: "reportIn"
    return

  self.addEventListener "message", (event) ->
    console.log JSON.stringify event

    self[event.data.func] event.data.args
    return

  self.postMessage type: "worker-initialized"


ret = """
  try {
    self.eval(JASON=#{JASON.stringify JASON});
    var World =JASON.parse(#{ JASON.stringify World});
    var GoalManager = JASON.parse(#{ JASON.stringify GoalManager});
    var work = JASON.parse(#{JASON.stringify work});
    work(self, World, GoalManager);
  }catch (error) {
    self.postMessage({"type": "console-log", args: ["An unhandled error occured: ", error.toString()], id: -1});
  }
"""

module.exports = new Function(ret)
