# Each LevelView or Simulator has a God which listens for spells cast and summons new Angels on the main thread to
# oversee simulation of the World on worker threads. The Gods and Angels even have names. It's kind of fun.
# (More fun than ThreadPool and WorkerAgentManager and such.)

{now} = require 'lib/world/world_utils'
World = require 'lib/world/world'
CocoClass = require 'lib/CocoClass'
Angel = require 'lib/Angel'

module.exports = class God extends CocoClass
  @nicks: ['Athena', 'Baldr', 'Crom', 'Dagr', 'Eris', 'Freyja', 'Great Gish', 'Hades', 'Ishtar', 'Janus', 'Khronos', 'Loki', 'Marduk', 'Negafook', 'Odin', 'Poseidon', 'Quetzalcoatl', 'Ra', 'Shiva', 'Thor', 'Umvelinqangi', 'Týr', 'Vishnu', 'Wepwawet', 'Xipe Totec', 'Yahweh', 'Zeus', '上帝', 'Tiamat', '盘古', 'Phoebe', 'Artemis', 'Osiris', '嫦娥', 'Anhur', 'Teshub', 'Enlil', 'Perkele', 'Chaos', 'Hera', 'Iris', 'Theia', 'Uranus', 'Stribog', 'Sabazios', 'Izanagi', 'Ao', 'Tāwhirimātea', 'Tengri', 'Inmar', 'Torngarsuk', 'Centzonhuitznahua', 'Hunab Ku', 'Apollo', 'Helios', 'Thoth', 'Hyperion', 'Alectrona', 'Eos', 'Mitra', 'Saranyu', 'Freyr', 'Koyash', 'Atropos', 'Clotho', 'Lachesis', 'Tyche', 'Skuld', 'Urðr', 'Verðandi', 'Camaxtli', 'Huhetotl', 'Set', 'Anu', 'Allah', 'Anshar', 'Hermes', 'Lugh', 'Brigit', 'Manannan Mac Lir', 'Persephone', 'Mercury', 'Venus', 'Mars', 'Azrael', 'He-Man', 'Anansi', 'Issek', 'Mog', 'Kos', 'Amaterasu Omikami', 'Raijin', 'Susanowo', 'Blind Io', 'The Lady', 'Offler', 'Ptah', 'Anubis', 'Ereshkigal', 'Nergal', 'Thanatos', 'Macaria', 'Angelos', 'Erebus', 'Hecate', 'Hel', 'Orcus', 'Ishtar-Deela Nakh', 'Prometheus', 'Hephaestos', 'Sekhmet', 'Ares', 'Enyo', 'Otrera', 'Pele', 'Hadúr', 'Hachiman', 'Dayisun Tngri', 'Ullr', 'Lua', 'Minerva']

  subscriptions:
    'tome:cast-spells': 'onTomeCast'
    'tome:spell-debug-value-request': 'retrieveValueFromFrame'
    'god:new-world-created': 'onNewWorldCreated'

  constructor: (options) ->
    options ?= {}
    @retrieveValueFromFrame = _.throttle @retrieveValueFromFrame, 1000
    super()

    # Angels are all given access to this.
    @angelsShare =
      workerCode: options.workerCode or '/javascripts/workers/worker_world.js'  # Either path or function
      headless: options.headless  # Whether to just simulate the goals, or to deserialize all simulation results
      godNick: @nick
      workQueue: []
      firstWorld: true
      world: undefined
      goalManager: undefined
      worldClassMap: undefined
      angels: []
      busyAngels: []  # Busy angels will automatically register here.

    # ~20MB per idle worker + angel overhead - every Angel maps to 1 worker
    angelCount = options.maxAngels ? 2  # How many concurrent Angels/web workers to use at a time
    # Don't generate all Angels at once.
    _.delay (=> new Angel @angelsShare unless @destroyed), 250 * i for i in [0 ... angelCount]

  destroy: ->
    angel.destroy() for angel in @angelsShare.angels.slice()
    @angelsShare.goalManager?.destroy()
    @debugWorker?.terminate()
    @debugWorker?.removeEventListener 'message', @onDebugWorkerMessage
    super()

  setLevel: (@level) ->
  setLevelSessionIDs: (@levelSessionIDs) ->
  setGoalManager: (goalManager) ->
    @angelsShare.goalManager?.destroy() unless @angelsShare.goalManager is goalManager
    @angelsShare.goalManager = goalManager
  setWorldClassMap: (worldClassMap) -> @angelsShare.worldClassMap = worldClassMap

  onTomeCast: (e) ->
    @createWorld e.spells, e.preload

  createWorld: (spells, preload=false) ->
    console.log "#{@nick}: Let there be light upon #{@level.name}! (preload: #{preload})"
    userCodeMap = @getUserCodeMap spells

    # We only want one world being simulated, so we abort other angels, unless we had one preloading this very code.
    hadPreloader = false
    for angel in @angelsShare.busyAngels
      isPreloading = angel.running and angel.work.preload and _.isEqual angel.work.userCodeMap, userCodeMap, (a, b) ->
        return a.raw is b.raw if a?.raw? and b?.raw?
        undefined  # Let default equality test suffice.
      if not hadPreloader and isPreloading
        angel.finalizePreload()
        hadPreloader = true
      else if preload and angel.running and not angel.work.preload
        # It's still running for real, so let's not preload.
        return
      else
        angel.abort()
    return if hadPreloader

    @angelsShare.workQueue = []
    @angelsShare.workQueue.push
      userCodeMap: userCodeMap
      level: @level
      levelSessionIDs: @levelSessionIDs
      goals: @angelsShare.goalManager?.getGoals()
      headless: @angelsShare.headless
      preload: preload
      synchronous: not Worker?  # Profiling world simulation is easier on main thread, or we are IE9.
    angel.workIfIdle() for angel in @angelsShare.angels

  getUserCodeMap: (spells) ->
    userCodeMap = {}
    for spellKey, spell of spells
      for thangID, spellThang of spell.thangs
        (userCodeMap[thangID] ?= {})[spell.name] = spellThang.aether.serialize()
    userCodeMap


  #### New stuff related to debugging ####
  retrieveValueFromFrame: (args) =>
    return if @destroyed
    return unless args.thangID and args.spellID and args.variableChain
    return console.error 'Tried to retrieve debug value with no currentUserCodeMap' unless @currentUserCodeMap
    @debugWorker ?= @createDebugWorker()
    args.frame ?= @angelsShare.world.age / @angelsShare.world.dt
    @debugWorker.postMessage
      func: 'retrieveValueFromFrame'
      args:
        userCodeMap: @currentUserCodeMap
        level: @level
        levelSessionIDs: @levelSessionIDs
        goals: @goalManager?.getGoals()
        frame: args.frame
        currentThangID: args.thangID
        currentSpellID: args.spellID
        variableChain: args.variableChain

  createDebugWorker: ->
    worker = new Worker '/javascripts/workers/worker_world.js'
    worker.addEventListener 'message', @onDebugWorkerMessage
    worker

  onDebugWorkerMessage: (event) =>
    switch event.data.type
      when 'console-log'
        console.log "|#{@nick}'s debugger|", event.data.args...
      when 'debug-value-return'
        Backbone.Mediator.publish 'god:debug-value-return', event.data.serialized
      when 'debug-world-load-progress-changed'
        Backbone.Mediator.publish 'god:debug-world-load-progress-changed', event.data

  onNewWorldCreated: (e) ->
    @currentUserCodeMap = @filterUserCodeMapWhenFromWorld e.world.userCodeMap

  filterUserCodeMapWhenFromWorld: (worldUserCodeMap) ->
    newUserCodeMap = {}
    for thangName, thang of worldUserCodeMap
      newUserCodeMap[thangName] = {}
      for spellName, aether of thang
        shallowFilteredObject = _.pick aether, ['raw', 'pure', 'originalOptions']
        newUserCodeMap[thangName][spellName] = _.cloneDeep shallowFilteredObject
        newUserCodeMap[thangName][spellName] = _.defaults newUserCodeMap[thangName][spellName],
          flow: {}
          metrics: {}
          problems:
            errors: []
            infos: []
            warnings: []
          style: {}
    newUserCodeMap


imitateIE9 = false  # (and in world_utils.coffee)
if imitateIE9
  window.Worker = null
  window.Float32Array = null
  # Also uncomment vendor_with_box2d.js in index.html if you want Collision to run and Thangs to move.
