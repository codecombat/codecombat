# path: an array of indexes to navigate into a JSON object
# left: 

module.exports.interpretDelta = (delta, path, left, schema) ->
  # takes a single delta and converts into an object that can be
  # easily formatted into something human readable.

  betterDelta = { action:'???', delta: delta }

  betterPath = []
  parentLeft = left
  parentSchema = schema
  for key in path
    # TODO: A smarter way of getting child schemas
    childSchema = parentSchema?.items or parentSchema?.properties?[key] or {}
    childLeft = parentLeft?[key]
    betterKey = null
    betterKey ?= childLeft.name or childLeft.id if childLeft
    betterKey ?= "#{childSchema.title} ##{key+1}" if childSchema.title and _.isNumber(key)
    betterKey ?= "#{childSchema.title}" if childSchema.title
    betterKey ?= _.string.titleize key
    betterPath.push betterKey
    parentLeft = childLeft
    parentSchema = childSchema
    
  betterDelta.path = betterPath.join(' :: ')
  betterDelta.schema = childSchema
  betterDelta.left = childLeft
  betterDelta.right = jsondiffpatch.patch childLeft, delta
  
  if _.isArray(delta) and delta.length is 1
    betterDelta.action = 'added'
    betterDelta.newValue = delta[0]

  if _.isArray(delta) and delta.length is 2
    betterDelta.action = 'modified'
    betterDelta.oldValue = delta[0]
    betterDelta.newValue = delta[1]

  if _.isArray(delta) and delta.length is 3 and delta[1] is 0 and delta[2] is 0
    betterDelta.action = 'deleted'
    betterDelta.oldValue = delta[0]

  if _.isPlainObject(delta) and delta._t is 'a'
    betterDelta.action = 'modified-array'

  if _.isPlainObject(delta) and delta._t isnt 'a'
    betterDelta.action = 'modified-object'

  if _.isArray(delta) and delta.length is 3 and delta[1] is 0 and delta[2] is 3
    betterDelta.action = 'moved-index'
    betterDelta.destinationIndex = delta[1]

  if _.isArray(delta) and delta.length is 3 and delta[1] is 0 and delta[2] is 2
    betterDelta.action = 'text-diff'
    betterDelta.unidiff = delta[0]
    left = betterDelta.left.trim().split('\n')
    right = betterDelta.right.trim().split('\n')
    shifted = popped = false
    while left.length > 5 and right.length > 5 and left[0] is right[0] and left[1] is right[1]
      left.shift()
      right.shift()
      shifted = true
    while left.length > 5 and right.length > 5 and left[left.length-1] is right[right.length-1] and left[left.length-2] is right[right.length-2]
      left.pop()
      right.pop()
      popped = true
    left.push('...') and right.push('...') if popped
    left.unshift('...') and right.unshift('...') if shifted
    betterDelta.trimmedLeft = left.join('\n')
    betterDelta.trimmedRight = right.join('\n')


  betterDelta
  
module.exports.flattenDelta = flattenDelta = (delta, path=null) ->
  # takes a single delta and returns an array of deltas
  
  path ?= []
  
  return [{path:path, delta:delta}] if _.isArray delta
  
  results = []
  affectingArray = delta._t is 'a'
  for index, childDelta of delta
    continue if index is '_t'
    index = parseInt(index.replace('_', '')) if affectingArray
    results = results.concat flattenDelta(childDelta, path.concat([index]))
  results 