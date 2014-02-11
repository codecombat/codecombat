{now} = require 'lib/world/world_utils'
World = require 'lib/world/world'

## Uncomment to imitate IE9 (and in world_utils.coffee)
#window.Worker = null
#window.Float32Array = null
# Also uncomment vendor_with_box2d.js in index.html if you want Collision to run and things to move.

module.exports = class God
  @ids: ['Athena', 'Baldr', 'Crom', 'Dagr', 'Eris', 'Freyja', 'Great Gish', 'Hades', 'Ishtar', 'Janus', 'Khronos', 'Loki', 'Marduk', 'Negafook', 'Odin', 'Poseidon', 'Quetzalcoatl', 'Ra', 'Shiva', 'Thor', 'Umvelinqangi', 'Týr', 'Vishnu', 'Wepwawet', 'Xipe Totec', 'Yahweh', 'Zeus', '上帝', 'Tiamat', '盘古', 'Phoebe', 'Artemis', 'Osiris', "嫦娥", 'Anhur', 'Teshub', 'Enlil', 'Perkele', 'Aether', 'Chaos', 'Hera', 'Iris', 'Theia', 'Uranus', 'Stribog', 'Sabazios', 'Izanagi', 'Ao', 'Tāwhirimātea', 'Tengri', 'Inmar', 'Torngarsuk', 'Centzonhuitznahua', 'Hunab Ku', 'Apollo', 'Helios', 'Thoth', 'Hyperion', 'Alectrona', 'Eos', 'Mitra', 'Saranyu', 'Freyr', 'Koyash', 'Atropos', 'Clotho', 'Lachesis', 'Tyche', 'Skuld', 'Urðr', 'Verðandi', 'Camaxtli', 'Huhetotl', 'Set', 'Anu', 'Allah', 'Anshar', 'Hermes', 'Lugh', 'Brigit', 'Manannan Mac Lir', 'Persephone', 'Mercury', 'Venus', 'Mars', 'Azrael', 'He-Man', 'Anansi', 'Issek', 'Mog', 'Kos', 'Amaterasu Omikami', 'Raijin', 'Susanowo', 'Blind Io', 'The Lady', 'Offler', 'Ptah', 'Anubis', 'Ereshkigal', 'Nergal', 'Thanatos', 'Macaria', 'Angelos', 'Erebus', 'Hecate', 'Hel', 'Orcus', 'Ishtar-Deela Nakh', 'Prometheus', 'Hephaestos', 'Sekhmet', 'Ares', 'Enyo', 'Otrera', 'Pele', 'Hadúr', 'Hachiman', 'Dayisun Tngri', 'Ullr', 'Lua', 'Minerva']
  @nextID: ->
    @lastID = (if @lastID? then @lastID + 1 else Math.floor(@ids.length * Math.random())) % @ids.length
    @ids[@lastID]

  maxAngels: 2  # how many concurrent web workers to use; if set past 8, make up more names
  worldWaiting: false  # whether we're waiting for a worker to free up and run the world
  constructor: ->
    @id = God.nextID()
    @angels = []
    @firstWorld = true
    Backbone.Mediator.subscribe 'tome:cast-spells', @onTomeCast, @
    @fillWorkerPool = _.throttle @fillWorkerPool, 3000, leading: false
    @fillWorkerPool()

  onTomeCast: (e) ->
    return if @dead
    @spells = e.spells
    @createWorld()

  fillWorkerPool: =>
    return unless Worker
    @workerPool ?= []
    while @workerPool.length < @maxAngels
      @workerPool.push @createWorker()

  getWorker: ->
    @fillWorkerPool()
    worker = @workerPool.shift()
    return worker if worker
    @createWorker()

  createWorker: ->
    new Worker '/javascripts/workers/worker_world.js'

  getAngel: ->
    freeAngel = null
    for angel in @angels
      if angel.busy
        angel.abort()
      else
        freeAngel ?= angel
    return freeAngel.enslave() if freeAngel
    maxedOut = @angels.length is @maxAngels
    if not maxedOut
      angel = new Angel @
      @angels.push angel
      return angel.enslave()
    null

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

  createWorld: ->
    #console.log @id + ': "Let there be light upon', @world.name + '!"'
    unless Worker?  # profiling world simulation is easier on main thread, or we are IE9
      setTimeout @simulateWorld, 1
      return

    angel = @getAngel()
    if angel
      @worldWaiting = false
    else
      @worldWaiting = true
      return
    angel.worker.postMessage {func: 'runWorld', args: {
      worldName: @level.name
      userCodeMap: @getUserCodeMap()
      level: @level
      firstWorld: @firstWorld
      goals: @goalManager?.getGoals()
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
    Backbone.Mediator.publish('god:new-world-created', world: @world, firstWorld: @firstWorld, errorCount: errorCount, goalStates: @latestGoalStates)
    for scriptNote in @world.scriptNotes
      Backbone.Mediator.publish scriptNote.channel, scriptNote.event
    @goalManager?.world = newWorld
    @firstWorld = false
    @testWorld = null
    unless _.find @angels, 'busy'
      @spells = null  # Don't hold onto old spells; memory leaks

  getUserCodeMap: ->
    console.log "userCodeMap is "
    userCodeMap = {}
    for spellKey, spell of @spells
      for thangID, spellThang of spell.thangs
        (userCodeMap[thangID] ?= {})[spell.name] = spellThang.aether.serialize()
    console.log userCodeMap
    userCodeMap

  destroy: ->
    angel.destroy() for angel in @angels
    @dead = true
    Backbone.Mediator.unsubscribe('tome:cast-spells', @onTomeCast, @)
    @goalManager = null

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
    if Worker?
      console?.profileEnd?()
    console.log "Construction:", (@t1 - @t0).toFixed(0), "ms. Simulation:", (@t2 - @t1).toFixed(0), "ms --", ((@t2 - @t1) / @testWorld.frames.length).toFixed(3), "ms per frame, profiled."

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


class Angel
  @ids: ['Archer', 'Lana', 'Cyril', 'Pam', 'Cheryl', 'Woodhouse', 'Ray', 'Krieger']
  @nextID: ->
    @lastID = (if @lastID? then @lastID + 1 else Math.floor(@ids.length * Math.random())) % @ids.length
    @ids[@lastID]

  # https://github.com/codecombat/codecombat/issues/81 -- TODO: we need to wait for worker initialization first
  infiniteLoopIntervalDuration: 1500000  # check this often (must be more than the others added)
  infiniteLoopTimeoutDuration: 1500  # wait this long when we check
  abortTimeoutDuration: 500  # give in-process or dying workers this long to give up
  constructor: (@god) ->
    @id = Angel.nextID()
    if (navigator.userAgent or navigator.vendor or window.opera).search("MSIE") isnt -1
      @infiniteLoopIntervalDuration *= 20  # since it's so slow to serialize without transferable objects, we can't trust it
      @infiniteLoopTimeoutDuration *= 20
      @abortTimeoutDuration *= 10
    @spawnWorker()

  spawnWorker: ->
    @worker = @god.getWorker()
    @listen()

  enslave: ->
    @busy = true
    @started = new Date()
    @purgatoryTimer = setInterval @testWorker, @infiniteLoopIntervalDuration
    @spawnWorker() unless @worker
    @

  free: ->
    @busy = false
    @started = null
    clearInterval @purgatoryTimer
    @purgatoryTimer = null
    if @worker
      worker = @worker
      _.defer -> worker.terminate
      @worker = null
    @

  abort: ->
    return unless @worker
    @abortTimeout = _.delay @terminate, @abortTimeoutDuration
    @worker.postMessage {func: 'abort'}

  terminate: =>
    @worker?.terminate()
    @worker = null
    return if @dead
    @free()
    @god.angelAborted @

  destroy: ->
    @dead = true
    @abort()

  testWorker: =>
    @worker.postMessage {func: 'reportIn'}
    @condemnTimeout = _.delay @condemnWorker, @infiniteLoopTimeoutDuration

  condemnWorker: =>
    @god.angelInfinitelyLooped @
    @abort()

  listen: ->
    @worker.addEventListener 'message', (event) =>
      switch event.data.type
        when 'new-world'
          @god.beholdWorld @, event.data.serialized, event.data.goalStates
        when 'world-load-progress-changed'
          Backbone.Mediator.publish 'god:world-load-progress-changed', event.data unless @dead
        when 'console-log'
          console.log "|" + @god.id + "'s " + @id + "|", event.data.args...
        when 'user-code-problem'
          @god.angelUserCodeProblem @, event.data.problem
        when 'abort'
          #console.log @id, "aborted."
          clearTimeout @abortTimeout
          @free()
          @god.angelAborted @
        when 'reportIn'
          clearTimeout @condemnTimeout
        else
          console.log "Unsupported message:", event.data
