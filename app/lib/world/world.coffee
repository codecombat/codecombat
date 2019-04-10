_ = require('lodash') # TODO webpack: Get these two loading from lodash entry, probably
_.string = require('underscore.string')
Vector = require './vector'
Rectangle = require './rectangle'
Ellipse = require './ellipse'
LineSegment = require './line_segment'
WorldFrame = require './world_frame'
Thang = require './thang'
ThangState = require './thang_state'
Rand = require './rand'
WorldScriptNote = require './world_script_note'
{now, consolidateThangs, typedArraySupport} = require './world_utils'
Component = require 'lib/world/component'
System = require 'lib/world/system'
PROGRESS_UPDATE_INTERVAL = 100
DESERIALIZATION_INTERVAL = 10
REAL_TIME_BUFFER_MIN = 2 * PROGRESS_UPDATE_INTERVAL
REAL_TIME_BUFFER_MAX = 3 * PROGRESS_UPDATE_INTERVAL
REAL_TIME_BUFFERED_WAIT_INTERVAL = 0.5 * PROGRESS_UPDATE_INTERVAL
REAL_TIME_COUNTDOWN_DELAY = 3000  # match CountdownScreen
ITEM_ORIGINAL = '53e12043b82921000051cdf9'
EXISTS_ORIGINAL = '524b4150ff92f1f4f8000024'
COUNTDOWN_LEVELS = ['sky-span']
window.string_score = require 'vendor/scripts/string_score.js' # Used as a global in DB code
require 'vendor/scripts/coffeescript' # Install the global CoffeeScript compiler #TODO Performance: Load this only when necessary
require('lib/worldLoader') # Install custom hack to dynamically require library files

module.exports = class World
  @className: 'World'
  age: 0
  ended: false
  preloading: false  # Whether we are just preloading a world in case we soon cast it
  debugging: false  # Whether we are just rerunning to debug a world we've already cast
  headless: false  # Whether we are just simulating for goal states instead of all serialized results
  synchronous: false  # Whether we are simulating the game on the main thread and don't need to serialize/deserialize
  framesSerializedSoFar: 0
  framesClearedSoFar: 0
  apiProperties: ['age', 'dt']
  realTimeBufferMax: REAL_TIME_BUFFER_MAX / 1000
  constructor: (@userCodeMap, classMap) ->
    # classMap is needed for deserializing Worlds, Thangs, and other classes
    @classMap = classMap ? {Vector: Vector, Rectangle: Rectangle, Thang: Thang, Ellipse: Ellipse, LineSegment: LineSegment}
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
    thang.stateChanged = true
    for old, i in @thangs
      if old.id is thang.id
        @thangs[i] = thang
        break
    @thangMap[thang.id] = thang

  thangDialogueSounds: (startFrame=0) ->
    return [] unless startFrame < @frames.length
    [sounds, seen] = [[], {}]
    for frameIndex in [startFrame ... @frames.length]
      frame = @frames[frameIndex]
      for thangID, state of frame.thangStateMap
        continue unless state.thang.say and sayMessage = state.getStateForProp 'sayMessage'
        soundKey = state.thang.spriteName + ':' + sayMessage
        unless seen[soundKey]
          sounds.push [state.thang.spriteName, sayMessage]
          seen[soundKey] = true
    sounds

  setGoalManager: (@goalManager) ->

  addError: (error) ->
    (@runtimeErrors ?= []).push error
    (@unhandledRuntimeErrors ?= []).push error

  loadFrames: (loadedCallback, errorCallback, loadProgressCallback, preloadedCallback, skipDeferredLoading, loadUntilFrame) ->
    return if @aborted
    @totalFrames = 2 if @justBegin
    console.log 'Warning: loadFrames called on empty World (no thangs).' unless @thangs.length
    continueLaterFn = =>
      @loadFrames(loadedCallback, errorCallback, loadProgressCallback, preloadedCallback, skipDeferredLoading, loadUntilFrame) unless @destroyed
    if @realTime and not @countdownFinished
      @realTimeSpeedFactor = 1
      unless @showsCountdown
        if @levelID in ['woodland-cleaver', 'village-guard', 'shield-rush']
          @realTimeSpeedFactor = 2
        else if @levelID in ['thornbush-farm', 'back-to-back', 'ogre-encampment', 'peasant-protection', 'munchkin-swarm', 'munchkin-harvest', 'swift-dagger', 'shrapnel', 'arcane-ally', 'touch-of-death', 'bonemender']
          @realTimeSpeedFactor = 3
      if @showsCountdown
        return setTimeout @finishCountdown(continueLaterFn), REAL_TIME_COUNTDOWN_DELAY
      else
        @finishCountdown continueLaterFn
    t1 = now()
    @t0 ?= t1
    @worldLoadStartTime ?= t1
    @lastRealTimeUpdate ?= 0
    frameToLoadUntil = if loadUntilFrame then loadUntilFrame + 1 else @totalFrames  # Might stop early if debugging.
    i = @frames.length
    while true
      if @indefiniteLength
        break if not @realTime # realtime has been stopped
        break if @victory? # game won or lost  # TODO: give a couple seconds of buffer after victory is set instead of ending instantly
      else
        break if i >= frameToLoadUntil
        break if i >= @totalFrames
      return unless @shouldContinueLoading t1, loadProgressCallback, skipDeferredLoading, continueLaterFn
      @adjustFlowSettings loadUntilFrame if @debugging
      try
        @getFrame(i)
        ++i  # Increment this after we have succeeded in getting the frame, otherwise we'll have to do that frame again
      catch error
        @addError error  # Not an Aether.errors.UserCodeError; maybe we can't recover
      unless @preloading or @debugging
        for error in (@unhandledRuntimeErrors ? [])
          return unless errorCallback error  # errorCallback tells us whether the error is recoverable
        @unhandledRuntimeErrors = []
    @finishLoadingFrames loadProgressCallback, loadedCallback, preloadedCallback

  finishLoadingFrames: (loadProgressCallback, loadedCallback, preloadedCallback) ->
    unless @debugging
      @ended = true
      system.finish @thangs for system in @systems
    if @preloading
      preloadedCallback()
    else
      loadProgressCallback? 1
      loadedCallback()

  finishCountdown: (continueLaterFn) -> =>
    return if @destroyed
    @countdownFinished = true
    continueLaterFn()

  shouldDelayRealTimeSimulation: (t) ->
    return false unless @realTime
    timeSinceStart = (t - @worldLoadStartTime) * @realTimeSpeedFactor
    timeLoaded = @frames.length * @dt * 1000
    timeBuffered = timeLoaded - timeSinceStart
    if @indefiniteLength
      return timeBuffered > 0
    else
      return timeBuffered > REAL_TIME_BUFFER_MAX * @realTimeSpeedFactor

  shouldUpdateRealTimePlayback: (t) ->
    return false unless @realTime
    return false if @frames.length * @dt is @lastRealTimeUpdate
    timeLoaded = @frames.length * @dt * 1000
    timeSinceStart = (t - @worldLoadStartTime) * @realTimeSpeedFactor
    remainingBuffer = @lastRealTimeUpdate * 1000 - timeSinceStart
    if @indefiniteLength
      return remainingBuffer <= 0
    else
      return remainingBuffer < REAL_TIME_BUFFER_MIN * @realTimeSpeedFactor

  shouldContinueLoading: (t1, loadProgressCallback, skipDeferredLoading, continueLaterFn) ->
    t2 = now()
    chunkSize = @frames.length - @framesSerializedSoFar
    simedTime = @frames.length / @frameRate

    chunkTime = switch
      when simedTime > 15 then 7
      when simedTime > 10 then 5
      when simedTime > 5 then 3
      when simedTime > 2 then 1
      else 0.5

    bailoutTime = Math.max(2000*chunkTime, 10000)

    dt = t2 - t1

    if @realTime
      shouldUpdateProgress = @shouldUpdateRealTimePlayback t2
      shouldDelayRealTimeSimulation = not shouldUpdateProgress and @shouldDelayRealTimeSimulation t2
    else
      shouldUpdateProgress = (dt > PROGRESS_UPDATE_INTERVAL and (chunkSize / @frameRate >= chunkTime) or dt > bailoutTime)
      shouldDelayRealTimeSimulation = false
    return true unless shouldUpdateProgress or shouldDelayRealTimeSimulation
    # Stop loading frames for now; continue in a moment.
    if shouldUpdateProgress
      @lastRealTimeUpdate = @frames.length * @dt if @realTime
      #console.log 'we think it is now', (t2 - @worldLoadStartTime) / 1000, 'so delivering', @lastRealTimeUpdate
      loadProgressCallback? @frames.length / @totalFrames unless @preloading
    t1 = t2
    if t2 - @t0 > 1000
      console.log '  Loaded', @frames.length, 'of', @totalFrames, '(+' + (t2 - @t0).toFixed(0) + 'ms)' unless @realTime
      @t0 = t2
    if skipDeferredLoading
      continueLaterFn()
    else
      delay = 0
      if shouldDelayRealTimeSimulation
        if @indefiniteLength
          delay = 1000 / 30
        else
          delay = REAL_TIME_BUFFERED_WAIT_INTERVAL
      setTimeout continueLaterFn, delay
    false

  adjustFlowSettings: (loadUntilFrame) ->
    for thang in @thangs when thang.isProgrammable
      userCode = @userCodeMap[thang.id] ? {}
      for methodName, aether of userCode
        framesToLoadFlowBefore = if methodName is 'plan' or methodName is 'makeBid' then 200 else 1  # Adjust if plan() is taking even longer
        aether._shouldSkipFlow = @frames.length < loadUntilFrame - framesToLoadFlowBefore

  finalizePreload: (loadedCallback) ->
    @preloading = false
    loadedCallback() if @ended

  abort: ->
    @aborted = true

  addFlagEvent: (flagEvent) ->
    @flagHistory.push flagEvent

  addRealTimeInputEvent: (realTimeInputEvent) ->
    @realTimeInputEvents.push realTimeInputEvent

  loadFromLevel: (level, willSimulate=true) ->
    @levelID = level.slug
    @levelComponents = level.levelComponents
    @thangTypes = level.thangTypes
    @loadScriptsFromLevel level
    @loadSystemsFromLevel level
    @loadThangsFromLevel level, willSimulate
    @showsCountdown = @levelID in COUNTDOWN_LEVELS or _.any(@thangs, (t) -> (t.programmableProperties and 'findFlags' in t.programmableProperties) or t.inventory?.flag)
    @picoCTFProblem = level.picoCTFProblem if level.picoCTFProblem
    if @picoCTFProblem?.instances and not @picoCTFProblem.flag_sha1
      @picoCTFProblem = _.merge @picoCTFProblem, @picoCTFProblem.instances[0]
    for system in @systems
      try
        system.start @thangs
      catch err
        console.error "Error starting system!", system, err
    @constrainHeroHealth(level)

  loadSystemsFromLevel: (level) ->
    # Remove old Systems
    @systems = []
    @systemMap = {}

    # Load new Systems
    for levelSystem in level.systems
      systemModel = levelSystem.model
      config = levelSystem.config
      systemClass = @loadClassFromCode systemModel.js, systemModel.name, 'system'
      #console.log "using db system class ---\n", systemClass, "\n--- from code ---n", systemModel.js, "\n---"
      system = new systemClass @, config
      @addSystems system
    null

  loadThangsFromLevel: (level, willSimulate) ->
    # Remove old Thangs
    @thangs = []
    @thangMap = {}

    # Load new Thangs
    toAdd = (@loadThangFromLevel thangConfig, level.levelComponents, level.thangTypes for thangConfig in level.thangs ? [])
    @extraneousThangs = consolidateThangs toAdd if willSimulate and not @synchronous  # Combine walls, for example; serialize the leftovers later
    @addThang thang for thang in toAdd
    null

  loadThangFromLevel: (thangConfig, levelComponents, thangTypes, equipBy=null) ->
    components = []
    for component, componentIndex in thangConfig.components
      componentModel = _.find levelComponents, (c) ->
        c.original is component.original and c.version.major is (component.majorVersion ? 0)
      componentClass = @loadClassFromCode componentModel.js, componentModel.name, 'component'
      components.push [componentClass, component.config]
      if component.original is ITEM_ORIGINAL
        isItem = true
        component.config.ownerID = equipBy if equipBy
      else if component.original is EXISTS_ORIGINAL
        existsConfigIndex = componentIndex
    if isItem and existsConfigIndex?
      # For memory usage performance, make sure these don't get any tracked properties assigned.
      components[existsConfigIndex][1] = {exists: false, stateless: true}
    thangTypeOriginal = thangConfig.thangType
    thangTypeModel = _.find thangTypes, (t) -> t.original is thangTypeOriginal
    return console.error thangConfig.id ? equipBy, 'could not find ThangType for', thangTypeOriginal unless thangTypeModel
    thangTypeName = thangTypeModel.name
    thang = new Thang @, thangTypeName, thangConfig.id
    try
      thang.addComponents components...
    catch e
      console.error 'couldn\'t load components for', thangTypeOriginal, thangConfig.id, 'because', e.toString(), e.stack
    thang

  addThang: (thang) ->
    @thangs.unshift thang  # Interactions happen in reverse order of specification/drawing
    @setThang thang
    @updateThangState thang
    thang.updateRegistration()
    thang

  loadScriptsFromLevel: (level) ->
    @scriptNotes = []
    @scripts = []
    @addScripts level.scripts...

  loadClassFromCode: (js, name, kind='component') ->
    # Cache them based on source code so we don't have to worry about extra compilations
    @componentCodeClassMap ?= {}
    @systemCodeClassMap ?= {}
    map = if kind is 'component' then @componentCodeClassMap else @systemCodeClassMap
    c = map[js]
    return c if c
    try
      require = window.libWorldRequire
      c = map[js] = eval js
    catch err
      console.error "Couldn't compile #{kind} code:", err, "\n", js
      c = map[js] = {}
    c.className = name
    c

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
    for thang in @thangs when thang.isLand or (not hasLand and thang.rectangle)  # Look at Lands only
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
    for script in @scripts ? []
      continue if script.channel isnt channel
      scriptNote = new WorldScriptNote script, event
      continue if scriptNote.invalid
      @scriptNotes.push scriptNote
    return unless @goalManager
    @goalManager.submitWorldGenerationEvent(channel, event, @frames.length)

  publishCameraEvent: (eventName, event) ->
    return if not Backbone?.Mediator # headless mode don't have this
    event ?= {}
    eventName = 'camera:' + eventName
    Backbone.Mediator.publish(eventName, event)

  getGoalState: (goalID) ->
    @goalManager.getGoalState(goalID)

  setGoalState: (goalID, status) ->
    @goalManager.setGoalState(goalID, status)

  endWorld: (victory=false, delay=3, tentative=false) ->
    maximumFrame = if @indefiniteLength then Infinity else @totalFrames
    @totalFrames = Math.min(maximumFrame, @frames.length + Math.floor(delay / @dt))  # end a few seconds later
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
    @freeMemoryBeforeFinalSerialization() if @ended
    startFrame = @framesSerializedSoFar
    endFrame = @frames.length
    if @indefiniteLength
      toClear = Math.max(@framesSerializedSoFar-10, 0)
      for i in _.range(@framesClearedSoFar, toClear)
        @frames[i] = null
      @framesClearedSoFar = @framesSerializedSoFar
    #console.log "... world serializing frames from", startFrame, "to", endFrame, "of", @totalFrames
    [transferableObjects, nontransferableObjects] = [0, 0]
    serializedFlagHistory = (_.omit(_.clone(flag), 'processed') for flag in @flagHistory)
    o = {totalFrames: @totalFrames, maxTotalFrames: @maxTotalFrames, frameRate: @frameRate, dt: @dt, victory: @victory, userCodeMap: {}, trackedProperties: {}, flagHistory: serializedFlagHistory, difficulty: @difficulty, scores: @getScores(), randomSeed: @randomSeed, picoCTFFlag: @picoCTFFlag, keyValueDb: @keyValueDb}
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
    o.trackedPropertiesPerThangValuesOffsets = []  # Needed to reconstruct ArrayBufferViews on other end, since Firefox has bugs transfering those: https://bugzilla.mozilla.org/show_bug.cgi?id=841904 and https://bugzilla.mozilla.org/show_bug.cgi?id=861925  # Actually, as of January 2014, it should be fixed. So we could try to undo the workaround.
    transferableStorageBytesNeeded = 0
    nFrames = endFrame - startFrame
    for thang in @thangs
      # Don't serialize empty trackedProperties for stateless Thangs which haven't changed (like obstacles).
      # Check both, since sometimes people mark stateless Thangs but then change them, and those should still be tracked, and the inverse doesn't work on the other end (we'll just think it doesn't exist then).
      # If streaming the world, a thang marked stateless that actually change will get messed up. I think.
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
    transferableStorageBytesNeeded += ThangState.transferableBytesNeededForType('number', @scoreTypes.length * nFrames)
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
    [o.scoresStorage, scoresBytesStored] = ThangState.createArrayForType 'number', nFrames * @scoreTypes.length, o.storageBuffer, storageBufferOffset

    o.specialKeysToValues = [null, Infinity, NaN]
    # Whatever is in specialKeysToValues index 0 will be default for anything missing, so let's make sure it's null.
    # Don't think we can include undefined or it'll be treated as a sparse array; haven't tested performance.
    o.specialValuesToKeys = {}
    for specialValue, i in o.specialKeysToValues
      o.specialValuesToKeys[specialValue] = i

    t1 = now()
    o.frameHashes = []
    for frameIndex in [startFrame ... endFrame]
      o.frameHashes.push @frames[frameIndex].serialize(frameIndex - startFrame, o.trackedPropertiesThangIDs, o.trackedPropertiesPerThangIndices, o.trackedPropertiesPerThangTypes, trackedPropertiesPerThangValues, o.specialValuesToKeys, o.specialKeysToValues, o.scoresStorage)
    t2 = now()

    unless typedArraySupport
      flattened = []
      for storage in o.storageBuffer
        for value in storage
          flattened.push value
      o.storageBuffer = flattened

    #console.log 'Allocating memory:', (t1 - t0).toFixed(0), 'ms; assigning values:', (t2 - t1).toFixed(0), 'ms, so', ((t2 - t1) / nFrames).toFixed(3), 'ms per frame for', nFrames, 'frames'
    #console.log 'Got', transferableObjects, 'transferable objects and', nontransferableObjects, 'nontransferable; stored', transferableStorageBytesNeeded, 'bytes transferably'

    o.thangs = (t.serialize() for t in @thangs.concat(@extraneousThangs ? []))
    o.scriptNotes = (sn.serialize() for sn in @scriptNotes)
    if o.scriptNotes.length > 200
      console.log 'Whoa, serializing a lot of WorldScriptNotes here:', o.scriptNotes.length
    @freeMemoryAfterEachSerialization() unless @ended
    {serializedWorld: o, transferableObjects: [o.storageBuffer], startFrame: startFrame, endFrame: endFrame}

  @deserialize: (o, classMap, oldSerializedWorldFrames, finishedWorldCallback, startFrame, endFrame, level, streamingWorld) ->
    # Code hotspot; optimize it
    #console.log 'Deserializing', o, 'length', JSON.stringify(o).length
    #console.log JSON.stringify(o)
    #console.log 'Got special keys and values:', o.specialValuesToKeys, o.specialKeysToValues
    perf = {}
    perf.t0 = now()
    nFrames = endFrame - startFrame
    if streamingWorld
      w = streamingWorld
      # Make sure we get any Aether updates from the new frames into the already-deserialized streaming world Aethers.
      for thangID, methods of o.userCodeMap
        for methodName, serializedAether of methods
          for aetherStateKey in ['flow', 'metrics', 'style', 'problems']
            w.userCodeMap[thangID] ?= {}
            w.userCodeMap[thangID][methodName] ?= {}
            w.userCodeMap[thangID][methodName][aetherStateKey] = serializedAether[aetherStateKey]
    else
      w = new World o.userCodeMap, classMap
    [w.totalFrames, w.maxTotalFrames, w.frameRate, w.dt, w.scriptNotes, w.victory, w.flagHistory, w.difficulty, w.scores, w.randomSeed, w.picoCTFFlag, w.keyValueDb] = [o.totalFrames, o.maxTotalFrames, o.frameRate, o.dt, o.scriptNotes ? [], o.victory, o.flagHistory, o.difficulty, o.scores, o.randomSeed, o.picoCTFFlag, o.keyValueDb]
    w[prop] = val for prop, val of o.trackedProperties

    perf.t1 = now()
    if w.thangs.length
      for thangConfig in o.thangs
        if thang = w.thangMap[thangConfig.id]
          for prop, val of thangConfig.finalState
            thang[prop] = val
        else
          w.thangs.push thang = Thang.deserialize(thangConfig, w, classMap, level.levelComponents)
          w.setThang thang
    else
      w.thangs = (Thang.deserialize(thang, w, classMap, level.levelComponents) for thang in o.thangs)
      w.setThang thang for thang in w.thangs
    w.scriptNotes = (WorldScriptNote.deserialize(sn, w, classMap) for sn in o.scriptNotes)
    perf.t2 = now()

    o.trackedPropertiesThangs = (w.getThangByID thangID for thangID in o.trackedPropertiesThangIDs)
    o.trackedPropertiesPerThangValues = []
    for trackedPropertyTypes, thangIndex in o.trackedPropertiesPerThangTypes
      o.trackedPropertiesPerThangValues.push (trackedPropertiesValues = [])
      trackedPropertiesValuesOffsets = o.trackedPropertiesPerThangValuesOffsets[thangIndex]
      for type, propIndex in trackedPropertyTypes
        storage = ThangState.createArrayForType(type, nFrames, o.storageBuffer, trackedPropertiesValuesOffsets[propIndex])[0]
        unless typedArraySupport
          # This could be more efficient
          i = trackedPropertiesValuesOffsets[propIndex]
          storage = o.storageBuffer.slice i, i + storage.length
        trackedPropertiesValues.push storage
    perf.t3 = now()

    perf.batches = 0
    perf.framesCPUTime = 0
    w.frames = [] unless streamingWorld
    clearTimeout @deserializationTimeout if @deserializationTimeout

    if w.indefiniteLength
      clearTo = Math.max(w.frames.length - 100, 0)
      if clearTo > w.framesClearedSoFar
        for i in _.range(w.framesClearedSoFar, clearTo)
          w.frames[i] = null
      w.framesClearedSoFar = clearTo

    @deserializationTimeout = _.delay @deserializeSomeFrames, 1, o, w, finishedWorldCallback, perf, startFrame, endFrame
    w  # Return in-progress deserializing world

  # Spread deserialization out across multiple calls so the interface stays responsive
  @deserializeSomeFrames: (o, w, finishedWorldCallback, perf, startFrame, endFrame) =>
    ++perf.batches
    startTime = now()
    for frameIndex in [w.frames.length ... endFrame]
      w.frames.push WorldFrame.deserialize(w, frameIndex - startFrame, o.trackedPropertiesThangIDs, o.trackedPropertiesThangs, o.trackedPropertiesPerThangKeys, o.trackedPropertiesPerThangTypes, o.trackedPropertiesPerThangValues, o.specialKeysToValues, o.scoresStorage, o.frameHashes[frameIndex - startFrame], w.dt * frameIndex)
      elapsed = now() - startTime
      if elapsed > DESERIALIZATION_INTERVAL and frameIndex < endFrame - 1
        #console.log "  Deserialization not finished, let's do it again soon. Have:", w.frames.length, ", wanted from", startFrame, "to", endFrame
        perf.framesCPUTime += elapsed
        @deserializationTimeout = _.delay @deserializeSomeFrames, 1, o, w, finishedWorldCallback, perf, startFrame, endFrame
        return
    @deserializationTimeout = null
    perf.framesCPUTime += elapsed
    @finishDeserializing w, finishedWorldCallback, perf, startFrame, endFrame

  @finishDeserializing: (w, finishedWorldCallback, perf, startFrame, endFrame) ->
    perf.t4 = now()
    w.ended = true
    nFrames = endFrame - startFrame
    totalCPUTime = perf.t3 - perf.t0 + perf.framesCPUTime
    #console.log 'Deserialization:', totalCPUTime.toFixed(0) + 'ms (' + (totalCPUTime / nFrames).toFixed(3) + 'ms per frame).', perf.batches, 'batches. Did', startFrame, 'to', endFrame, 'in', (perf.t4 - perf.t0).toFixed(0) + 'ms wall clock time.'
    if false
      console.log '  Deserializing--constructing new World:', (perf.t1 - perf.t0).toFixed(2) + 'ms'
      console.log '  Deserializing--Thangs and ScriptNotes:', (perf.t2 - perf.t1).toFixed(2) + 'ms'
      console.log '  Deserializing--reallocating memory:', (perf.t3 - perf.t2).toFixed(2) + 'ms'
      console.log '  Deserializing--WorldFrames:', (perf.t4 - perf.t3).toFixed(2) + 'ms wall clock time,', (perf.framesCPUTime).toFixed(2) + 'ms CPU time'
    finishedWorldCallback w

  findFirstChangedFrame: (oldWorld) ->
    return 0 unless oldWorld
    for newFrame, i in @frames
      oldFrame = oldWorld.frames[i]
      break unless oldFrame and ((newFrame.hash is oldFrame.hash) or not newFrame.hash? or not oldFrame.hash?)  # undefined gets in there when streaming at the last frame of each batch for some reason
    firstChangedFrame = i
    if @frames.length is @totalFrames
      if @frames[i]
        console.log 'First changed frame is', firstChangedFrame, 'with hash', @frames[i].hash, 'compared to', oldWorld.frames[i]?.hash
      else
        console.log 'No frames were changed out of all', @frames.length
    firstChangedFrame

  freeMemoryBeforeFinalSerialization: ->
    @levelComponents = null
    @thangTypes = null

  freeMemoryAfterEachSerialization: ->
    @frames[i] = null for frame, i in @frames when i < @frames.length - 1

  pointsForThang: (thangID, camera=null) ->
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
        continue unless frame # may have been evicted for game dev levels
        if pos = frame.thangStateMap[thangID]?.getStateForProp 'pos'
          pos = camera.worldToSurface {x: pos.x, y: pos.y} if camera  # without z
          if not lastPos.x? or (Math.abs(lastPos.x - pos.x) + Math.abs(lastPos.y - pos.y)) > 1
            lastPos = pos
        allPoints.push lastPos.y, lastPos.x unless lastPos.y is 0 and lastPos.x is 0
      allPoints.reverse()
      @pointsForThangCache[cacheKey] = allPoints

    return allPoints

  actionsForThang: (thangID, keepIdle=false) ->
    # Optimized
    @actionsForThangCache ?= {}
    cacheKey = thangID + '_' + Boolean(keepIdle)
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
    if n?
      playableTeams[n % playableTeams.length]
    else
      _.sample playableTeams  # Pick at random for good distribution

  scoreTypes: ['time', 'damage-taken', 'damage-dealt', 'gold-collected', 'difficulty', 'survival-time', 'defeated']
  # Not 'code-length', that doesn't need to be stored per each frame

  getScores: ->
    time: @age
    'damage-taken': @getSystem('Combat')?.damageTakenForTeam 'humans'
    'damage-dealt': @getSystem('Combat')?.damageDealtForTeam 'humans'
    'gold-collected': @getSystem('Inventory')?.teamGold.humans?.collected
    'difficulty': @difficulty
    'code-length': @getThangByID('Hero Placeholder')?.linesOfCodeUsed
    'survival-time': @age
    'defeated': @getSystem('Combat')?.defeatedByTeam 'humans'

  constrainHeroHealth: (level) ->
    return unless level.constrainHeroHealth
    hero = _.find @thangs, id: 'Hero Placeholder'
    if hero?
      if level.recommendedHealth?
        hero.maxHealth = Math.max(hero.maxHealth, level.recommendedHealth)
      if level.maximumHealth?
        hero.maxHealth = Math.min(hero.maxHealth, level.maximumHealth)
      hero.health = hero.maxHealth