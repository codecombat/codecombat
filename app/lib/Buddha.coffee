#Sane rewrite of God (a thread pool)
{now} = require 'lib/world/world_utils'
World = require 'lib/world/world'

###
  Every Angel has exactly one WebWorker attached to it.
  It will call methods inside the webwrker and kill it if it times out.
###
class Angel
  @cyanide: 0xDEADBEEF

  infiniteLoopIntervalDuration: 7500  # check this often (must be more than the others added)
  infiniteLoopTimeoutDuration: 10000  # wait this long when we check
  abortTimeoutDuration: 500  # give in-process or dying workers this long to give up

  constructor: (@id, @shared) ->
    console.log @id + ": Creating Angel"
    if (navigator.userAgent or navigator.vendor or window.opera).search("MSIE") isnt -1
      @infiniteLoopIntervalDuration *= 20  # since it's so slow to serialize without transferable objects, we can't trust it
      @infiniteLoopTimeoutDuration *= 20
      @abortTimeoutDuration *= 10
    @initialized = false
    @running = false
    @hireWorker()
    @shared.angels.push @

  testWorker: =>
    if @initialized
      @worker.postMessage {func: 'reportIn'}
      # Are there any errors when webworker isn't loaded properly?

  onWorkerMessage: (event) =>
    #console.log JSON.stringify event
    if @aborting and not
    event.data.type is 'abort'
      console.log id + " is currently aborting old work."
      return

    switch event.data.type
      when 'start-load-frames'
        clearTimeout(@condemnTimeout)
        @condemnTimeout = _.delay @infinitelyLooped, @infiniteLoopTimeoutDuration
      when 'end-load-frames'
        console.log @id + ': No condemn this time.'
        clearTimeout(@condemnTimeout)
      when 'worker-initialized'
        unless @initialized
          console.log @id + ": Worker initialized after", ((new Date()) - @worker.creationTime), "ms"
          @initialized = true
          @doWork()
      when 'new-world'
        @beholdWorld event.data.serialized, event.data.goalStates
      when 'world-load-progress-changed'
        Backbone.Mediator.publish 'god:world-load-progress-changed', event.data
      when 'console-log'
        console.log "|" + @id + "|", event.data.args...
      when 'user-code-problem'
        Backbone.Mediator.publish 'god:user-code-problem', problem: event.data.problem
      when 'abort'
        console.log @id, "aborted."
        clearTimeout @abortTimeout
        @aborting = false
        @running = false
        @shared.busyAngels.pop @
        @doWork()
      when 'reportIn'
        clearTimeout @condemnTimeout
      else
        console.log @id + " received unsupported message:", event.data

  beholdWorld: (serialized, goalStates) ->
    return if @aborting
    unless serialized
      # We're only interested in goalStates. (Simulator)
      @latestGoalStates = goalStates;
      Backbone.Mediator.publish('god:goals-calculated', goalStates: goalStates)
      @running = false
      @shared.busyAngels.pop @

    # console.warn "Goal states: " + JSON.stringify(goalStates)

    window.BOX2D_ENABLED = false  # Flip this off so that if we have box2d in the namespace, the Collides Components still don't try to create bodies for deserialized Thangs upon attachment
    World.deserialize serialized, @shared.worldClassMap, @lastSerializedWorldFrames, @finishBeholdingWorld(goalStates)
    window.BOX2D_ENABLED = true
    @lastSerializedWorldFrames = serialized.frames

  finishBeholdingWorld: (goalStates) => (world) =>
    return if @aborting
    world.findFirstChangedFrame @shared.world
    @shared.world = world
    errorCount = (t for t in @shared.world.thangs when t.errorsOut).length
    Backbone.Mediator.publish('god:new-world-created', world: world, firstWorld: @shared.firstWorld, errorCount: errorCount, goalStates: goalStates)
    for scriptNote in @shared.world.scriptNotes
      Backbone.Mediator.publish scriptNote.channel, scriptNote.event
    @shared.goalManager?.world = world
    @running = false
    @shared.busyAngels.pop @
    @shared.firstWorld = false;
    @doWork()

  infinitelyLooped: =>
    unless @aborting
      problem = type: "runtime", level: "error", id: "runtime_InfiniteLoop", message: "Code never finished. It's either really slow or has an infinite loop."
      Backbone.Mediator.publish 'god:user-code-problem', problem: problem
      Backbone.Mediator.publish 'god:infinite-loop', firstWorld: @shared.firstWorld
      @fireWorker()

  workIfIdle: ->
    @doWork() unless @running

  doWork: =>
    #console.log "work."
    return if @aborted
    console.log @id + " ready and looking for work. WorkQueue lenght is " + @shared.workQueue.length
    if @initialized and @shared.workQueue.length
      work = @shared.workQueue.pop()
      if work is Angel.cyanide # Kill all other Angels, too
        console.log @id + ": 'work is poison'"
        @shared.workQueue.push Angel.cyanide
        @free()
      else
        console.log @id + ": Sending the worker to work."
        @running = true
        @shared.busyAngels.push @

        console.log "Running world..."
        @worker.postMessage func: 'runWorld', args: work
        console.log @id + ": Setting interval."
        clearTimeout @purgatoryTimer
        @purgatoryTimer = setInterval @testWorker, @infiniteLoopIntervalDuration
    else
      console.log "No work for " + @id
      @hireWorker()

  abort: =>
    if @worker and @running
      console.log "Aborting " + @id
      @running = false
      @shared.busyAngels.pop @
      @abortTimeout = _.delay @terminate, @fireWorker, @abortTimeoutDuration
      @worker.postMessage func: 'abort'
      @aborting = true
      @work = null

  fireWorker: (rehire=true) =>
    @aborting = false
    @running = false
    @shared.busyAngels.pop @
    @worker?.removeEventListener 'message', @onWorkerMessage
    @worker?.terminate()
    @worker = null
    clearTimeout @condemnTimeout
    clearInterval @purgatoryTimer
    console.log "Fired worker."
    @initialized = false
    @work = null
    @hireWorker() if rehire

  hireWorker: ->
    unless @worker
      console.log @id + ": Hiring worker."
      @worker = new Worker @shared.workerCode
      @worker.addEventListener 'message', @onWorkerMessage
      @worker.creationTime = new Date()
    #@worker.postMessage func: 'initialized' else

  kill: ->
    @fireWorker false
    @shared.angels.pop @
    clearTimeout @condemnTimeout
    clearTimeout @purgatoryTimer
    @purgatoryTimer = null
    @condemnTimeout = null

module.exports = class God
  ids: ['Athena', 'Baldr', 'Crom', 'Dagr', 'Eris', 'Freyja', 'Great Gish', 'Hades', 'Ishtar', 'Janus', 'Khronos', 'Loki', 'Marduk', 'Negafook', 'Odin', 'Poseidon', 'Quetzalcoatl', 'Ra', 'Shiva', 'Thor', 'Umvelinqangi', 'Týr', 'Vishnu', 'Wepwawet', 'Xipe Totec', 'Yahweh', 'Zeus', '上帝', 'Tiamat', '盘古', 'Phoebe', 'Artemis', 'Osiris', "嫦娥", 'Anhur', 'Teshub', 'Enlil', 'Perkele', 'Chaos', 'Hera', 'Iris', 'Theia', 'Uranus', 'Stribog', 'Sabazios', 'Izanagi', 'Ao', 'Tāwhirimātea', 'Tengri', 'Inmar', 'Torngarsuk', 'Centzonhuitznahua', 'Hunab Ku', 'Apollo', 'Helios', 'Thoth', 'Hyperion', 'Alectrona', 'Eos', 'Mitra', 'Saranyu', 'Freyr', 'Koyash', 'Atropos', 'Clotho', 'Lachesis', 'Tyche', 'Skuld', 'Urðr', 'Verðandi', 'Camaxtli', 'Huhetotl', 'Set', 'Anu', 'Allah', 'Anshar', 'Hermes', 'Lugh', 'Brigit', 'Manannan Mac Lir', 'Persephone', 'Mercury', 'Venus', 'Mars', 'Azrael', 'He-Man', 'Anansi', 'Issek', 'Mog', 'Kos', 'Amaterasu Omikami', 'Raijin', 'Susanowo', 'Blind Io', 'The Lady', 'Offler', 'Ptah', 'Anubis', 'Ereshkigal', 'Nergal', 'Thanatos', 'Macaria', 'Angelos', 'Erebus', 'Hecate', 'Hel', 'Orcus', 'Ishtar-Deela Nakh', 'Prometheus', 'Hephaestos', 'Sekhmet', 'Ares', 'Enyo', 'Otrera', 'Pele', 'Hadúr', 'Hachiman', 'Dayisun Tngri', 'Ullr', 'Lua', 'Minerva']
  nextID: ->
    @lastID = (if @lastID? then @lastID + 1 else Math.floor(@ids.length * Math.random())) % @ids.length
    @ids[@lastID]

  # Charlie's Angels are all given access to this.
  angelsShare: {
    workerCode: '/javascripts/workers/worker_world.js' # Either path or function
    workQueue: []
    firstWorld: true
    world: undefined
    goalManager: undefined
    worldClassMap: undefined
    angels: []
    busyAngels: [] #  Busy angels will automatically register here.
  }

  constructor: (options) ->
    options ?= {}

    @angelsShare.workerCode = options.workerCode if options.workerCode

    # ~20MB per idle worker + angel overhead - in this implementation, every Angel maps to 1 worker
    angelCount = options.maxAngels ? options.maxWorkerPoolSize ? 2  # How many concurrent Angels/web workers to use at a time

    _.delay (=>new Angel @nextID(), @angelsShare), 250 * i for i in [0...angelCount] # Don't generate all Angels at once.
    Backbone.Mediator.subscribe 'tome:cast-spells', @onTomeCast, @

  onTomeCast: (e) ->
    @createWorld e.spells

  setGoalManager: (goalManager) =>
    @angelsShare.goalManager = goalManager

  setWorldClassMap: (worldClassMap) =>
    @angelsShare.worldClassMap = worldClassMap

  getUserCodeMap: (spells) ->
    userCodeMap = {}
    for spellKey, spell of spells
      for thangID, spellThang of spell.thangs
        (userCodeMap[thangID] ?= {})[spell.name] = spellThang.aether.serialize()

    #console.log userCodeMap
    userCodeMap

  createWorld: (spells) =>
    angel.abort() for angel in @angelsShare.busyAngels # We really only ever want one world calculated per God
    #console.log "Level: " + @level
    @angelsShare.workQueue.push
      worldName: @level.name
      userCodeMap: @getUserCodeMap(spells)
      level: @level
      goals: @angelsShare.goalManager?.getGoals()
    angel.workIfIdle() for angel in @angelsShare.angels

  destroy: =>
    console.log "Destroying Buddha"
    @createWorld = -> console.log "CreateWorld already gone."
    @angelsShare.workQueue.push Angel.cyanide
    angel.kill for angel in @angelsShare.busyAngels
    Backbone.Mediator.unsubscribe('tome:cast-spells', @onTomeCast, @)
    @angelsShare.goalManager?.destroy()
    @angelsShare.goalManager = null
    @angelsShare = null

  #TODO: self.world.totalFrames??
  #TODO: Don't show arguments.
