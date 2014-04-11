# As the server does not really need more than one background thread, this is a one-thread godess.
{now} = require 'lib/world/world_utils'
World = require 'lib/world/world'
Threads = require 'webworker-threads'
GoalManager = require 'lib/world/GoalManager'
JASON = require 'jason' # JASONs can contain executable code. Don't use this module to send stuff around.

module.exports = class God
  constructor: (options) ->
    @thread = Threads.create()

    t.eval("JASON= "+ JASON.stringify(JASON));

    thread.eval(world =
      worldName: @level.name
      userCodeMap: @getUserCodeMap()
      level: @level
      firstWorld: @firstWorld
      goals: @goalManager?.getGoals()
    )


  angelInfinitelyLooped: (angel) ->
    return if @dead
    problem = type: "runtime", level: "error", id: "runtime_InfiniteLoop", message: "Code never finished. It's either really slow or has an infinite loop."
    Backbone.Mediator.publish 'god:user-code-problem', problem: problem
    Backbone.Mediator.publish 'god:infinite-loop', firstWorld: @firstWorld

  angelAborted: (angel) ->
    return unless @worldWaiting and not @dead
    @createWorld()

  angelUserCodeProblem: (angel, problem) ->
    return if @dead
    #console.log "UserCodeProblem:", '"' + problem.message + '"', "for", problem.userInfo.thangID, "-", problem.userInfo.methodName, 'at line', problem.ranges?[0][0][0], 'column', problem.ranges?[0][0][1]
    Backbone.Mediator.publish 'god:user-code-problem', problem: problem

    angel.worker.postMessage {func: 'runWorld', args: {

    }}

  beholdWorld: (angel, serialized, goalStates) ->
    worldCreation = angel.started
    angel.free()
    return if @latestWorldCreation? and worldCreation < @latestWorldCreation
    @latestWorldCreation = worldCreation
    @latestGoalStates = goalStates
    window.BOX2D_ENABLED = false  # Flip this off so that if we have box2d in the namespace, the Collides Components still don't try to create bodies for deserialized Thangs upon attachment
    World.deserialize serialized, @worldClassMap, @lastSerializedWorldFrames, worldCreation, @finishBeholdingWorld
    window.BOX2D_ENABLED = true
    @lastSerializedWorldFrames = serialized.frames

  finishBeholdingWorld: (newWorld) =>
    newWorld.findFirstChangedFrame @world
    @world = newWorld
    errorCount = (t for t in @world.thangs when t.errorsOut).length
    Backbone.Mediator.publish('god:new-world-created', world: @world, firstWorld: @firstWorld, errorCount: errorCount, goalStates: @latestGoalStates, team: me.team)
    for scriptNote in @world.scriptNotes
      Backbone.Mediator.publish scriptNote.channel, scriptNote.event
    @goalManager?.world = newWorld
    @firstWorld = false
    @testWorld = null
    unless _.find @angels, 'busy'
      @spells = null  # Don't hold onto old spells; memory leaks

  getUserCodeMap: ->
    userCodeMap = {}
    for spellKey, spell of @spells
      for thangID, spellThang of spell.thangs
        (userCodeMap[thangID] ?= {})[spell.name] = spellThang.aether.serialize()
    userCodeMap

  destroy: ->
    worker.removeEventListener 'message', @onWorkerMessage for worker in @workerPool ? []
    angel.destroy() for angel in @angels
    @dead = true
    Backbone.Mediator.unsubscribe('tome:cast-spells', @onTomeCast, @)
    @goalManager?.destroy()
    @goalManager = null
    @fillWorkerPool = null
    @simulateWorld = null
    @onWorkerMessage = null

  #### Bad code for running worlds on main thread (profiling / IE9) ####
  simulateWorld: =>
    if Worker?
      console?.profile? "World Generation #{(Math.random() * 1000).toFixed(0)}"
    @t0 = now()
    @testWorld = new @world.constructor @world.name, @getUserCodeMap()
    @testWorld.loadFromLevel @level
    if @goalManager
      @testGM = new @goalManager.constructor @testWorld
      @testGM.setGoals @goalManager.getGoals()
      @testGM.setCode @getUserCodeMap()
      @testGM.worldGenerationWillBegin()
      @testWorld.setGoalManager @testGM
    @doSimulateWorld()

    # If performance was really a priority in IE9, we would rework things to be able to skip this step.
    @latestGoalStates = @testGM?.getGoalStates()
    serialized = @testWorld.serialize().serializedWorld
    window.BOX2D_ENABLED = false
    World.deserialize serialized, @worldClassMap, @lastSerializedWorldFrames, @t0, @finishBeholdingWorld
    window.BOX2D_ENABLED = true
    @lastSerializedWorldFrames = serialized.frames

  doSimulateWorld: ->
    @t1 = now()
    Math.random = @testWorld.rand.randf  # so user code is predictable
    i = 0
    while i < @testWorld.totalFrames
      frame = @testWorld.getFrame i++
    @testWorld.ended = true
    system.finish @testWorld.thangs for system in @testWorld.systems
    @t2 = now()
#### End bad testing code ####

