// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS201: Simplify complex destructure assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SpriteOptimizer;
const utils = require('core/utils');

module.exports = (SpriteOptimizer = (function() {
  SpriteOptimizer = class SpriteOptimizer {
    static initClass() {
      this.prototype.debug = false;
    }

    constructor(thangTypeModel, options) {
      this.thangTypeModel = thangTypeModel;
      if (options == null) { options = {}; }
      this.aggressiveShapes = options.aggressiveShapes;
      this.aggressiveContainers = options.aggressiveContainers;
      if (this.debug) { console.log('Optimizing with aggressiveShapes:', this.aggressiveShapes, 'and containers', this.aggressiveContainers); }
      this.raw = $.extend(true, {}, this.thangTypeModel.attributes.raw);
      if (this.raw.shapes == null) { this.raw.shapes = {}; }
      if (this.raw.containers == null) { this.raw.containers = {}; }
      if (this.raw.animations == null) { this.raw.animations = {}; }
      this.colorGroups = $.extend(true, {}, this.thangTypeModel.attributes.colorGroups);
      this.actions = $.extend(true, {}, this.thangTypeModel.attributes.actions);
    }

    optimize() {
      if (this.debug) {
        console.log('Got shapes to optimize:', this.raw.shapes, JSON.stringify(this.raw.shapes, null, 0).length, "chars", _.size(this.raw.shapes), "shapes");
        console.log('Got containers to optimize:', this.raw.containers, JSON.stringify(this.raw.containers, null, 0).length, "chars", _.size(this.raw.containers), "containers");
        console.log('Got animations to optimize:', this.raw.animations, JSON.stringify(this.raw.animations, null, 0).length, "chars", _.size(this.raw.animations), "animations");
        if (_.size(this.colorGroups)) {
          console.log('Got colors to optimize:', this.colorGroups, JSON.stringify(this.colorGroups, null, 0).length, "chars", _.flatten(_.values(this.colorGroups)).length, "colored shapes");
        }
        console.log("Total:", JSON.stringify(this.raw, null, 0).length, "chars");
      }

      for (let round = 1; round <= 3; round++) {
        // Hacky hack: certain optimizations work better after others, so we run once for basic pass, 2nd time to finish deduping containers that now realize they're referencing duplicate shapes, and 3rd time to get the most frequent unique shape/container names shorter. Better coding could make this require fewer passes, but it runs pretty fast anyway.
        this.optimizeShapes();

        if (this.debug) {
          console.log(`Renamed/deduplicated shapes, round ${round}:`, this.raw.shapes, JSON.stringify(this.raw.shapes, null, 0).length, "chars", _.size(this.raw.shapes), "shapes");
          console.log(`Renamed/deduplicated containers, round ${round}:`, this.raw.containers, JSON.stringify(this.raw.containers, null, 0).length, "chars", _.size(this.raw.containers), "containers");
          console.log("Total:", JSON.stringify(this.raw, null, 0).length, "chars");
        }

        if (round === 1) {
          this.cullUnused();

          if (this.debug) {
            console.log(`Culled shapes, round ${round}:`, this.raw.shapes, JSON.stringify(this.raw.shapes, null, 0).length, "chars", _.size(this.raw.shapes), "shapes");
            console.log(`Culled containers, round ${round}:`, this.raw.containers, JSON.stringify(this.raw.containers, null, 0).length, "chars", _.size(this.raw.containers), "containers");
            console.log(`Culled animations, round ${round}:`, this.raw.animations, JSON.stringify(this.raw.animations, null, 0).length, "chars", _.size(this.raw.animations), "animations");
            if (_.size(this.colorGroups)) {
              console.log(`Culled colors, round ${round}:`, this.colorGroups, JSON.stringify(this.colorGroups, null, 0).length, "chars", _.flatten(_.values(this.colorGroups)).length, "colored shapes");
            }
            console.log("Total:", JSON.stringify(this.raw, null, 0).length, "chars");
          }
        }
      }

      this.sortBySize();

      return this.saveToModel();
    }

    saveToModel() {
      this.thangTypeModel.set('raw', this.raw);
      this.thangTypeModel.set('actions', this.actions);
      if (utils.isOzaria && _.size(this.colorGroups)) {
        return this.thangTypeModel.set('colorGroups', this.colorGroups);
      }
    }

    keyForShape(shape) {
      if (this.aggressiveShapes) { shape = _.omit(shape, 't'); }  // Sometimes transform doesn't matter as far as unique shapes go (ex.: Hero A Cinematic), but sometimes it does (ex.: Hero B)
      return JSON.stringify(_.values(shape), null, 0);
    }

    keyForContainer(container) {
      container = _.cloneDeep(container);
      if (container.b) {
        for (let index = 0; index < container.b.length; index++) {
          // Containers can be pretty similar except for very small variations in floating point numbers, causing expensive duplicates.
          // Hack: round off to a few significant digits according to heuristics of how much we care for small/large values.
          // This algorithm is stupid but should work well enough to not bother with coming up with the Correct Solution.
          var num = container.b[index];
          container.b[index] = (num / 1000).toFixed(Math.min(3, Math.max(1, 5 - Math.log10(Math.abs(num)))));
        }
      }
          // for(var num of [-0.51, -0.49, -0.06, -0.03, 0.03, 0.06, 0.49, 0.51, 1.4, 1.5, 1.51, 14.9, 15.6, 99, 101, 101.1, 253.35235, 253.56363, 1098, 1101, 1110, 1111111111]) console.log(num, (num / 1000).toFixed(Math.min(3, Math.max(1, 5 - Math.log10(Math.abs(num))))), Math.log10(Math.abs(num)))
      return JSON.stringify(_.values(container), null, 0);
    }

    nameShape(n) {
      // Brittle with sortBySize
      //'s' + n  # If we want to sort shapes by size, their keys can't be integer-like
      return n + '';  // But we don't really care about sorting shapes by size
    }

    nameContainer(n) {
      // Brittle with sortBySize
      return 'c' + n;
    }

    optimizeShapes() {
      let action, animation, animationName, child, container, containerName, frequency, index, name, newContainerName, newShapeName, oldShapeName, relatedAction, relatedActionName, renamedTarget;
      let shape;
      const shapeRenamings = {};
      const containerRenamings = {};
      const shapeDuplicates = {};
      const containerDuplicates = {};

      // Rename shapes from 40-character hashes to simple numeric strings starting from 1, in order of usage frequency
      // Just look inside containers; raw.animations.shapes appears to always be empty, probably a legacy field.
      const shapeFrequencies = {};
      const object = this.raw.containers != null ? this.raw.containers : {};
      for (containerName in object) {
        container = object[containerName];
        for (child of Array.from(container.c != null ? container.c : [])) {
          if (child.gn) { continue; }  // It's actually a container, not a shape
          shapeFrequencies[child] = (shapeFrequencies[child] != null ? shapeFrequencies[child] : 0) + 1;
        }
      }
      const shapesByFrequency = _.sortBy(_.pairs(shapeFrequencies), function(...args) { let shapeName;
      let frequency; [shapeName, frequency] = Array.from(args[0]); return -frequency; });
      for ([shape, frequency] of Array.from(shapesByFrequency)) {
        var shapeKey = this.keyForShape(this.raw.shapes[shape]);
        if ((newShapeName = shapeDuplicates[shapeKey])) {
          shapeRenamings[shape] = newShapeName;  // This deduplicates identical shapes, keeping only the first
        } else {
          shapeDuplicates[shapeKey] = (shapeRenamings[shape] = this.nameShape(_.size(shapeRenamings)));
        }
      }

      if (this.debug) {
        console.log(shapesByFrequency);
        console.log(shapeRenamings);
      }

      const firstContainers = {};  // Just for debugging which containers we are rereferencing duplicates to

      // Now rename containers, which can be inside other containers or inside animations.
      // Containers can be referenced in more places inside animations and tweens, but let's not worry about frequency of use inside those; too complicated.
      const containerFrequencies = {};
      const object1 = this.raw.containers != null ? this.raw.containers : {};
      for (containerName in object1) {
        container = object1[containerName];
        for (child of Array.from(container.c != null ? container.c : [])) {
          if (child.gn) {  // It's actually a container, not a shape
            containerFrequencies[child.gn] = (containerFrequencies[child.gn] != null ? containerFrequencies[child.gn] : 0) + 1;
          }
        }
      }
      const object2 = this.raw.animations != null ? this.raw.animations : {};
      for (animationName in object2) {
        animation = object2[animationName];
        for (container of Array.from(animation.containers != null ? animation.containers : [])) {
          if (container.bn !== ('bn_' + container.gn + '_0')) {
            console.error('Unexpected bn/gn name relationship', container.bn, container.gn);
          }
          containerFrequencies[container.gn] = (containerFrequencies[container.gn] != null ? containerFrequencies[container.gn] : 0) + 1;
        }
      }
      for (name in this.actions) {
        action = this.actions[name];
        if (action.container) {
          containerFrequencies[action.container] = (containerFrequencies[action.container] != null ? containerFrequencies[action.container] : 0) + 1;
        }
        var object3 = action.relatedActions != null ? action.relatedActions : {};
        for (relatedActionName in object3) {
          relatedAction = object3[relatedActionName];
          if (relatedAction.container) {
            containerFrequencies[relatedAction.container] = (containerFrequencies[relatedAction.container] != null ? containerFrequencies[relatedAction.container] : 0) + 1;
          }
        }
      }
      const containersByFrequency = _.sortBy(_.pairs(containerFrequencies), function(...args) { let containerName, frequency; [containerName, frequency] = Array.from(args[0]); return -frequency; });
      for ([container, frequency] of Array.from(containersByFrequency)) {
        var containerKey = this.keyForContainer(this.raw.containers[container]);
        if (this.aggressiveContainers && (newContainerName = containerDuplicates[containerKey])) {
          // TODO: fix issue where the same animation might have multiple tweens targeting the same container (which breaks) if we consolidate identical containers. Exmaple: Hero A Cinematic eatPopcorn animation, with three tweens referencing what would be c0 (most common container, a hand used 13 times overall)
          // Until now, only do this in aggressive mode (currently: shift+click the reoptimize button)
          containerRenamings[container] = newContainerName;
          // This deduplicates identical containers, keeping only the first
          // It won't work right until we have also renamed the shapes within the containers, which is why we run multiple times. ;)
          if (this.debug && !_.isEqual(this.raw.containers[container], firstContainers[containerKey])) {
            console.log(container, _.cloneDeep(this.raw.containers[container]), 'is the same as', _.cloneDeep(firstContainers[containerKey]));
          }
        } else {
          containerDuplicates[containerKey] = (containerRenamings[container] = this.nameContainer(_.size(containerRenamings)));
          firstContainers[containerKey] = this.raw.containers[container];
        }
      }

      if (this.debug) {
        console.log(containersByFrequency);
        console.log(containerRenamings);
      }

      // Don't bother renaming animations, there aren't that many of them.
      // We also needn't bother deduping them, because we usually don't have that many duplicate animations, it's uncommon that we would configure an action to use two versions of the same animation, and it's just unfortunate if nested animations happen to nest two versions of the same animation.

      // Now reference the new names: in raw.shapes
      const newShapes = {};
      for (oldShapeName in shapeRenamings) {
        newShapeName = shapeRenamings[oldShapeName];
        newShapes[newShapeName] = this.raw.shapes[oldShapeName];
      }
      this.raw.shapes = newShapes;

      // ... in raw.containers
      const newContainers = {};
      for (var oldContainerName in containerRenamings) {
        newContainerName = containerRenamings[oldContainerName];
        newContainers[newContainerName] = this.raw.containers[oldContainerName];
      }
      this.raw.containers = newContainers;

      // ... for shapes and containers inside other containers
      const object4 = this.raw.containers != null ? this.raw.containers : {};
      for (containerName in object4) {
        container = object4[containerName];
        var iterable = container.c != null ? container.c : [];
        for (index = 0; index < iterable.length; index++) {
          child = iterable[index];
          if (child.gn) {
            child.gn = containerRenamings[child.gn];
          } else {
            container.c[index] = shapeRenamings[child];
          }
        }
      }

      // ... for containers inside various levels of nesting in animations and their tweens
      const object5 = this.raw.animations != null ? this.raw.animations : {};
      for (animationName in object5) {
        animation = object5[animationName];
        for (container of Array.from(animation.containers != null ? animation.containers : [])) {
          container.gn = containerRenamings[container.gn];
          container.bn = 'bn_' + container.gn + '_0';
        }  // I think bn always follows this pattern and can be derived from gn
        for (var tween of Array.from(animation.tweens != null ? animation.tweens : [])) {
          for (var step of Array.from(tween != null ? tween : [])) {
            var iterable1 = step.a != null ? step.a : [];
            for (index = 0; index < iterable1.length; index++) {
              var target = iterable1[index];
              if (renamedTarget = containerRenamings[__guardMethod__(target, 'replace', o => o.replace(/bn_([a-f0-9]+)_0/i, '$1'))]) {
                step.a[index] = 'bn_' + renamedTarget + '_0';
              } else if ((target != null ? target.state : undefined) && target.state.length) {
                for (var subTarget of Array.from(target.state)) {
                  if ((subTarget != null ? subTarget.t : undefined) && (renamedTarget = containerRenamings[typeof subTarget.t.replace === 'function' ? subTarget.t.replace(/bn_([a-f0-9]+)_0/i, '$1') : undefined])) {
                    subTarget.t = 'bn_' + renamedTarget + '_0';
                  }
                }
              } else if (target != null ? target.length : undefined) {
                for (var subEntry of Array.from(target)) {
                  if (__guard__(subEntry != null ? subEntry.state : undefined, x => x.length)) {
                    for (var subSubEntry of Array.from(subEntry.state)) {
                      if (renamedTarget = containerRenamings[__guardMethod__(subSubEntry != null ? subSubEntry.t : undefined, 'replace', o1 => o1.replace(/bn_([a-f0-9]+)_0/i, '$1'))]) {
                        subSubEntry.t = 'bn_' + renamedTarget + '_0';
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // ... and when containers are referenced directly within actions
      for (name in this.actions) {
        action = this.actions[name];
        if (action.container && (renamedTarget = containerRenamings[action.container])) {
          action.container = renamedTarget;
        }
        var object6 = action.relatedActions != null ? action.relatedActions : {};
        for (relatedActionName in object6) {
          relatedAction = object6[relatedActionName];
          if (relatedAction.container && (renamedTarget = containerRenamings[relatedAction.container])) {
            relatedAction.container = renamedTarget;
          }
        }
      }

      if (utils.isOzaria) {
        // Also rename shapes within color groups
        for (var group in this.colorGroups) {
          var shapes = this.colorGroups[group];
          for (index = 0; index < shapes.length; index++) {
            oldShapeName = shapes[index];
            if (newShapeName = shapeRenamings[oldShapeName]) {
              shapes[index] = newShapeName;
            }
          }
        }
      }

      if (this.debug) {
        console.log(shapeRenamings);
        return console.log(containerRenamings);
      }
    }

    cullUnused() {
      // Opposite direction of optimizeShapes. With more time, we could DRY this logic out, but let's do it quick, dirty, and WET.
      let animation, child, container, rawContainer;
      if (!_.size(this.actions)) { return; }  // Don't just delete everything if we are optimizing before we've configured any actions

      const used = {shapes: new Set(), containers: new Set(), animations: new Set()};

      // We'll only process animations that correspond to a configured action
      for (var name in this.actions) {
        var action = this.actions[name];
        if (action.animation) { used.animations.add(action.animation); }
        if (action.container) { used.containers.add(action.container); }  // Sometimes actions reference containers directly
        var object = action.relatedActions != null ? action.relatedActions : {};
        for (var relatedActionName in object) {
          var relatedAction = object[relatedActionName];
          if (relatedAction.animation) { used.animations.add(relatedAction.animation); }
          if (relatedAction.container) { used.containers.add(relatedAction.container); }
        }
      }

      // Make sure that we mark any nested animations as used. Feeling like stack solution instead of recursive today.
      const animationsToProcess = Array.from(used.animations);
      while ((animation = animationsToProcess.pop())) {
        var rawAnimation = this.raw.animations[animation];
        for (child of Array.from((rawAnimation.animations != null ? rawAnimation.animations : []))) {
          if (child.gn && !used.animations.has(child.gn)) {
            used.animations.add(child.gn);
            animationsToProcess.push(child.gn);
          }
        }
      }

      // Now walk the animations and mark their containers.
      // Just to be sure, mark containers used in tweens. This may be unnecessary; not bothering to do it for animations.
      for (var animationName of Array.from(Array.from(used.animations))) {
        animation = this.raw.animations[animationName];
        for (container of Array.from(animation.containers != null ? animation.containers : [])) { used.containers.add(container.gn); }
        for (var tween of Array.from(animation.tweens != null ? animation.tweens : [])) {
          for (var step of Array.from(tween != null ? tween : [])) {
            var iterable = step.a != null ? step.a : [];
            for (var index = 0; index < iterable.length; index++) {
              // Tween targets may be containers or animations. Animations aren't renamed, so skip the ones with long names.
              var containerName;
              var target = iterable[index];
              if ((containerName = __guardMethod__(target, 'replace', o => o.replace(/bn_([c0-9]+)_0/i, '$1'))) && (containerName.length < 40)) {
                used.containers.add(containerName);
              } else if ((target != null ? target.state : undefined) && target.state.length) {
                for (var subTarget of Array.from(target.state)) {
                  if ((subTarget != null ? subTarget.t : undefined) && (containerName = __guardMethod__(subTarget != null ? subTarget.t : undefined, 'replace', o1 => o1.replace(/bn_([c0-9]+)_0/i, '$1'))) && (containerName.length < 40)) {
                    used.containers.add(containerName);
                  }
                }
              } else if (target != null ? target.length : undefined) {
                for (var subEntry of Array.from(target)) {
                  if (__guard__(subEntry != null ? subEntry.state : undefined, x => x.length)) {
                    for (var subSubEntry of Array.from(subEntry.state)) {
                      if ((containerName = __guardMethod__(subSubEntry != null ? subSubEntry.t : undefined, 'replace', o2 => o2.replace(/bn_([c0-9]+)_0/i, '$1'))) && (containerName.length < 40)) {
                        used.containers.add(containerName);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Make sure that we mark any nested containers as used
      const containersToProcess = Array.from(used.containers);
      while ((container = containersToProcess.pop())) {
        rawContainer = this.raw.containers[container];
        for (child of Array.from((rawContainer.c != null ? rawContainer.c : []))) {
          if (child.gn && !used.containers.has(child.gn)) {
            used.containers.add(child.gn);
            containersToProcess.push(child.gn);
          }
        }
      }

      // Now that we know all the containers that are used, we know all the shapes that are used
      for (container of Array.from(Array.from(used.containers))) {
        rawContainer = this.raw.containers[container];
        for (child of Array.from((rawContainer.c != null ? rawContainer.c : []))) {
          if (_.isString(child)) {
            used.shapes.add(child);
          }
        }
      }

      if (this.debug) {
        console.log('Used', used.shapes.size, 'shapes out of', _.size(this.raw.shapes));
        console.log('Used', used.containers.size, 'containers out of', _.size(this.raw.containers));
        console.log('Used', used.animations.size, 'animations out of', _.size(this.raw.animations));
      }

      this.raw.shapes = _.omit(this.raw.shapes, (val, key) => !used.shapes.has(key));
      this.raw.containers = _.omit(this.raw.containers, (val, key) => !used.containers.has(key));
      return this.raw.animations = _.omit(this.raw.animations, (val, key) => !used.animations.has(key));
    }

    sortBySize() {
      // Could re-enable this if we wanted to put biggest shapes first, would have to put 'a' back in shape key for non-integer ordering
      //shapesBySize = Object.fromEntries Object.entries(@raw.shapes).sort (a, b) ->
      //  aScore = if a[1].bounds then 1000 * a[1].bounds[2] * a[1].bounds[3] else parseInt(a, 10)
      //  bScore = if b[1].bounds then 1000 * b[1].bounds[2] * b[1].bounds[3] else parseInt(b, 10)
      //  bScore - aScore
      //
      //console.log 'Shapes by size:', shapesBySize if @debug
      //
      //@raw.shapes = shapesBySize

      const object = this.raw.shapes != null ? this.raw.shapes : {};
      for (var shapeName in object) {
        var shape = object[shapeName];
        delete shape.bounds;
      }  // We don't even need this!

      // We do like having the biggest containers at the top, to help track down duplicate-ish containers and problems
      const containersBySize = Object.fromEntries(Object.entries(this.raw.containers).sort(function(a, b) {
        const aScore = a[1].b ? 1000 * a[1].b[2] * a[1].b[3] : parseInt(a[0].slice(1), 10);
        const bScore = b[1].b ? 1000 * b[1].b[2] * b[1].b[3] : parseInt(b[0].slice(1), 10);
        return bScore - aScore;
      })
      );

      if (this.debug) { console.log('Containers by size:', containersBySize); }

      return this.raw.containers = containersBySize;
    }
  };
  SpriteOptimizer.initClass();
  return SpriteOptimizer;
})());

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}
function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}