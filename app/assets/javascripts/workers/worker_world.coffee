
throw "Attempt to load worker_world into main window instead of web worker." if not self.importScripts or not window?

self.window = self
self.workerID = "Worker"

self.logLimit = 200
self.logsLogged = 0
console =
  log: ->
    self.logsLogged += 1
    if self.logsLogged is self.logLimit
      self.postMessage
        type: 'console-log'
        args: ["Log limit " + self.logLimit + " reached; shutting up."]
        id: self.workerID
    else if self.logsLogged < self.logLimit
      args = [].slice.call arguments
      for arg in args
        if arg and arg.constructor and (arg.constructor.className is "Thang" or arg.isComponent)
          arg = arg.toString()

      try
        self.postMessage
          type: 'console-log'
          args: args
          id: self.workerID

      catch error
        self.postMessage
          type: 'console-log'
          args: ["Could not post log: " + args, error.toString(), error.stack, error.stackTrace]
          id: self.workerID


console.error = console.info = console.log
self.console = console

importScripts '/javascripts/world.js'


self.transferableSupported = transferableSupported = ->
  try
    ab = new ArrayBuffer 1
    worker.postMessage ab, [ab]
    return ab.byteLength is 0
  catch error
    return false
  return false


  World = self.require 'lib/world/world'
  GoalManager = self.require 'lib/world/GoalManager'

  self.runWorld = runWorld = (args) ->
    self.postedErrors = {}
    self.t0 = new Date()
    self.firstWorld = args.firstWorld
    self.postedErrors = false
    self.logsLogged = 0

    try
      self.world = new World args.worldName, args.userCodeMap
      if args.level
        self.world.loadFromLevel args.level, true
      self.goalManager = new GoalManager self.world
      self.goalManager.setGoals args.goals
      self.goalManager.setCode args.userCodeMap
      self.goalManager.worldGenerationWillBegin()
      self.world.setGoalManager self.goalManager
    catch error
      self.onWorldError error
      return
    Math.random = self.world.rand.randf
    self.world.loadFrames self.onWorldLoaded, self.onWorldError, self.onWorldLoadProgress

self.onWorldLoaded = onWorldLoaded = () ->
  self.goalManager.worldGenerationEnded()
  t1 = new Date()
  diff = t1 - self.t0
  transferableSupported = self.transferableSupported()
  try
    serialized = self.world.serialize()
  catch error
    console.log "World serialization error:", error.toString() + "\n" + error.stack or error.stackTrace


  t2 = new Date()

  try
    if transferableSupported
      self.postMessage(
        type: 'new-world'
        serialized: serialized.serializedWorld
        goalStates: self.goalManager.getGoalStates()
      , serialized.transferableObjects)
    else
      self.postMessage
        type: 'new-world'
        serialized: serialized.serializedWorld
        goalStates: self.goalManager.getGoalStates()
  catch error
    console.log "World delivery error:", error.toString + "\n" + error.stack or error.stackTrace
  t3 = new Date()
  console.log "And it was so: (" + (diff / self.world.totalFrames).toFixed(3) + "ms per frame,", self.world.totalFrames, "frames)\nSimulation :"
  self.world = null

self.onWorldError = onWorldError = (error) ->
  if error instanceof Aether.problems.UserCodeProblem
    unless self.postedErrors[error.key]
      problem = error.serialize()
      self.postMessage
        type: 'user-code-problem'
        problem: problem
      self.postedErrors[error.key] = problem

  else
    console.log "Non-UserCodeError:", error.toString() + "\n" + error.stack or error.stackTrace
  return true

self.onWorldLoadProgress = onWorldLoadProgress = (progress) ->
  self.postMessage
    type: 'world-load-progress-changed'
    progress: progress

self.abort = abort = ->
  if self.world and self.world.name
    console.log "About to abort:", self.world.name, typeof self.world.abort
    self.world?.abort()
    self.world = null

  self.postMessage
    type: 'abort'

self.reportIn = reportIn = ->
  self.postMessage
    type: 'reportIn'

self.addEventListener 'message', (event) ->
  self[event.data.func](event.data.args)
