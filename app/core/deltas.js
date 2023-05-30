// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let jsondiffpatch;
import SystemNameLoader from './../core/SystemNameLoader';
if (typeof window === 'undefined') {
  // Just load the normal NPM library on the server side
  jsondiffpatch = require('jsondiffpatch');
} else {
  // Client needs an extra formatting plugin and CSS
  jsondiffpatch = require('lib/jsondiffpatch');
}

/*
  Good-to-knows:
    dataPath: an array of keys that walks you up a JSON object that's being patched
      ex: ['scripts', 0, 'description']
    deltaPath: an array of keys that walks you up a JSON Diff Patch object.
      ex: ['scripts', '_0', 'description']
*/

export const expandDelta = function(delta, left, schema) {
  let right;
  if (left != null) {
    right = jsondiffpatch.clone(left);
    jsondiffpatch.patch(right, delta);
  }

  const flattenedDeltas = flattenDelta(delta);
  return (Array.from(flattenedDeltas).map((fd) => expandFlattenedDelta(fd, left, right, schema)));
};

export const flattenDelta = function(delta, dataPath=null, deltaPath=null) {
  // takes a single jsondiffpatch delta and returns an array of objects with
  if (!delta) { return []; }
  if (dataPath == null) { dataPath = []; }
  if (deltaPath == null) { deltaPath = []; }
  if (_.isArray(delta)) { return [{dataPath, deltaPath, o: delta}]; }

  let results = [];
  const affectingArray = delta._t === 'a';
  for (var deltaIndex in delta) {
    var childDelta = delta[deltaIndex];
    if (deltaIndex === '_t') { continue; }
    var dataIndex = affectingArray ? parseInt(deltaIndex.replace('_', '')) : deltaIndex;
    results = results.concat(flattenDelta(
      childDelta, dataPath.concat([dataIndex]), deltaPath.concat([deltaIndex]))
    );
  }
  return results;
};

var expandFlattenedDelta = function(delta, left, right, schema) {
  // takes a single flattened delta and converts into an object that can be
  // easily formatted into something human readable.

  let childLeft, childRight, childSchema;
  delta.action = '???';
  const {
    o
  } = delta; // the raw jsondiffpatch delta

  const humanPath = [];
  let parentLeft = left;
  let parentRight = right;
  let parentSchema = schema;
  for (let i = 0; i < delta.dataPath.length; i++) {
    // TODO: Better schema/json walking
    var key = delta.dataPath[i];
    childSchema = (parentSchema != null ? parentSchema.items : undefined) || __guard__(parentSchema != null ? parentSchema.properties : undefined, x => x[key]) || {};
    childLeft = parentLeft != null ? parentLeft[key] : undefined;
    childRight = parentRight != null ? parentRight[key] : undefined;
    var humanKey = null;
    if (childRight) { if (humanKey == null) { humanKey = childRight.name || childRight.id; } }
    if (humanKey == null) { humanKey = SystemNameLoader.getName(childRight != null ? childRight.original : undefined); }
    if (childSchema.title) { if (humanKey == null) { humanKey = `${childSchema.title}`; } }
    if (humanKey == null) { humanKey = _.string.titleize(key); }
    humanPath.push(humanKey);
    parentLeft = childLeft;
    parentRight = childRight;
    parentSchema = childSchema;
  }

  if (!childLeft && childRight) {
    childLeft = jsondiffpatch.patch(childRight, jsondiffpatch.reverse(o));
  }

  if (_.isArray(o) && (o.length === 1)) {
    delta.action = 'added';
    delta.newValue = o[0];
  }

  if (_.isArray(o) && (o.length === 2)) {
    delta.action = 'modified';
    delta.oldValue = o[0];
    delta.newValue = o[1];
  }

  if (_.isArray(o) && (o.length === 3) && (o[1] === 0) && (o[2] === 0)) {
    delta.action = 'deleted';
    delta.oldValue = o[0];
  }

  if (_.isPlainObject(o) && (o._t === 'a')) {
    delta.action = 'modified-array';
  }

  if (_.isPlainObject(o) && (o._t !== 'a')) {
    delta.action = 'modified-object';
  }

  if (_.isArray(o) && (o.length === 3) && (o[2] === 3)) {
    delta.action = 'moved-index';
    delta.destinationIndex = o[1];
    delta.originalIndex = delta.dataPath[delta.dataPath.length-1];
    delta.hash = objectHash(childRight);
  }

  if (_.isArray(o) && (o.length === 3) && (o[1] === 0) && (o[2] === 2)) {
    delta.action = 'text-diff';
    delta.unidiff = o[0];
  }

  delta.humanPath = humanPath.join(' :: ');
  delta.schema = childSchema;
  delta.left = childLeft;
  delta.right = childRight;

  return delta;
};

var objectHash = function(obj) { if (obj != null) { return (obj.name || obj.id || obj._id || JSON.stringify(_.keys(obj).sort())); } else { return 'null'; } };


export const makeJSONDiffer = () => jsondiffpatch.create({objectHash});

export const getConflicts = function(headDeltas, pendingDeltas) {
  // headDeltas and pendingDeltas should be lists of deltas returned by expandDelta
  // Returns a list of conflict objects with properties:
  //   headDelta
  //   pendingDelta
  // The deltas that have conflicts also have conflict properties pointing to one another.

  const headPathMap = groupDeltasByAffectingPaths(headDeltas);
  const pendingPathMap = groupDeltasByAffectingPaths(pendingDeltas);
  const paths = _.keys(headPathMap).concat(_.keys(pendingPathMap));

  // Here's my thinking: conflicts happen when one delta path is a substring of another delta path
  // So, sort paths from both deltas together, which will naturally make conflicts adjacent,
  // and if one is identified AND one path is from the headDeltas AND the other is from pendingDeltas
  // This is all to avoid an O(nm) brute force search.

  const conflicts = [];
  paths.sort();
  for (let i = 0; i < paths.length; i++) {
    var path = paths[i];
    var offset = 1;
    while ((i + offset) < paths.length) {
      // Look at the neighbor
      var nextPath = paths[i+offset];
      offset += 1;

      // these stop being substrings of each other? Then conflict DNE
      if (!(_.string.startsWith(nextPath, path))) { break; }

      // check if these two are from the same group, but we still need to check for more beyond
      if (!headPathMap[path] && !headPathMap[nextPath]) { continue; }
      if (!pendingPathMap[path] && !pendingPathMap[nextPath]) { continue; }

      // Okay, we found two deltas from different groups which conflict
      for (var headMetaDelta of Array.from((headPathMap[path] || headPathMap[nextPath]))) {
        var headDelta = headMetaDelta.delta;
        for (var pendingMetaDelta of Array.from((pendingPathMap[path] || pendingPathMap[nextPath]))) {
          var pendingDelta = pendingMetaDelta.delta;
          conflicts.push({headDelta, pendingDelta});
          pendingDelta.conflict = headDelta;
          headDelta.conflict = pendingDelta;
        }
      }
    }
  }

  if (conflicts.length) { return conflicts; }
};

var groupDeltasByAffectingPaths = function(deltas) {
  const metaDeltas = [];
  for (var delta of Array.from(deltas)) {
    var conflictPaths = [];
    // We're being fairly liberal with what's a conflict, because the alternative is worse
    if (delta.action === 'moved-index') {
      // If you moved items around in an array, mark the whole array as a gonner
      conflictPaths.push(delta.dataPath.slice(0, delta.dataPath.length-1));
    } else if (['deleted', 'added'].includes(delta.action) && _.isNumber(delta.dataPath[delta.dataPath.length-1])) {
      // If you remove or add items in an array, mark the whole thing as a gonner
      conflictPaths.push(delta.dataPath.slice(0, delta.dataPath.length-1));
    } else {
      conflictPaths.push(delta.dataPath);
    }
    for (var path of Array.from(conflictPaths)) {
      metaDeltas.push({
        delta,
        path: (Array.from(path).map((item) => item.toString())).join('/')
      });
    }
  }

  const map = _.groupBy(metaDeltas, 'path');
  return map;
};

export const pruneConflictsFromDelta = function(delta, conflicts) {
  const expandedDeltas = (Array.from(conflicts).map((conflict) => conflict.pendingDelta));
  return pruneExpandedDeltasFromDelta(delta, expandedDeltas);
};

export const pruneExpandedDeltasFromDelta = function(delta, expandedDeltas) {
  // the jsondiffpatch delta mustn't include any dangling nodes,
  // or else things will get removed which shouldn't be, or errors will occur
  for (var expandedDelta of Array.from(expandedDeltas)) {
    prunePath(delta, expandedDelta.deltaPath);
  }
  if (_.isEmpty(delta)) { return undefined; } else { return delta; }
};

var prunePath = function(delta, path) {
  if (path.length === 1) {
    if (delta[path] !== undefined) { return delete delta[path]; }
  } else {
    if (delta[path[0]] !== undefined) { prunePath(delta[path[0]], path.slice(1)); }
    const keys = (Array.from(_.keys(delta[path[0]])).filter((k) => k !== '_t'));
    if (keys.length === 0) { return delete delta[path[0]]; }
  }
};

export const DOC_SKIP_PATHS = [
  '_id','version', 'commitMessage', 'parent', 'created',
  'slug', 'index', '__v', 'patches', 'creator', 'js', 'watchers', 'levelsUpdated', '_algoliaObjectID'
];

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
