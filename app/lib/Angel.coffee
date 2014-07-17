# Every Angel has one web worker attached to it. It will call methods inside the worker and kill it if it times out.
# God is the public API; Angels are an implementation detail. Each God can have one or more Angels.

{now} = require 'lib/world/world_utils'
World = require 'lib/world/world'
CocoClass = require 'lib/CocoClass'

module.exports = class Angel extends CocoClass
  @nicks: ['Archer', 'Lana', 'Cyril', 'Pam', 'Cheryl', 'Woodhouse', 'Ray', 'Krieger']

  infiniteLoopIntervalDuration: 10000  # check this often; must be longer than other two combined
  infiniteLoopTimeoutDuration: 7500  # wait this long for a response when checking
  abortTimeoutDuration: 500  # give in-process or dying workers this long to give up

  constructor: (@shared) ->
    super()
    @say 'Got my wings.'
    if window.navigator and (window.navigator.userAgent.search('MSIE') isnt -1 or window.navigator.appName is 'Microsoft Internet Explorer')
      @infiniteLoopIntervalDuration *= 10  # since it's so slow to serialize without transferable objects, we can't trust it
      @infiniteLoopTimeoutDuration *= 10
      @abortTimeoutDuration *= 10
    @initialized = false
    @running = false
    @hireWorker()
    @shared.angels.push @

  destroy: ->
    @fireWorker false
    _.remove @shared.angels, @
    super()

  workIfIdle: ->
    @doWork() unless @running

  # say: debugging stuff, usually off; log: important performance indicators, keep on
  say: (args...) -> #@log args...
  log: (args...) -> console.info "|#{@shared.godNick}'s #{@nick}|", args...

  testWorker: =>
    return if @destroyed
    clearTimeout @condemnTimeout
    @condemnTimeout = _.delay @infinitelyLooped, @infiniteLoopTimeoutDuration
    @say 'Let\'s give it', @infiniteLoopTimeoutDuration, 'to not loop.'
    @worker.postMessage func: 'reportIn'

  onWorkerMessage: (event) =>
    return @say 'Currently aborting old work.' if @aborting and event.data.type isnt 'abort'

    switch event.data.type
      # First step: worker has to load the scripts.
      when 'worker-initialized'
        unless @initialized
          @log "Worker initialized after #{(new Date()) - @worker.creationTime}ms"
          @initialized = true
          @doWork()

      # We watch over the worker as it loads the world frames to make sure it doesn't infinitely loop.
      when 'start-load-frames'
        clearTimeout @condemnTimeout
      when 'report-in'
        @say 'Worker reported in.'
        clearTimeout @condemnTimeout
      when 'end-load-frames'
        clearTimeout @condemnTimeout
        @beholdGoalStates event.data.goalStates  # Work ends here if we're headless.

      # We pay attention to certain progress indicators as the world loads.
      when 'world-load-progress-changed'
        Backbone.Mediator.publish 'god:world-load-progress-changed', event.data
      when 'console-log'
        @log event.data.args...
      when 'user-code-problem'
        Backbone.Mediator.publish 'god:user-code-problem', problem: event.data.problem

      # We have to abort like an infinite loop if we see one of these; they're not really recoverable
      when 'non-user-code-problem'
        Backbone.Mediator.publish 'god:non-user-code-problem', problem: event.data.problem
        if @shared.firstWorld
          @infinitelyLooped()  # For now, this should do roughly the right thing if it happens during load.
        else
          @fireWorker()

      # Either the world finished simulating successfully, or we abort the worker.
      when 'new-world'
        @beholdWorld event.data.serialized, event.data.goalStates
      when 'abort'
        @say 'Aborted.', event.data
        clearTimeout @abortTimeout
        @aborting = false
        @running = false
        _.remove @shared.busyAngels, @
        @doWork()

      else
        @log 'Received unsupported message:', event.data

  beholdGoalStates: (goalStates) ->
    return if @aborting
    Backbone.Mediator.publish 'god:goals-calculated', goalStates: goalStates
    @finishWork() if @shared.headless

  beholdWorld: (serialized, goalStates) ->
    return if @aborting
    # Toggle BOX2D_ENABLED during deserialization so that if we have box2d in the namespace, the Collides Components still don't try to create bodies for deserialized Thangs upon attachment.
    window.BOX2D_ENABLED = false
    World.deserialize serialized, @shared.worldClassMap, @shared.lastSerializedWorldFrames, @finishBeholdingWorld(goalStates)
    window.BOX2D_ENABLED = true
    @shared.lastSerializedWorldFrames = serialized.frames

  finishBeholdingWorld: (goalStates) -> (world) =>
    return if @aborting
    world.findFirstChangedFrame @shared.world
    @shared.world = world
    errorCount = (t for t in @shared.world.thangs when t.errorsOut).length
    Backbone.Mediator.publish 'god:new-world-created', world: world, firstWorld: @shared.firstWorld, errorCount: errorCount, goalStates: goalStates, team: me.team
    for scriptNote in @shared.world.scriptNotes
      Backbone.Mediator.publish scriptNote.channel, scriptNote.event
    @shared.goalManager?.world = world
    @finishWork()

  finishWork: ->
    @shared.firstWorld = false
    @running = false
    _.remove @shared.busyAngels, @
    @doWork()

  finalizePreload: ->
    @say 'Finalize preload.'
    @worker.postMessage func: 'finalizePreload'

  infinitelyLooped: =>
    @say 'On infinitely looped! Aborting?', @aborting
    return if @aborting
    problem = type: 'runtime', level: 'error', id: 'runtime_InfiniteLoop', message: 'Code never finished. It\'s either really slow or has an infinite loop.'
    Backbone.Mediator.publish 'god:user-code-problem', problem: problem
    Backbone.Mediator.publish 'god:infinite-loop', firstWorld: @shared.firstWorld
    @fireWorker()

  doWork: ->
    return if @aborting
    return @say 'Not initialized for work yet.' unless @initialized
    if @shared.workQueue.length
      @work = @shared.workQueue.shift()
      return _.defer @simulateSync, @work if @work.synchronous
      @say 'Running world...'
      @running = true
      @shared.busyAngels.push @
      @worker.postMessage func: 'runWorld', args: @work
      clearTimeout @purgatoryTimer
      @say 'Infinite loop timer started at interval of', @infiniteLoopIntervalDuration
      @purgatoryTimer = setInterval @testWorker, @infiniteLoopIntervalDuration
    else
      @say 'No work to do.'
      @hireWorker()

  abort: ->
    return unless @worker and @running
    @say 'Aborting...'
    @running = false
    @work = null
    _.remove @shared.busyAngels, @
    @abortTimeout = _.delay @fireWorker, @abortTimeoutDuration
    @aborting = true
    @worker.postMessage func: 'abort'

  fireWorker: (rehire=true) =>
    @aborting = false
    @running = false
    _.remove @shared.busyAngels, @
    @worker?.removeEventListener 'message', @onWorkerMessage
    @worker?.terminate()
    @worker = null
    clearTimeout @condemnTimeout
    clearInterval @purgatoryTimer
    @say 'Fired worker.'
    @initialized = false
    @work = null
    @hireWorker() if rehire

  hireWorker: ->
    return if @worker
    @say 'Hiring worker.'
    @worker = new Worker @shared.workerCode
    @worker.addEventListener 'message', @onWorkerMessage
    @worker.creationTime = new Date()


  #### Synchronous code for running worlds on main thread (profiling / IE9) ####
  simulateSync: (work) =>
    console?.profile? "World Generation #{(Math.random() * 1000).toFixed(0)}" if imitateIE9?
    work.t0 = now()
    work.testWorld = testWorld = new World work.userCodeMap
    testWorld.loadFromLevel work.level
    if @shared.goalManager
      testGM = new @shared.goalManager.constructor @testWorld
      testGM.setGoals work.goals
      testGM.setCode work.userCodeMap
      testGM.worldGenerationWillBegin()
      testWorld.setGoalManager testGM
    @doSimulateWorld work
    console?.profileEnd?() if imitateIE9?
    console.log 'Construction:', (work.t1 - work.t0).toFixed(0), 'ms. Simulation:', (work.t2 - work.t1).toFixed(0), 'ms --', ((work.t2 - work.t1) / testWorld.frames.length).toFixed(3), 'ms per frame, profiled.'

    # If performance was really a priority in IE9, we would rework things to be able to skip this step.
    goalStates = testGM?.getGoalStates()
    serialized = testWorld.serialize().serializedWorld
    window.BOX2D_ENABLED = false
    World.deserialize serialized, @angelsShare.worldClassMap, @shared.lastSerializedWorldFrames, @finishBeholdingWorld(goalStates)
    window.BOX2D_ENABLED = true
    @shared.lastSerializedWorldFrames = serialized.frames

  doSimulateWorld: (work) ->
    work.t1 = now()
    Math.random = work.testWorld.rand.randf  # so user code is predictable
    Aether.replaceBuiltin('Math', Math)
    i = 0
    while i < work.testWorld.totalFrames
      frame = work.testWorld.getFrame i++
    work.testWorld.ended = true
    system.finish work.testWorld.thangs for system in work.testWorld.systems
    work.t2 = now()
