# path: an array of indexes to navigate into a JSON object
# left: 

module.exports.interpretDelta = (delta, path, left, schema) ->
  # takes a single delta and converts into an object that can be
  # easily formatted into something human readable.

  betterDelta = { action:'???', delta: delta }

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

  betterPath = []
  parentLeft = left
  parentSchema = schema
  for key, i in path
    # TODO: A smarter way of getting child schemas
    childSchema = parentSchema?.items or parentSchema?.properties?[key] or {}
    childLeft = parentLeft?[key]
    betterKey = null
    childData = if i is path.length-1 and betterDelta.action is 'added' then delta[0] else childLeft
    betterKey ?= childData.name or childData.id if childData
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
  
  betterDelta
  
module.exports.flattenDelta = flattenDelta = (delta, path=null) ->
  # takes a single delta and returns an array of deltas
  return [] unless delta
  
  path ?= []
  
  return [{path:path, delta:delta}] if _.isArray delta
  
  results = []
  affectingArray = delta._t is 'a'
  for index, childDelta of delta
    continue if index is '_t'
    index = parseInt(index.replace('_', '')) if affectingArray
    results = results.concat flattenDelta(childDelta, path.concat([index]))
  results 