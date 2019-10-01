{clone, typedArraySupport} = require './world_utils'
Vector = require './vector'

if typedArraySupport
  FloatArrayType = Float32Array  # Better performance than Float64Array
  bytesPerFloat = FloatArrayType.BYTES_PER_ELEMENT ? FloatArrayType.prototype.BYTES_PER_ELEMENT
else
  bytesPerFloat = 4

module.exports = class ThangState
  @className: 'ThangState'
  @trackedPropertyTypes: [
    'boolean'
    'number'
    'string'
    'array'  # will turn everything into strings
    'object'  # grrr
    'Vector'
    'Thang'  # serialized as ids, like strings
  ]

  hasRestored: false
  constructor: (thang) ->
    @props = []  # parallel array to @thang's trackedPropertiesKeys/Types
    return unless thang
    @thang = thang
    for prop, propIndex in thang.trackedPropertiesKeys
      type = thang.trackedPropertiesTypes[propIndex]
      value = thang[prop]
      if type is 'Vector'
        @props.push value?.copy()  # could try storing [x, y, z] or {x, y, z} here instead if this is expensive
      else if type is 'object' or type is 'array'
        @props.push clone(value, true)
      else
        @props.push value

  # Either pass storage and type, or don't pass either of them
  getStoredProp: (propIndex, type, storage) ->
    # Optimize it
    unless type
      type = @trackedPropertyTypes[propIndex]
      storage = @trackedPropertyValues[propIndex]
    if type is 'Vector'
      value = new Vector storage[3 * @frameIndex], storage[3 * @frameIndex + 1], storage[3 * @frameIndex + 2]
    else if type is 'string'
      specialKey = storage[@frameIndex]
      value = @specialKeysToValues[specialKey]
    else if type is 'Thang'
      specialKey = storage[@frameIndex]
      value = @thang.world.getThangByID @specialKeysToValues[specialKey]
    else if type is 'array'
      specialKey = storage[@frameIndex]
      valueString = @specialKeysToValues[specialKey]
      if valueString and valueString.length > 1
        # Trim leading Group Separator and trailing Record Separator, split by Record Separators, restore string array.
        value = valueString.substring(1, valueString.length - 1).split '\x1E'
      else
        value = []
    else
      value = storage[@frameIndex]
    value

  getStateForProp: (prop) ->
    # Get the property, whether we have it stored in @props or in @trackedPropertyValues. Optimize it.
    # Figured based on http://jsperf.com/object-vs-array-vs-native-linked-list/13 that it should be faster with small arrays to do the indexOf reads (each up to 24x faster) than to do a single object read, and then we don't have to maintain an extra @props object; just keep array
    return @thang[prop] if @thang.world.synchronous
    propIndex = @trackedPropertyKeys.indexOf prop
    if propIndex is -1
      initialPropIndex = @thang.unusedTrackedPropertyKeys.indexOf prop
      return null if initialPropIndex is -1
      return @thang.unusedTrackedPropertyValues[initialPropIndex]
    value = @props[propIndex]
    return value if value isnt undefined or @hasRestored
    return @props[propIndex] = @getStoredProp propIndex

  restore: ->
    # Restore trackedProperties' values to @thang, retrieving them from @trackedPropertyValues if needed. Optimize it.
    return @ if @thang._state is @ and not @thang.partialState
    unless @hasRestored  # Restoring in a deserialized World for first time
      return @ if @thang.world.synchronous
      for prop, propIndex in @thang.unusedTrackedPropertyKeys when @trackedPropertyKeys.indexOf(prop) is -1
        @thang[prop] = @thang.unusedTrackedPropertyValues[propIndex]
      props = []
      for prop, propIndex in @trackedPropertyKeys
        type = @trackedPropertyTypes[propIndex]
        storage = @trackedPropertyValues[propIndex]
        props.push @thang[prop] = @getStoredProp propIndex, type, storage
        #console.log @frameIndex, @thang.id, prop, propIndex, type, storage, 'got', @thang[prop]
      @props = props
      @trackedPropertyTypes = @trackedPropertyValues = @specialKeysToValues = null  # leave @trackedPropertyKeys for indexing
      @hasRestored = true
    else  # Restoring later times
      for prop, propIndex in @thang.unusedTrackedPropertyKeys when @trackedPropertyKeys.indexOf(prop) is -1
        @thang[prop] = @thang.unusedTrackedPropertyValues[propIndex]
      for prop, propIndex in @trackedPropertyKeys
        @thang[prop] = @props[propIndex]
    @thang.partialState = false
    @thang.stateChanged = true
    @

  restorePartial: (ratio) ->
    # Don't think we need to worry about unusedTrackedPropertyValues here.
    # If it's not tracked yet, it'll very rarely partially change between frames; we can afford to miss the first one.
    inverse = 1 - ratio
    for prop, propIndex in @trackedPropertyKeys when prop is 'pos' or prop is 'rotation'
      if @hasRestored
        value = @props[propIndex]
      else
        type = @trackedPropertyTypes[propIndex]
        storage = @trackedPropertyValues[propIndex]
        value = @getStoredProp propIndex, type, storage
      if prop is 'pos'
        if (@thang.teleport and @thang.pos.distanceSquared(value) > 900) or (@thang.pos.x is 0 and @thang.pos.y is 0)
          # Don't interpolate; it was probably a teleport. https://github.com/codecombat/codecombat/issues/738
          @thang.pos = value
        else
          @thang.pos = @thang.pos.copy()
          @thang.pos.x = inverse * @thang.pos.x + ratio * value.x
          @thang.pos.y = inverse * @thang.pos.y + ratio * value.y
          @thang.pos.z = inverse * @thang.pos.z + ratio * value.z
      else if prop is 'rotation'
        @thang.rotation = inverse * @thang.rotation + ratio * value
      @thang.partialState = true
    @thang.stateChanged = true
    @

  serialize: (frameIndex, trackedPropertyIndices, trackedPropertyTypes, trackedPropertyValues, specialValuesToKeys, specialKeysToValues) ->
    # Performance hotspot--called once per tracked property per Thang per frame. Optimize the crap out of it.
    for type, newPropIndex in trackedPropertyTypes
      originalPropIndex = trackedPropertyIndices[newPropIndex]
      storage = trackedPropertyValues[newPropIndex]
      value = @props[originalPropIndex]
      if value
        # undefined, null, false, 0 won't trigger in this serialization code scheme anyway, so we can't differentiate between them when deserializing
        if type is 'Vector'
          storage[3 * frameIndex] = value.x
          storage[3 * frameIndex + 1] = value.y
          storage[3 * frameIndex + 2] = value.z
        else if type is 'string'
          specialKey = specialValuesToKeys[value]
          unless specialKey
            specialKey = specialKeysToValues.length
            specialValuesToKeys[value] = specialKey
            specialKeysToValues.push value
            storage[frameIndex] = specialKey
          storage[frameIndex] = specialKey
        else if type is 'Thang'
          value = value.id
          specialKey = specialValuesToKeys[value]
          unless specialKey
            specialKey = specialKeysToValues.length
            specialValuesToKeys[value] = specialKey
            specialKeysToValues.push value
            storage[frameIndex] = specialKey
          storage[frameIndex] = specialKey
        else if type is 'array'
          # We make sure the array keys won't collide with any string keys by using some unprintable characters.
          stringPieces = ['\x1D']  # Group Separator
          for element in value
            if element and element.id  # Was checking element.isThang, but we can't store non-strings anyway
              element = element.id
            stringPieces.push element, '\x1E'  # Record Separator(s)
          value = stringPieces.join('')
          specialKey = specialValuesToKeys[value]
          unless specialKey
            specialKey = specialKeysToValues.length
            specialValuesToKeys[value] = specialKey
            specialKeysToValues.push value
            storage[frameIndex] = specialKey
          storage[frameIndex] = specialKey
        else
          storage[frameIndex] = value
        #console.log @thang.id, 'assigned prop', originalPropIndex, newPropIndex, value, type, 'at', frameIndex, 'to', storage[frameIndex]
    null

  @deserialize: (world, frameIndex, thang, trackedPropertyKeys, trackedPropertyTypes, trackedPropertyValues, specialKeysToValues) ->
    # Optimize like no tomorrow--most performance-sensitive part of the whole app, called once per WorldFrame per Thang per trackedProperty, blocking the UI
    ts = new ThangState
    ts.thang = thang
    ts.frameIndex = frameIndex
    ts.trackedPropertyKeys = trackedPropertyKeys
    ts.trackedPropertyTypes = trackedPropertyTypes
    ts.trackedPropertyValues = trackedPropertyValues
    ts.specialKeysToValues = specialKeysToValues
    ts

  @transferableBytesNeededForType: (type, nFrames) ->
    bytes = switch type
      when 'boolean' then 1
      when 'number' then bytesPerFloat
      when 'Vector' then bytesPerFloat * 3
      when 'string' then 4
      when 'Thang' then 4  # turn them into strings of their ids
      when 'array'  then 4  # turn them into strings and hope it doesn't explode?
      else 0
    # We need to be a multiple of bytesPerFloat otherwise bigger-byte array (Float64Array, etc.) offsets won't work
    # http://www.kirupa.com/forum/showthread.php?378737-Typed-Arrays-Y-U-No-offset-at-values-other-than-multiples-of-element-size
    bytesPerFloat * Math.ceil(nFrames * bytes / bytesPerFloat)

  @createArrayForType: (type, nFrames, buffer, offset) ->
    bytes = @transferableBytesNeededForType type, nFrames
    storage = switch type
      when 'boolean'
        new Uint8Array(buffer, offset, nFrames)
      when 'number'
        new FloatArrayType(buffer, offset, nFrames)
      when 'Vector'
        new FloatArrayType(buffer, offset, nFrames * 3)
      when 'string'
        new Uint32Array(buffer, offset, nFrames)
      when 'Thang'
        new Uint32Array(buffer, offset, nFrames)
      when 'array'
        new Uint32Array(buffer, offset, nFrames)
      else
        []
    [storage, bytes]

unless typedArraySupport
  # Fall back to normal arrays in IE 9
  ThangState.createArrayForType = (type, nFrames, buffer, offset) ->
    bytes = @transferableBytesNeededForType type, nFrames
    elementsPerFrame = if type is 'Vector' then 3 else 1
    storage = (0 for i in [0 ... nFrames * elementsPerFrame])
    [storage, bytes]
