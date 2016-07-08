# Every Angel has one web worker attached to it. It will call methods inside the worker and kill it if it times out.
# God is the public API; Angels are an implementation detail. Each God can have one or more Angels.

{now} = require 'lib/world/world_utils'
World = require 'lib/world/world'
CocoClass = require 'core/CocoClass'
GoalManager = require 'lib/world/GoalManager'
{sendContactMessage} = require 'core/contact'

reportedLoadErrorAlready = false

module.exports = class Angel extends CocoClass
  @nicks: ['Archer', 'Lana', 'Cyril', 'Pam', 'Cheryl', 'Woodhouse', 'Ray', 'Krieger']

  infiniteLoopIntervalDuration: 10000  # check this often; must be longer than other two combined
  infiniteLoopTimeoutDuration: 7500  # wait this long for a response when checking
  abortTimeoutDuration: 500  # give in-process or dying workers this long to give up

  subscriptions:
    'level:flag-updated': 'onFlagEvent'
    'playback:stop-real-time-playback': 'onStopRealTimePlayback'
    'level:escape-pressed': 'onEscapePressed'

  constructor: (@shared) ->
    super()
    @say 'Got my wings.'
    isIE = window.navigator and (window.navigator.userAgent.search('MSIE') isnt -1 or window.navigator.appName is 'Microsoft Internet Explorer')
    slowerSimulations = isIE  #or @shared.headless
    # Since IE is so slow to serialize without transferable objects, we can't trust it.
    # We also noticed the headless_client simulator needing more time. (This does both Simulators, though.) If we need to use lots of headless clients, enable this.
    if slowerSimulations
      @infiniteLoopIntervalDuration *= 10
      @infiniteLoopTimeoutDuration *= 10
      @abortTimeoutDuration *= 10
    @initialized = false
    @running = false
    @allLogs = []
    @hireWorker()
    @shared.angels.push @
    @listenTo @shared.gameUIState.get('realTimeInputEvents'), 'add', @onAddRealTimeInputEvent

  destroy: ->
    @fireWorker false
    _.remove @shared.angels, @
    super()

  workIfIdle: ->
    @doWork() unless @running

  # say: debugging stuff, usually off; log: important performance indicators, keep on
  say: (args...) -> #@log args...
  log: ->
    # console.info.apply is undefined in IE9, CoffeeScript splats invocation won't work.
    # http://stackoverflow.com/questions/5472938/does-ie9-support-console-log-and-is-it-a-real-function
    message = "|#{@shared.godNick}'s #{@nick}|"
    message += " #{arg}" for arg in arguments
    console.info message
    @allLogs.push message

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
        @beholdGoalStates {goalStates: event.data.goalStates, overallStatus: event.data.overallStatus, preload: false, totalFrames: event.data.totalFrames, lastFrameHash: event.data.lastFrameHash, simulationFrameRate: event.data.simulationFrameRate}  # Work ends here if we're headless.
      when 'end-preload-frames'
        clearTimeout @condemnTimeout
        @beholdGoalStates {goalStates: event.data.goalStates, overallStatus: event.data.overallStatus, preload: true, simulationFrameRate: event.data.simulationFrameRate}

      # We have to abort like an infinite loop if we see one of these; they're not really recoverable
      when 'non-user-code-problem'
        @publishGodEvent 'non-user-code-problem', problem: event.data.problem
        if @shared.firstWorld
          @infinitelyLooped(false, true)  # For now, this should do roughly the right thing if it happens during load.
        else
          @fireWorker()

      # If it didn't finish simulating successfully, or we abort the worker.
      when 'abort'
        @say 'Aborted.', event.data
        clearTimeout @abortTimeout
        @aborting = false
        @running = false
        _.remove @shared.busyAngels, @
        @doWork()

      # We pay attention to certain progress indicators as the world loads.
      when 'console-log'
        @log event.data.args...
      when 'user-code-problem'
        @publishGodEvent 'user-code-problem', problem: event.data.problem
      when 'world-load-progress-changed'
        @publishGodEvent 'world-load-progress-changed', progress: event.data.progress
        unless event.data.progress is 1 or @work.preload or @work.headless or @work.synchronous or @deserializationQueue.length or (@shared.firstWorld and not @shared.spectate)
          @worker.postMessage func: 'serializeFramesSoFar'  # Stream it!

      # We have some or all of the frames serialized, so let's send the (partially?) simulated world to the Surface.
      when 'some-frames-serialized', 'new-world'
        deserializationArgs = [event.data.serialized, event.data.goalStates, event.data.startFrame, event.data.endFrame, @streamingWorld]
        @deserializationQueue.push deserializationArgs
        if @deserializationQueue.length is 1
          @beholdWorld deserializationArgs...

      else
        @log 'Received unsupported message:', event.data

  beholdGoalStates: ({goalStates, overallStatus, preload, totalFrames, lastFrameHash, simulationFrameRate}) ->
    return if @aborting
    event = goalStates: goalStates, preload: preload ? false, overallStatus: overallStatus
    event.totalFrames = totalFrames if totalFrames?
    event.lastFrameHash = lastFrameHash if lastFrameHash?
    event.simulationFrameRate = simulationFrameRate if simulationFrameRate?
    @publishGodEvent 'goals-calculated', event
    @finishWork() if @shared.headless

  beholdWorld: (serialized, goalStates, startFrame, endFrame, streamingWorld) ->
    return if @aborting
    # Toggle BOX2D_ENABLED during deserialization so that if we have box2d in the namespace, the Collides Components still don't try to create bodies for deserialized Thangs upon attachment.
    window.BOX2D_ENABLED = false
    @streamingWorld = World.deserialize serialized, @shared.worldClassMap, @shared.lastSerializedWorldFrames, @finishBeholdingWorld(goalStates), startFrame, endFrame, @work.level, streamingWorld
    window.BOX2D_ENABLED = true
    @shared.lastSerializedWorldFrames = serialized.frames

  finishBeholdingWorld: (goalStates) -> (world) =>
    return if @aborting or @destroyed
    finished = world.frames.length is world.totalFrames
    firstChangedFrame = world.findFirstChangedFrame @shared.world
    eventType = if finished then 'new-world-created' else 'streaming-world-updated'
    if finished
      @shared.world = world
    @publishGodEvent eventType, world: world, firstWorld: @shared.firstWorld, goalStates: goalStates, team: me.team, firstChangedFrame: firstChangedFrame, finished: finished
    if finished
      for scriptNote in @shared.world.scriptNotes
        Backbone.Mediator.publish scriptNote.channel, scriptNote.event
      @shared.goalManager?.world = world
      @finishWork()
    else
      @deserializationQueue.shift()  # Finished with this deserialization.
      if deserializationArgs = @deserializationQueue[0]  # Start another?
        @beholdWorld deserializationArgs...

  finishWork: ->
    @streamingWorld = null
    @shared.firstWorld = false
    @deserializationQueue = []
    @running = false
    _.remove @shared.busyAngels, @
    clearTimeout @condemnTimeout
    clearInterval @purgatoryTimer
    @condemnTimeout = @purgatoryTimer = null
    @doWork()

  finalizePreload: ->
    @say 'Finalize preload.'
    @worker.postMessage func: 'finalizePreload'
    @work.preload = false

  infinitelyLooped: (escaped=false, nonUserCodeProblem=false) =>
    @say 'On infinitely looped! Aborting?', @aborting
    return if @aborting
    problem = type: 'runtime', level: 'error', id: 'runtime_InfiniteLoop', message: 'Code never finished. It\'s either really slow or has an infinite loop.'
    problem.message = 'Escape pressed; code aborted.' if escaped
    @publishGodEvent 'user-code-problem', problem: problem
    @publishGodEvent 'infinite-loop', firstWorld: @shared.firstWorld, nonUserCodeProblem: nonUserCodeProblem
    @reportLoadError() if nonUserCodeProblem
    @fireWorker()

  publishGodEvent: (channel, e) ->
    # For Simulator. TODO: refactor all the god:* Mediator events to be local events.
    @shared.god.trigger channel, e
    e.god = @shared.god
    Backbone.Mediator.publish 'god:' + channel, e

  reportLoadError: ->
    return if me.isAdmin() or /dev=true/.test(window.location?.href ? '') or reportedLoadErrorAlready
    reportedLoadErrorAlready = true
    context = email: me.get('email')
    context.message = "Automatic Report - Unable to Load Level\nLogs:\n" + @allLogs.join('\n')
    if $.browser
      context.browser = "#{$.browser.platform} #{$.browser.name} #{$.browser.versionNumber}"
    context.screenSize = "#{screen?.width ? $(window).width()} x #{screen?.height ? $(window).height()}"
    context.subject = "Level Load Error: #{@work?.level?.name or 'Unknown Level'}"
    context.levelSlug = @work?.level?.slug
    sendContactMessage context

  doWork: ->
    return if @aborting
    return @say 'Not initialized for work yet.' unless @initialized
    if @shared.workQueue.length
      @work = @shared.workQueue.shift()
      return _.defer @simulateSync, @work if @work.synchronous
      @say 'Running world...'
      @running = true
      @shared.busyAngels.push @
      @deserializationQueue = []
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
    @streamingWorld = null
    @deserializationQueue = null
    _.remove @shared.busyAngels, @
    @abortTimeout = _.delay @fireWorker, @abortTimeoutDuration
    @aborting = true
    @worker.postMessage func: 'abort'

  fireWorker: (rehire=true) =>
    return if @destroyed
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
    @streamingWorld = null
    @deserializationQueue = null
    @hireWorker() if rehire

  hireWorker: ->
    unless Worker?
      unless @initialized
        @initialized = true
        @doWork()
      return null
    return if @worker
    @say 'Hiring worker.'
    @worker = new Worker @shared.workerCode
    @worker.addEventListener 'message', @onWorkerMessage
    @worker.creationTime = new Date()

  onFlagEvent: (e) ->
    return unless @running and @work.realTime
    @worker.postMessage func: 'addFlagEvent', args: e

  onAddRealTimeInputEvent: (realTimeInputEvent) ->
    return unless @running and @work.realTime
    @worker.postMessage func: 'addRealTimeInputEvent', args: realTimeInputEvent.toJSON()

  onStopRealTimePlayback: (e) ->
    return unless @running and @work.realTime
    @work.realTime = false
    @lastRealTimeWork = new Date()
    @worker.postMessage func: 'stopRealTimePlayback'

  onEscapePressed: (e) ->
    return unless @running and not @work.realTime
    return if (new Date() - @lastRealTimeWork) < 1000  # Fires right after onStopRealTimePlayback
    @infinitelyLooped true

  #### Synchronous code for running worlds on main thread (profiling / IE9) ####
  simulateSync: (work) =>
    console?.profile? "World Generation #{(Math.random() * 1000).toFixed(0)}" if imitateIE9?
    work.t0 = now()
    work.world = testWorld = new World work.userCodeMap
    work.world.levelSessionIDs = work.levelSessionIDs
    work.world.submissionCount = work.submissionCount
    work.world.fixedSeed = work.fixedSeed
    work.world.flagHistory = work.flagHistory ? []
    work.world.difficulty = work.difficulty
    work.world.loadFromLevel work.level
    work.world.preloading = work.preload
    work.world.headless = work.headless
    work.world.realTime = work.realTime
    if @shared.goalManager
      testGM = new GoalManager(testWorld)
      testGM.setGoals work.goals
      testGM.setCode work.userCodeMap
      testGM.worldGenerationWillBegin()
      testWorld.setGoalManager testGM
    @doSimulateWorld work
    console?.profileEnd?() if imitateIE9?
    console.log 'Construction:', (work.t1 - work.t0).toFixed(0), 'ms. Simulation:', (work.t2 - work.t1).toFixed(0), 'ms --', ((work.t2 - work.t1) / testWorld.frames.length).toFixed(3), 'ms per frame, profiled.'

    # If performance was really a priority in IE9, we would rework things to be able to skip this step.
    goalStates = testGM?.getGoalStates()
    work.world.goalManager.worldGenerationEnded() if work.world.ended

    if work.headless
      simulationFrameRate = work.world.frames.length / (work.t2 - work.t1) * 1000 * 30 / work.world.frameRate
      @beholdGoalStates {goalStates, overallStatus: testGM.checkOverallStatus(), preload: false, totalFrames: work.world.totalFrames, lastFrameHash: work.world.frames[work.world.totalFrames - 2]?.hash, simulationFrameRate: simulationFrameRate}
      return

    serialized = world.serialize()
    window.BOX2D_ENABLED = false
    World.deserialize serialized.serializedWorld, @shared.worldClassMap, @shared.lastSerializedWorldFrames, @finishBeholdingWorld(goalStates), serialized.startFrame, serialized.endFrame, work.level
    window.BOX2D_ENABLED = true
    @shared.lastSerializedWorldFrames = serialized.serializedWorld.frames

  doSimulateWorld: (work) ->
    work.t1 = now()
    Math.random = work.world.rand.randf  # so user code is predictable
    Aether.replaceBuiltin('Math', Math)
    replacedLoDash = _.runInContext(window)
    _[key] = replacedLoDash[key] for key, val of replacedLoDash
    i = 0
    while i < work.world.totalFrames
      frame = work.world.getFrame i++
    @publishGodEvent 'world-load-progress-changed', progress: 1
    work.world.ended = true
    system.finish work.world.thangs for system in work.world.systems
    work.t2 = now()
