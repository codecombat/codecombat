SystemNameLoader = require 'lib/SystemNameLoader'
### 
  Good-to-knows:
    dataPath: an array of keys that walks you up a JSON object that's being patched
      ex: ['scripts', 0, 'description']
    deltaPath: an array of keys that walks you up a JSON Diff Patch object.
      ex: ['scripts', '_0', 'description']
###
  
module.exports.expandDelta = (delta, left, schema) ->
  flattenedDeltas = flattenDelta(delta)
  (expandFlattenedDelta(fd, left, schema) for fd in flattenedDeltas)
  

flattenDelta = (delta, dataPath=null, deltaPath=null) ->
  # takes a single jsondiffpatch delta and returns an array of objects with
  return [] unless delta
  dataPath ?= []
  deltaPath ?= []
  return [{dataPath:dataPath, deltaPath: deltaPath, o:delta}] if _.isArray delta

  results = []
  affectingArray = delta._t is 'a'
  for deltaIndex, childDelta of delta
    continue if deltaIndex is '_t'
    dataIndex = if affectingArray then parseInt(deltaIndex.replace('_', '')) else deltaIndex
    results = results.concat flattenDelta(
      childDelta, dataPath.concat([dataIndex]), deltaPath.concat([deltaIndex]))
  results
  

expandFlattenedDelta = (delta, left, schema) ->
  # takes a single flattened delta and converts into an object that can be
  # easily formatted into something human readable.
  
  delta.action = '???'
  o = delta.o # the raw jsondiffpatch delta

  if _.isArray(o) and o.length is 1
    delta.action = 'added'
    delta.newValue = o[0]

  if _.isArray(o) and o.length is 2
    delta.action = 'modified'
    delta.oldValue = o[0]
    delta.newValue = o[1]

  if _.isArray(o) and o.length is 3 and o[1] is 0 and o[2] is 0
    delta.action = 'deleted'
    delta.oldValue = o[0]

  if _.isPlainObject(o) and o._t is 'a'
    delta.action = 'modified-array'

  if _.isPlainObject(o) and o._t isnt 'a'
    delta.action = 'modified-object'

  if _.isArray(o) and o.length is 3 and o[2] is 3
    delta.action = 'moved-index'
    delta.destinationIndex = o[1]
    delta.originalIndex = delta.dataPath[delta.dataPath.length-1]

  if _.isArray(o) and o.length is 3 and o[1] is 0 and o[2] is 2
    delta.action = 'text-diff'
    delta.unidiff = o[0]

  humanPath = []
  parentLeft = left
  parentSchema = schema
  for key, i in delta.dataPath
    # TODO: Better schema/json walking
    childSchema = parentSchema?.items or parentSchema?.properties?[key] or {}
    childLeft = parentLeft?[key]
    humanKey = null
    childData = if i is delta.dataPath.length-1 and delta.action is 'added' then o[0] else childLeft
    humanKey ?= childData.name or childData.id if childData
    humanKey ?= SystemNameLoader.getName(childData?.original)
    humanKey ?= "#{childSchema.title}" if childSchema.title
    humanKey ?= _.string.titleize key
    humanPath.push humanKey
    parentLeft = childLeft
    parentSchema = childSchema
    
  delta.humanPath = humanPath.join(' :: ')
  delta.schema = childSchema
  delta.left = childLeft
  delta.right = jsondiffpatch.patch childLeft, delta.o unless delta.action is 'moved-index'
  
  delta
  
module.exports.makeJSONDiffer = ->
  hasher = (obj) -> obj.name || obj.id || obj._id || JSON.stringify(_.keys(obj))
  jsondiffpatch.create({objectHash:hasher})
    
module.exports.getConflicts = (headDeltas, pendingDeltas) ->
  # headDeltas and pendingDeltas should be lists of deltas returned by interpretDelta
  # Returns a list of conflict objects with properties:
  #   headDelta
  #   pendingDelta
  # The deltas that have conflicts also have conflict properties pointing to one another.
  
  headPathMap = groupDeltasByAffectingPaths(headDeltas)
  pendingPathMap = groupDeltasByAffectingPaths(pendingDeltas)
  paths = _.keys(headPathMap).concat(_.keys(pendingPathMap))
  
  # Here's my thinking:
  # A) Conflicts happen when one delta path is a substring of another delta path
  # B) A delta from one self-consistent group cannot conflict with another
  # So, sort the paths, which will naturally make conflicts adjacent,
  # and if one is identified, one path is from the headDeltas, the other is from pendingDeltas
  # This is all to avoid an O(nm) brute force search.
  
  conflicts = []
  paths.sort()
  for path, i in paths
    continue if i + 1 is paths.length
    nextPath = paths[i+1]
    if nextPath.startsWith path
      headDelta = (headPathMap[path] or headPathMap[nextPath])[0].delta
      pendingDelta = (pendingPathMap[path] or pendingPathMap[nextPath])[0].delta
      conflicts.push({headDelta:headDelta, pendingDelta:pendingDelta})
      pendingDelta.conflict = headDelta
      headDelta.conflict = pendingDelta

  return conflicts if conflicts.length
  
groupDeltasByAffectingPaths = (deltas) ->
  metaDeltas = []
  for delta in deltas
    conflictPaths = []
    if delta.action is 'moved-index'
      # every other action affects just the data path, but moved indexes affect a swath
      indices = [delta.originalIndex, delta.destinationIndex]
      indices.sort()
      for index in _.range(indices[0], indices[1]+1)
        conflictPaths.push delta.dataPath.slice(0, delta.dataPath.length-1).concat(index)
    else
      conflictPaths.push delta.dataPath
    for path in conflictPaths
      metaDeltas.push {
        delta: delta
        path: (item.toString() for item in path).join('/')
      }
  _.groupBy metaDeltas, 'path' 
  
module.exports.pruneConflictsFromDelta = (delta, conflicts) ->
  # the jsondiffpatch delta mustn't include any dangling nodes,
  # or else things will get removed which shouldn't be, or errors will occur
  for conflict in conflicts
    prunePath delta, conflict.pendingDelta.deltaPath
  if _.isEmpty delta then undefined else delta
    
prunePath = (delta, path) ->
  if path.length is 1
    delete delta[path]
  else
    prunePath delta[path[0]], path.slice(1)
    keys = (k for k in _.keys(delta[path[0]]) when k isnt '_t')
    delete delta[path[0]] if keys.length is 0
