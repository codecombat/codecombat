Vector = require './vector'
Rectangle = require './rectangle'
WorldFrame = require './world_frame'
Thang = require './thang'
ThangState = require './thang_state'
Rand = require './rand'
WorldScriptNote = require './world_script_note'
{now, consolidateThangs, typedArraySupport} = require './world_utils'
Component = require 'lib/world/component'
System = require 'lib/world/system'
PROGRESS_UPDATE_INTERVAL = 200
DESERIALIZATION_INTERVAL = 20

module.exports = class World
  @className: "World"
  age: 0
  ended: false
  preloading: false  # Whether we are just preloading a world in case we soon cast it
  debugging: false  # Whether we are just rerunning to debug a world we've already cast
  headless: false  # Whether we are just simulating for goal states instead of all serialized results
  apiProperties: ['age', 'dt']
  constructor: (@userCodeMap, classMap) ->
    # classMap is needed for deserializing Worlds, Thangs, and other classes
    @classMap = classMap ? {Vector: Vector, Rectangle: Rectangle, Thang: Thang}
    Thang.resetThangIDs()

    @userCodeMap ?= {}
    @thangs = []
    @thangMap = {}
    @systems = []
    @systemMap = {}
    @scriptNotes = []
    @rand = new Rand 0  # Existence System may change this seed
    @frames = [new WorldFrame(@, 0)]

  destroy: ->
    @goalManager?.destroy()
    thang.destroy() for thang in @thangs
    @[key] = undefined for key of @
    @destroyed = true
    @destroy = ->

  getFrame: (frameIndex) ->
    # Optimize it a bit--assume we have all if @ended and are at the previous frame otherwise
    frames = @frames
    if @ended
      frame = frames[frameIndex]
    else if frameIndex
      frame = frames[frameIndex - 1].getNextFrame()
      frames.push frame
    else
      frame = frames[0]
    @age = frameIndex * @dt
    frame

  getThangByID: (id) ->
    @thangMap[id]

  setThang: (thang) ->
    for old, i in @thangs
      if old.id is thang.id
        @thangs[i] = thang
    @thangMap[thang.id] = thang

  thangDialogueSounds: ->
    if @frames.length < @totalFrames then throw new Error("World should be over before grabbing dialogue")
    [sounds, seen] = [[], {}]
    for frame in @frames
      for thangID, state of frame.thangStateMap
        continue unless state.thang.say and sayMessage = state.getStateForProp "sayMessage"
        soundKey = state.thang.spriteName + ":" + sayMessage
        unless seen[soundKey]
          sounds.push [state.thang.spriteName, sayMessage]
          seen[soundKey] = true
    sounds

  setGoalManager: (@goalManager) ->

  addError: (error) ->
    (@runtimeErrors ?= []).push error
    (@unhandledRuntimeErrors ?= []).push error

  loadFrames: (loadedCallback, errorCallback, loadProgressCallback, skipDeferredLoading, loadUntilFrame) ->
    return if @aborted
    unless @thangs.length
      console.log "Warning: loadFrames called on empty World (no thangs)."
    t1 = now()
    @t0 ?= t1
    if loadUntilFrame
      frameToLoadUntil = loadUntilFrame + 1
    else
      frameToLoadUntil = @totalFrames
    i = @frames.length
    while i < frameToLoadUntil
      if @debugging
        for thang in @thangs when thang.isProgrammable
          userCode = @userCodeMap[thang.id] ? {}
          for methodName, aether of userCode
            framesToLoadFlowBefore = if methodName is 'plan' or methodName is 'makeBid' then 200 else 1  # Adjust if plan() is taking even longer
            aether._shouldSkipFlow = i < loadUntilFrame - framesToLoadFlowBefore
      try
        @getFrame(i)
        ++i  # increment this after we have succeeded in getting the frame, otherwise we'll have to do that frame again
      catch error
        # Not an Aether.errors.UserCodeError; maybe we can't recover
        @addError error
      unless @preloading or @debugging
        for error in (@unhandledRuntimeErrors ? [])
          return unless errorCallback error  # errorCallback tells us whether the error is recoverable
        @unhandledRuntimeErrors = []
      t2 = now()
      if t2 - t1 > PROGRESS_UPDATE_INTERVAL
        loadProgressCallback? i / @totalFrames unless @preloading
        t1 = t2
        if t2 - @t0 > 1000
          console.log('  Loaded', i, 'of', @totalFrames, "(+" + (t2 - @t0).toFixed(0) + "ms)")
          @t0 = t2
        continueFn = =>
          return if @destroyed
          if loadUntilFrame
            @loadFrames(loadedCallback,errorCallback,loadProgressCallback, skipDeferredLoading, loadUntilFrame)
          else
            @loadFrames(loadedCallback, errorCallback, loadProgressCallback, skipDeferredLoading)
        if skipDeferredLoading
          continueFn()
        else
          setTimeout(continueFn, 0)
        return
    unless @debugging
      @ended = true
      system.finish @thangs for system in @systems
    unless @preloading
      loadProgressCallback? 1
      loadedCallback()

  finalizePreload: (loadedCallback) ->
    @preloading = false
    loadedCallback() if @ended

  abort: ->
    @aborted = true

  loadFromLevel: (level, willSimulate=true) ->
    @loadSystemsFromLevel level
    @loadThangsFromLevel level, willSimulate
    @loadScriptsFromLevel level
    system.start @thangs for system in @systems

  loadSystemsFromLevel: (level) ->
    # Remove old Systems
    @systems = []
    @systemMap = {}

    # Load new Systems
    for levelSystem in level.systems
      systemModel = levelSystem.model
      config = levelSystem.config
      systemClass = @loadClassFromCode systemModel.js, systemModel.name, "system"
      #console.log "using db system class ---\n", systemClass, "\n--- from code ---n", systemModel.js, "\n---"
      system = new systemClass @, config
      @addSystems system
    null

  loadThangsFromLevel: (level, willSimulate) ->
    # Remove old Thangs
    @thangs = []
    @thangMap = {}

    # Load new Thangs
    toAdd = []
    for d in level.thangs
      continue if d.thangType is "Interface"  # ignore old Interface Thangs until we've migrated away
      components = []
      for component in d.components
        componentModel = _.find level.levelComponents, (c) -> c.original is component.original and c.version.major is (component.majorVersion ? 0)
        #console.log "found model", componentModel, "from", component, "for", d.id, "from existing components", level.levelComponents
        componentClass = @loadClassFromCode componentModel.js, componentModel.name, "component"
        components.push [componentClass, component.config]
        #console.log "---", d.id, "using db component class ---\n", componentClass, "\n--- from code ---\n", componentModel.js, '\n---'
        #console.log "(found", componentModel, "for id", component.original, "from", level.levelComponents, ")"
      thangType = d.thangType
      thangTypeModel = _.find level.thangTypes, (t) -> t.original is thangType
      thangType = thangTypeModel.name if thangTypeModel
      thang = new Thang @, thangType, d.id
      try
        thang.addComponents components...
      catch e
        console.error "couldn't load components for", d.thangType, d.id, "because", e, e.stack, e.stackTrace
      toAdd.push thang
    @extraneousThangs = consolidateThangs toAdd if willSimulate  # combine walls, for example; serialize the leftovers later
    for thang in toAdd
      @thangs.unshift thang  # interactions happen in reverse order of specification/drawing
      @setThang thang
      @updateThangState thang
      thang.updateRegistration()
    null

  loadScriptsFromLevel: (level) ->
    @scriptNotes = []
    @scripts = []
    @addScripts level.scripts...

  loadClassFromCode: (js, name, kind="component") ->
    # Cache them based on source code so we don't have to worry about extra compilations
    @componentCodeClassMap ?= {}
    @systemCodeClassMap ?= {}
    map = if kind is "component" then @componentCodeClassMap else @systemCodeClassMap
    c = map[js]
    return c if c
    c = map[js] = eval js
    c.className = name
    c

  add: (spriteName, id, components...) ->
    thang = new Thang @, spriteName, id
    @thangs.unshift thang  # interactions happen in reverse order of specification/drawing
    @setThang thang
    thang.addComponents components...
    @updateThangState thang
    thang.updateRegistration()
    thang

  updateThangState: (thang) ->
    @frames[@frames.length-1].thangStateMap[thang.id] = thang.getState()

  size: ->
    @calculateBounds() unless @width? and @height?
    return [@width, @height] if @width? and @height?

  getBounds: ->
    @calculateBounds() unless @bounds?
    return @bounds

  calculateBounds: ->
    bounds = {left: 0, top: 0, right: 0, bottom: 0}
    hasLand = _.some @thangs, 'isLand'
    for thang in @thangs when thang.isLand or not hasLand  # Look at Lands only
      rect = thang.rectangle().axisAlignedBoundingBox()
      bounds.left = Math.min(bounds.left, rect.x - rect.width / 2)
      bounds.right = Math.max(bounds.right, rect.x + rect.width / 2)
      bounds.bottom = Math.min(bounds.bottom, rect.y - rect.height / 2)
      bounds.top = Math.max(bounds.top, rect.y + rect.height / 2)
    @width = bounds.right - bounds.left
    @height = bounds.top - bounds.bottom
    @bounds = bounds
    [@width, @height]

  publishNote: (channel, event) ->
    event ?= {}
    channel = 'world:' + channel
    for script in @scripts
      continue if script.channel isnt channel
      scriptNote = new WorldScriptNote script, event
      continue if scriptNote.invalid
      @scriptNotes.push scriptNote
    return unless @goalManager
    @goalManager.submitWorldGenerationEvent(channel, event, @frames.length)

  getGoalState: (goalID) ->
    @goalManager.getGoalState(goalID)

  setGoalState: (goalID, status) ->
    @goalManager.setGoalState(goalID, status)

  endWorld: (victory=false, delay=3, tentative=false) ->
    @totalFrames = Math.min(@totalFrames, @frames.length + Math.floor(delay / @dt))  # end a few seconds later
    @victory = victory  # TODO: should just make this signify the winning superteam
    @victoryIsTentative = tentative
    status = if @victory then 'won' else 'lost'
    @publishNote status
    console.log "The world ended in #{status} on frame #{@totalFrames}"

  addSystems: (systems...) ->
    @systems = @systems.concat systems
    for system in systems
      @systemMap[system.constructor.className] = system
  getSystem: (systemClassName) ->
    @systemMap?[systemClassName]

  addScripts: (scripts...) ->
    @scripts = (@scripts ? []).concat scripts

  addTrackedProperties: (props...) ->
    @trackedProperties = (@trackedProperties ? []).concat props

  serialize: ->
    # Code hotspot; optimize it
    if @frames.length < @totalFrames then throw new Error("World Should Be Over Before Serialization")
    [transferableObjects, nontransferableObjects] = [0, 0]
    o = {totalFrames: @totalFrames, maxTotalFrames: @maxTotalFrames, frameRate: @frameRate, dt: @dt, victory: @victory, userCodeMap: {}, trackedProperties: {}}
    o.trackedProperties[prop] = @[prop] for prop in @trackedProperties or []

    for thangID, methods of @userCodeMap
      serializedMethods = o.userCodeMap[thangID] = {}
      for methodName, method of methods
        serializedMethods[methodName] = method.serialize?() ? method # serialize the method again if it has been deserialized

    t0 = now()
    o.trackedPropertiesThangIDs = []
    o.trackedPropertiesPerThangIndices = []
    o.trackedPropertiesPerThangKeys = []
    o.trackedPropertiesPerThangTypes = []
    trackedPropertiesPerThangValues = []  # We won't send these, just the offsets and the storage buffer
    o.trackedPropertiesPerThangValuesOffsets = []  # Needed to reconstruct ArrayBufferViews on other end, since Firefox has bugs transfering those: https://bugzilla.mozilla.org/show_bug.cgi?id=841904 and https://bugzilla.mozilla.org/show_bug.cgi?id=861925
    transferableStorageBytesNeeded = 0
    nFrames = @frames.length
    for thang in @thangs
      # Don't serialize empty trackedProperties for stateless Thangs which haven't changed (like obstacles).
      # Check both, since sometimes people mark stateless Thangs but don't change them, and those should still be tracked, and the inverse doesn't work on the other end (we'll just think it doesn't exist then).
      continue if thang.stateless and not _.some(thang.trackedPropertiesUsed, Boolean)
      o.trackedPropertiesThangIDs.push thang.id
      trackedPropertiesIndices = []
      trackedPropertiesKeys = []
      trackedPropertiesTypes = []
      for used, propIndex in thang.trackedPropertiesUsed
        continue unless used
        trackedPropertiesIndices.push propIndex
        trackedPropertiesKeys.push thang.trackedPropertiesKeys[propIndex]
        trackedPropertiesTypes.push thang.trackedPropertiesTypes[propIndex]
      o.trackedPropertiesPerThangIndices.push trackedPropertiesIndices
      o.trackedPropertiesPerThangKeys.push trackedPropertiesKeys
      o.trackedPropertiesPerThangTypes.push trackedPropertiesTypes
      trackedPropertiesPerThangValues.push []
      o.trackedPropertiesPerThangValuesOffsets.push []
      for type in trackedPropertiesTypes
        transferableStorageBytesNeeded += ThangState.transferableBytesNeededForType(type, nFrames)
    if typedArraySupport
      o.storageBuffer = new ArrayBuffer(transferableStorageBytesNeeded)
    else
      o.storageBuffer = []
    storageBufferOffset = 0
    for trackedPropertiesValues, thangIndex in trackedPropertiesPerThangValues
      trackedPropertiesValuesOffsets = o.trackedPropertiesPerThangValuesOffsets[thangIndex]
      for type, propIndex in o.trackedPropertiesPerThangTypes[thangIndex]
        [storage, bytesStored] = ThangState.createArrayForType type, nFrames, o.storageBuffer, storageBufferOffset
        trackedPropertiesValues.push storage
        trackedPropertiesValuesOffsets.push storageBufferOffset
        ++transferableObjects if bytesStored
        ++nontransferableObjects unless bytesStored
        if typedArraySupport
          storageBufferOffset += bytesStored
        else
          # Instead of one big array with each storage as a view into it, they're all separate, so let's keep 'em around for flattening.
          storageBufferOffset += storage.length
          o.storageBuffer.push storage

    o.specialKeysToValues = [null, Infinity, NaN]
    # Whatever is in specialKeysToValues index 0 will be default for anything missing, so let's make sure it's null.
    # Don't think we can include undefined or it'll be treated as a sparse array; haven't tested performance.
    o.specialValuesToKeys = {}
    for specialValue, i in o.specialKeysToValues
      o.specialValuesToKeys[specialValue] = i

    t1 = now()
    o.frameHashes = []
    for frame, frameIndex in @frames
      o.frameHashes.push frame.serialize(frameIndex, o.trackedPropertiesThangIDs, o.trackedPropertiesPerThangIndices, o.trackedPropertiesPerThangTypes, trackedPropertiesPerThangValues, o.specialValuesToKeys, o.specialKeysToValues)
    t2 = now()

    unless typedArraySupport
      flattened = []
      for storage in o.storageBuffer
        for value in storage
          flattened.push value
      o.storageBuffer = flattened

    #console.log "Allocating memory:", (t1 - t0).toFixed(0), "ms; assigning values:", (t2 - t1).toFixed(0), "ms, so", ((t2 - t1) / @frames.length).toFixed(3), "ms per frame"
    #console.log "Got", transferableObjects, "transferable objects and", nontransferableObjects, "nontransferable; stored", transferableStorageBytesNeeded, "bytes transferably"

    o.thangs = (t.serialize() for t in @thangs.concat(@extraneousThangs ? []))
    o.scriptNotes = (sn.serialize() for sn in @scriptNotes)
    if o.scriptNotes.length > 200
      console.log "Whoa, serializing a lot of WorldScriptNotes here:", o.scriptNotes.length
    {serializedWorld: o, transferableObjects: [o.storageBuffer]}

  @deserialize: (o, classMap, oldSerializedWorldFrames, finishedWorldCallback) ->
    # Code hotspot; optimize it
    #console.log "Deserializing", o, "length", JSON.stringify(o).length
    #console.log JSON.stringify(o)
    #console.log "Got special keys and values:", o.specialValuesToKeys, o.specialKeysToValues
    perf = {}
    perf.t0 = now()
    w = new World o.userCodeMap, classMap
    [w.totalFrames, w.maxTotalFrames, w.frameRate, w.dt, w.scriptNotes, w.victory] = [o.totalFrames, o.maxTotalFrames, o.frameRate, o.dt, o.scriptNotes ? [], o.victory]
    w[prop] = val for prop, val of o.trackedProperties

    perf.t1 = now()
    w.thangs = (Thang.deserialize(thang, w, classMap) for thang in o.thangs)
    w.setThang thang for thang in w.thangs
    w.scriptNotes = (WorldScriptNote.deserialize(sn, w, classMap) for sn in o.scriptNotes)
    perf.t2 = now()

    o.trackedPropertiesThangs = (w.getThangByID thangID for thangID in o.trackedPropertiesThangIDs)
    o.trackedPropertiesPerThangValues = []
    for trackedPropertyTypes, thangIndex in o.trackedPropertiesPerThangTypes
      o.trackedPropertiesPerThangValues.push (trackedPropertiesValues = [])
      trackedPropertiesValuesOffsets = o.trackedPropertiesPerThangValuesOffsets[thangIndex]
      for type, propIndex in trackedPropertyTypes
        storage = ThangState.createArrayForType(type, o.totalFrames, o.storageBuffer, trackedPropertiesValuesOffsets[propIndex])[0]
        unless typedArraySupport
          # This could be more efficient
          i = trackedPropertiesValuesOffsets[propIndex]
          storage = o.storageBuffer.slice i, i + storage.length
        trackedPropertiesValues.push storage
    perf.t3 = now()

    perf.batches = 0
    w.frames = []
    _.delay @deserializeSomeFrames, 1, o, w, finishedWorldCallback, perf

  # Spread deserialization out across multiple calls so the interface stays responsive
  @deserializeSomeFrames: (o, w, finishedWorldCallback, perf) =>
    ++perf.batches
    startTime = now()
    for frameIndex in [w.frames.length ... o.totalFrames]
      w.frames.push WorldFrame.deserialize(w, frameIndex, o.trackedPropertiesThangIDs, o.trackedPropertiesThangs, o.trackedPropertiesPerThangKeys, o.trackedPropertiesPerThangTypes, o.trackedPropertiesPerThangValues, o.specialKeysToValues, o.frameHashes[frameIndex])
      if (now() - startTime) > DESERIALIZATION_INTERVAL
        _.delay @deserializeSomeFrames, 1, o, w, finishedWorldCallback, perf
        return
    @finishDeserializing w, finishedWorldCallback, perf

  @finishDeserializing: (w, finishedWorldCallback, perf) ->
    perf.t4 = now()
    w.ended = true
    w.getFrame(w.totalFrames - 1).restoreState()
    perf.t5 = now()
    console.log "Deserialization:", (perf.t5 - perf.t0).toFixed(0) + "ms (" + ((perf.t5 - perf.t0) / w.frames.length).toFixed(3) + "ms per frame).", perf.batches, "batches."
    if false
      console.log "  Deserializing--constructing new World:", (perf.t1 - perf.t0).toFixed(2) + "ms"
      console.log "  Deserializing--Thangs and ScriptNotes:", (perf.t2 - perf.t1).toFixed(2) + "ms"
      console.log "  Deserializing--reallocating memory:", (perf.t3 - perf.t2).toFixed(2) + "ms"
      console.log "  Deserializing--WorldFrames:", (perf.t4 - perf.t3).toFixed(2) + "ms"
      console.log "  Deserializing--restoring last WorldFrame:", (perf.t5 - perf.t4).toFixed(2) + "ms"
    finishedWorldCallback w

  findFirstChangedFrame: (oldWorld) ->
    return @firstChangedFrame = 0 unless oldWorld
    for newFrame, i in @frames
      oldFrame = oldWorld.frames[i]
      break unless oldFrame and newFrame.hash is oldFrame.hash
    @firstChangedFrame = i
    if @frames[i]
      console.log "First changed frame is", @firstChangedFrame, "with hash", @frames[i].hash, "compared to", oldWorld.frames[i]?.hash
    else
      console.log "No frames were changed out of all", @frames.length
    @firstChangedFrame

  pointsForThang: (thangID, frameStart=0, frameEnd=null, camera=null, resolution=4) ->
    # Optimized
    @pointsForThangCache ?= {}
    cacheKey = thangID
    allPoints = @pointsForThangCache[cacheKey]
    unless allPoints
      allPoints = []
      lastFrameIndex = @frames.length - 1
      lastPos = x: null, y: null
      for frameIndex in [lastFrameIndex .. 0] by -1
        frame = @frames[frameIndex]
        if pos = frame.thangStateMap[thangID]?.getStateForProp 'pos'
          pos = camera.worldToSurface {x: pos.x, y: pos.y} if camera  # without z
          if not lastPos.x? or (Math.abs(lastPos.x - pos.x) + Math.abs(lastPos.y - pos.y)) > 1
            lastPos = pos
        allPoints.push lastPos.y, lastPos.x unless lastPos.y is 0 and lastPos.x is 0
      allPoints.reverse()
      @pointsForThangCache[cacheKey] = allPoints

    points = []
    [lastX, lastY] = [null, null]
    for frameIndex in [Math.floor(frameStart / resolution) ... Math.ceil(frameEnd / resolution)]
      x = allPoints[frameIndex * 2 * resolution]
      y = allPoints[frameIndex * 2 * resolution + 1]
      continue if x is lastX and y is lastY
      lastX = x
      lastY = y
      points.push x, y
    points

  actionsForThang: (thangID, keepIdle=false) ->
    # Optimized
    @actionsForThangCache ?= {}
    cacheKey = thangID + "_" + Boolean(keepIdle)
    cached = @actionsForThangCache[cacheKey]
    return cached if cached
    states = (frame.thangStateMap[thangID] for frame in @frames)
    actions = []
    lastAction = ''
    for state, i in states
      action = state?.getStateForProp 'action'
      continue unless action and (action isnt lastAction or state.actionActivated)
      continue unless state.action isnt 'idle' or keepIdle
      actions.push {frame: i, pos: state.pos, name: action}
      lastAction = action
    @actionsForThangCache[cacheKey] = actions
    return actions

  getTeamColors: ->
    teamConfigs = @teamConfigs or {}
    colorConfigs = {}
    colorConfigs[teamName] = config.color for teamName, config of teamConfigs
    colorConfigs

  teamForPlayer: (n) ->
    playableTeams = @playableTeams ? ['humans']
    playableTeams[n % playableTeams.length]
