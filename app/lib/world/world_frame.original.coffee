ThangState = require './thang_state'

module.exports = class WorldFrame
  @className: 'WorldFrame'

  constructor: (@world, @time=0) ->
    @thangStateMap = {}
    if @world
      @scores = _.omit @world.getScores(), 'code-length'
      @setState()

  getNextFrame: ->
    # Optimized. Must be called while thangs are current at this frame.
    nextTime = @time + @world.dt
    return null if nextTime > @world.lifespan and not @world.indefiniteLength
    @hash = @world.rand.seed
    @hash += system.update() for system in @world.systems
    nextFrame = new WorldFrame(@world, nextTime)
    return nextFrame

  setState: ->
    return if @world.synchronous or @world.headless
    for thang in @world.thangs when not thang.stateless
      @thangStateMap[thang.id] = thang.getState()

  restoreState: ->
    return if @world.synchronous or @world.headless
    thangState.restore() for thangID, thangState of @thangStateMap
    for thang in @world.thangs
      if not @thangStateMap[thang.id] and not thang.stateless
        #console.log 'Frame', @time, 'restoring state for', thang.id, 'and saying it don\'t exist'
        thang.exists = false

  restorePartialState: (ratio) ->
    return if @world.synchronous or @world.headless
    thangState.restorePartial ratio for thangID, thangState of @thangStateMap

  restoreStateForThang: (thang) ->
    return if @world.synchronous or @world.headless
    thangState = @thangStateMap[thang.id]
    if not thangState
      if not thang.stateless
        thang.exists = false
        #console.log 'Frame', @time, 'restoring state for', thang.id, 'in particular and saying it don\'t exist'
      return
    thangState.restore()

  clearEvents: -> thang.currentEvents = [] for thang in @world.thangs

  toString: ->
    map = ((' ' for x in [0 .. @world.width])  \
           for y in [0 .. @world.height])
    symbols = '.ox@dfga[]/D'
    for thang, i in @world.thangs when thang.rectangle
      rect = thang.rectangle().axisAlignedBoundingBox()
      for y in [Math.floor(rect.y - rect.height / 2) ... Math.ceil(rect.y + rect.height / 2)]
        for x in [Math.floor(rect.x - rect.width / 2) ... Math.ceil(rect.x + rect.width / 2)]
          map[y][x] = symbols[i % symbols.length] if 0 <= y < @world.height and 0 <= x < @world.width
    @time + '\n' + (xs.join(' ') for xs in map).join('\n') + '\n'

  serialize: (frameIndex, trackedPropertiesThangIDs, trackedPropertiesPerThangIndices, trackedPropertiesPerThangTypes, trackedPropertiesPerThangValues, specialValuesToKeys, specialKeysToValues, scoresStorage) ->
    # Optimize
    for thangID, thangIndex in trackedPropertiesThangIDs
      thangState = @thangStateMap[thangID]
      if thangState
        thangState.serialize(frameIndex, trackedPropertiesPerThangIndices[thangIndex], trackedPropertiesPerThangTypes[thangIndex], trackedPropertiesPerThangValues[thangIndex], specialValuesToKeys, specialKeysToValues)
    scoreValues = _.values(@scores)
    for score, scoreIndex in scoreValues
      scoresStorage[frameIndex * scoreValues.length + scoreIndex] = score or 0
    @hash

  @deserialize: (world, frameIndex, trackedPropertiesThangIDs, trackedPropertiesThangs, trackedPropertiesPerThangKeys, trackedPropertiesPerThangTypes, trackedPropertiesPerThangValues, specialKeysToValues, scoresStorage, hash, age) ->
    # Optimize
    wf = new WorldFrame null, age
    wf.world = world
    wf.hash = hash
    wf.scores = {}
    for thangID, thangIndex in trackedPropertiesThangIDs
      wf.thangStateMap[thangID] = ThangState.deserialize world, frameIndex, trackedPropertiesThangs[thangIndex], trackedPropertiesPerThangKeys[thangIndex], trackedPropertiesPerThangTypes[thangIndex], trackedPropertiesPerThangValues[thangIndex], specialKeysToValues
    for scoreType, scoreIndex in world.scoreTypes
      wf.scores[scoreType] = scoresStorage[frameIndex * world.scoreTypes.length + scoreIndex]
    wf
