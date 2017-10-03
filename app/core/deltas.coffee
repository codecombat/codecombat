SystemNameLoader = require './../core/SystemNameLoader'
if typeof window is 'undefined'
  # Just load the normal NPM library on the server side
  jsondiffpatch = require('jsondiffpatch')
else
  # Client needs an extra formatting plugin and CSS
  jsondiffpatch = require('lib/jsondiffpatch')

###
  Good-to-knows:
    dataPath: an array of keys that walks you up a JSON object that's being patched
      ex: ['scripts', 0, 'description']
    deltaPath: an array of keys that walks you up a JSON Diff Patch object.
      ex: ['scripts', '_0', 'description']
###

module.exports.expandDelta = (delta, left, schema) ->
  if left?
    right = jsondiffpatch.clone(left)
    jsondiffpatch.patch right, delta

  flattenedDeltas = flattenDelta(delta)
  (expandFlattenedDelta(fd, left, right, schema) for fd in flattenedDeltas)

module.exports.flattenDelta = flattenDelta = (delta, dataPath=null, deltaPath=null) ->
  # takes a single jsondiffpatch delta and returns an array of objects with
  return [] unless delta
  dataPath ?= []
  deltaPath ?= []
  return [{dataPath: dataPath, deltaPath: deltaPath, o: delta}] if _.isArray delta

  results = []
  affectingArray = delta._t is 'a'
  for deltaIndex, childDelta of delta
    continue if deltaIndex is '_t'
    dataIndex = if affectingArray then parseInt(deltaIndex.replace('_', '')) else deltaIndex
    results = results.concat flattenDelta(
      childDelta, dataPath.concat([dataIndex]), deltaPath.concat([deltaIndex]))
  results

expandFlattenedDelta = (delta, left, right, schema) ->
  # takes a single flattened delta and converts into an object that can be
  # easily formatted into something human readable.

  delta.action = '???'
  o = delta.o # the raw jsondiffpatch delta

  humanPath = []
  parentLeft = left
  parentRight = right
  parentSchema = schema
  for key, i in delta.dataPath
    # TODO: Better schema/json walking
    childSchema = parentSchema?.items or parentSchema?.properties?[key] or {}
    childLeft = parentLeft?[key]
    childRight = parentRight?[key]
    humanKey = null
    humanKey ?= childRight.name or childRight.id if childRight
    humanKey ?= SystemNameLoader.getName(childRight?.original)
    humanKey ?= "#{childSchema.title}" if childSchema.title
    humanKey ?= _.string.titleize key
    humanPath.push humanKey
    parentLeft = childLeft
    parentRight = childRight
    parentSchema = childSchema

  if not childLeft and childRight
    childLeft = jsondiffpatch.patch(childRight, jsondiffpatch.reverse(o))

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
    delta.hash = objectHash childRight

  if _.isArray(o) and o.length is 3 and o[1] is 0 and o[2] is 2
    delta.action = 'text-diff'
    delta.unidiff = o[0]

  delta.humanPath = humanPath.join(' :: ')
  delta.schema = childSchema
  delta.left = childLeft
  delta.right = childRight

  delta

objectHash = (obj) -> if obj? then (obj.name or obj.id or obj._id or JSON.stringify(_.keys(obj).sort())) else 'null'


module.exports.makeJSONDiffer = ->
  jsondiffpatch.create({objectHash})

module.exports.getConflicts = (headDeltas, pendingDeltas) ->
  # headDeltas and pendingDeltas should be lists of deltas returned by expandDelta
  # Returns a list of conflict objects with properties:
  #   headDelta
  #   pendingDelta
  # The deltas that have conflicts also have conflict properties pointing to one another.

  headPathMap = groupDeltasByAffectingPaths(headDeltas)
  pendingPathMap = groupDeltasByAffectingPaths(pendingDeltas)
  paths = _.keys(headPathMap).concat(_.keys(pendingPathMap))

  # Here's my thinking: conflicts happen when one delta path is a substring of another delta path
  # So, sort paths from both deltas together, which will naturally make conflicts adjacent,
  # and if one is identified AND one path is from the headDeltas AND the other is from pendingDeltas
  # This is all to avoid an O(nm) brute force search.

  conflicts = []
  paths.sort()
  for path, i in paths
    offset = 1
    while i + offset < paths.length
      # Look at the neighbor
      nextPath = paths[i+offset]
      offset += 1

      # these stop being substrings of each other? Then conflict DNE
      if not (_.string.startsWith nextPath, path) then break

      # check if these two are from the same group, but we still need to check for more beyond
      unless headPathMap[path] or headPathMap[nextPath] then continue
      unless pendingPathMap[path] or pendingPathMap[nextPath] then continue

      # Okay, we found two deltas from different groups which conflict
      for headMetaDelta in (headPathMap[path] or headPathMap[nextPath])
        headDelta = headMetaDelta.delta
        for pendingMetaDelta in (pendingPathMap[path] or pendingPathMap[nextPath])
          pendingDelta = pendingMetaDelta.delta
          conflicts.push({headDelta: headDelta, pendingDelta: pendingDelta})
          pendingDelta.conflict = headDelta
          headDelta.conflict = pendingDelta

  return conflicts if conflicts.length

groupDeltasByAffectingPaths = (deltas) ->
  metaDeltas = []
  for delta in deltas
    conflictPaths = []
    # We're being fairly liberal with what's a conflict, because the alternative is worse
    if delta.action is 'moved-index'
      # If you moved items around in an array, mark the whole array as a gonner
      conflictPaths.push delta.dataPath.slice(0, delta.dataPath.length-1)
    else if delta.action in ['deleted', 'added'] and _.isNumber(delta.dataPath[delta.dataPath.length-1])
      # If you remove or add items in an array, mark the whole thing as a gonner
      conflictPaths.push delta.dataPath.slice(0, delta.dataPath.length-1)
    else
      conflictPaths.push delta.dataPath
    for path in conflictPaths
      metaDeltas.push {
        delta: delta
        path: (item.toString() for item in path).join('/')
      }

  map = _.groupBy metaDeltas, 'path'
  return map

module.exports.pruneConflictsFromDelta = (delta, conflicts) ->
  expandedDeltas = (conflict.pendingDelta for conflict in conflicts)
  module.exports.pruneExpandedDeltasFromDelta delta, expandedDeltas

module.exports.pruneExpandedDeltasFromDelta = (delta, expandedDeltas) ->
  # the jsondiffpatch delta mustn't include any dangling nodes,
  # or else things will get removed which shouldn't be, or errors will occur
  for expandedDelta in expandedDeltas
    prunePath delta, expandedDelta.deltaPath
  if _.isEmpty delta then undefined else delta

prunePath = (delta, path) ->
  if path.length is 1
    delete delta[path] unless delta[path] is undefined
  else
    prunePath delta[path[0]], path.slice(1) unless delta[path[0]] is undefined
    keys = (k for k in _.keys(delta[path[0]]) when k isnt '_t')
    delete delta[path[0]] if keys.length is 0

module.exports.DOC_SKIP_PATHS = [
  '_id','version', 'commitMessage', 'parent', 'created',
  'slug', 'index', '__v', 'patches', 'creator', 'js', 'watchers', 'levelsUpdated'
]
