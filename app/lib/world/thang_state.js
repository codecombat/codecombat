// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let bytesPerFloat, FloatArrayType, ThangState;
import { clone, typedArraySupport } from './world_utils';
import Vector from './vector';

if (typedArraySupport) {
  FloatArrayType = Float32Array;  // Better performance than Float64Array
  bytesPerFloat = FloatArrayType.BYTES_PER_ELEMENT != null ? FloatArrayType.BYTES_PER_ELEMENT : FloatArrayType.prototype.BYTES_PER_ELEMENT;
} else {
  bytesPerFloat = 4;
}

export default ThangState = (function() {
  ThangState = class ThangState {
    static initClass() {
      this.className = 'ThangState';
      this.trackedPropertyTypes = [
        'boolean',
        'number',
        'string',
        'array',  // will turn everything into strings
        'object',  // grrr
        'Vector',
        'Thang'  // serialized as ids, like strings
      ];
  
      this.prototype.hasRestored = false;
    }
    constructor(thang) {
      this.props = [];  // parallel array to @thang's trackedPropertiesKeys/Types
      if (!thang) { return; }
      this.thang = thang;
      for (let propIndex = 0; propIndex < thang.trackedPropertiesKeys.length; propIndex++) {
        var prop = thang.trackedPropertiesKeys[propIndex];
        var type = thang.trackedPropertiesTypes[propIndex];
        var value = thang[prop];
        if (type === 'Vector') {
          this.props.push(value != null ? value.copy() : undefined);  // could try storing [x, y, z] or {x, y, z} here instead if this is expensive
        } else if ((type === 'object') || (type === 'array')) {
          this.props.push(clone(value, true));
        } else {
          this.props.push(value);
        }
      }
    }

    // Either pass storage and type, or don't pass either of them
    getStoredProp(propIndex, type, storage) {
      // Optimize it
      let specialKey, value;
      if (!type) {
        type = this.trackedPropertyTypes[propIndex];
        storage = this.trackedPropertyValues[propIndex];
      }
      if (type === 'Vector') {
        value = new Vector(storage[3 * this.frameIndex], storage[(3 * this.frameIndex) + 1], storage[(3 * this.frameIndex) + 2]);
      } else if (type === 'string') {
        specialKey = storage[this.frameIndex];
        value = this.specialKeysToValues[specialKey];
      } else if (type === 'Thang') {
        specialKey = storage[this.frameIndex];
        value = this.thang.world.getThangByID(this.specialKeysToValues[specialKey]);
      } else if (type === 'array') {
        specialKey = storage[this.frameIndex];
        const valueString = this.specialKeysToValues[specialKey];
        if (valueString && (valueString.length > 1)) {
          // Trim leading Group Separator and trailing Record Separator, split by Record Separators, restore string array.
          value = valueString.substring(1, valueString.length - 1).split('\x1E');
        } else {
          value = [];
        }
      } else {
        value = storage[this.frameIndex];
      }
      return value;
    }

    getStateForProp(prop) {
      // Get the property, whether we have it stored in @props or in @trackedPropertyValues. Optimize it.
      // Figured based on http://jsperf.com/object-vs-array-vs-native-linked-list/13 that it should be faster with small arrays to do the indexOf reads (each up to 24x faster) than to do a single object read, and then we don't have to maintain an extra @props object; just keep array
      if (this.thang.world.synchronous) { return this.thang[prop]; }
      const propIndex = this.trackedPropertyKeys.indexOf(prop);
      if (propIndex === -1) {
        const initialPropIndex = this.thang.unusedTrackedPropertyKeys.indexOf(prop);
        if (initialPropIndex === -1) { return null; }
        return this.thang.unusedTrackedPropertyValues[initialPropIndex];
      }
      const value = this.props[propIndex];
      if ((value !== undefined) || this.hasRestored) { return value; }
      return this.props[propIndex] = this.getStoredProp(propIndex);
    }

    restore() {
      // Restore trackedProperties' values to @thang, retrieving them from @trackedPropertyValues if needed. Optimize it.
      let prop, propIndex, props;
      if ((this.thang._state === this) && !this.thang.partialState) { return this; }
      if (!this.hasRestored) {  // Restoring in a deserialized World for first time
        if (this.thang.world.synchronous) { return this; }
        for (propIndex = 0; propIndex < this.thang.unusedTrackedPropertyKeys.length; propIndex++) {
          prop = this.thang.unusedTrackedPropertyKeys[propIndex];
          if (this.trackedPropertyKeys.indexOf(prop) === -1) {
            this.thang[prop] = this.thang.unusedTrackedPropertyValues[propIndex];
          }
        }
        props = [];
        for (propIndex = 0; propIndex < this.trackedPropertyKeys.length; propIndex++) {
          prop = this.trackedPropertyKeys[propIndex];
          var type = this.trackedPropertyTypes[propIndex];
          var storage = this.trackedPropertyValues[propIndex];
          props.push(this.thang[prop] = this.getStoredProp(propIndex, type, storage));
        }
          //console.log @frameIndex, @thang.id, prop, propIndex, type, storage, 'got', @thang[prop]
        this.props = props;
        this.trackedPropertyTypes = (this.trackedPropertyValues = (this.specialKeysToValues = null));  // leave @trackedPropertyKeys for indexing
        this.hasRestored = true;
      } else {  // Restoring later times
        for (propIndex = 0; propIndex < this.thang.unusedTrackedPropertyKeys.length; propIndex++) {
          prop = this.thang.unusedTrackedPropertyKeys[propIndex];
          if (this.trackedPropertyKeys.indexOf(prop) === -1) {
            this.thang[prop] = this.thang.unusedTrackedPropertyValues[propIndex];
          }
        }
        for (propIndex = 0; propIndex < this.trackedPropertyKeys.length; propIndex++) {
          prop = this.trackedPropertyKeys[propIndex];
          this.thang[prop] = this.props[propIndex];
        }
      }
      this.thang.partialState = false;
      this.thang.stateChanged = true;
      return this;
    }

    restorePartial(ratio) {
      // Don't think we need to worry about unusedTrackedPropertyValues here.
      // If it's not tracked yet, it'll very rarely partially change between frames; we can afford to miss the first one.
      const inverse = 1 - ratio;
      for (let propIndex = 0; propIndex < this.trackedPropertyKeys.length; propIndex++) {
        var prop = this.trackedPropertyKeys[propIndex];
        if ((prop === 'pos') || (prop === 'rotation')) {var value;
        
          if (this.hasRestored) {
            value = this.props[propIndex];
          } else {
            var type = this.trackedPropertyTypes[propIndex];
            var storage = this.trackedPropertyValues[propIndex];
            value = this.getStoredProp(propIndex, type, storage);
          }
          if (prop === 'pos') {
            if ((this.thang.teleport && (this.thang.pos.distanceSquared(value) > 900)) || ((this.thang.pos.x === 0) && (this.thang.pos.y === 0))) {
              // Don't interpolate; it was probably a teleport. https://github.com/codecombat/codecombat/issues/738
              this.thang.pos = value;
            } else {
              this.thang.pos = this.thang.pos.copy();
              this.thang.pos.x = (inverse * this.thang.pos.x) + (ratio * value.x);
              this.thang.pos.y = (inverse * this.thang.pos.y) + (ratio * value.y);
              this.thang.pos.z = (inverse * this.thang.pos.z) + (ratio * value.z);
            }
          } else if (prop === 'rotation') {
            this.thang.rotation = (inverse * this.thang.rotation) + (ratio * value);
          }
          this.thang.partialState = true;
        }
      }
      this.thang.stateChanged = true;
      return this;
    }

    serialize(frameIndex, trackedPropertyIndices, trackedPropertyTypes, trackedPropertyValues, specialValuesToKeys, specialKeysToValues) {
      // Performance hotspot--called once per tracked property per Thang per frame. Optimize the crap out of it.
      for (let newPropIndex = 0; newPropIndex < trackedPropertyTypes.length; newPropIndex++) {
        var type = trackedPropertyTypes[newPropIndex];
        var originalPropIndex = trackedPropertyIndices[newPropIndex];
        var storage = trackedPropertyValues[newPropIndex];
        var value = this.props[originalPropIndex];
        if (value) {
          // undefined, null, false, 0 won't trigger in this serialization code scheme anyway, so we can't differentiate between them when deserializing
          var specialKey;
          if (type === 'Vector') {
            storage[3 * frameIndex] = value.x;
            storage[(3 * frameIndex) + 1] = value.y;
            storage[(3 * frameIndex) + 2] = value.z;
          } else if (type === 'string') {
            specialKey = specialValuesToKeys[value];
            if (!specialKey) {
              specialKey = specialKeysToValues.length;
              specialValuesToKeys[value] = specialKey;
              specialKeysToValues.push(value);
              storage[frameIndex] = specialKey;
            }
            storage[frameIndex] = specialKey;
          } else if (type === 'Thang') {
            value = value.id;
            specialKey = specialValuesToKeys[value];
            if (!specialKey) {
              specialKey = specialKeysToValues.length;
              specialValuesToKeys[value] = specialKey;
              specialKeysToValues.push(value);
              storage[frameIndex] = specialKey;
            }
            storage[frameIndex] = specialKey;
          } else if (type === 'array') {
            // We make sure the array keys won't collide with any string keys by using some unprintable characters.
            var stringPieces = ['\x1D'];  // Group Separator
            for (var element of Array.from(value)) {
              if (element && element.id) {  // Was checking element.isThang, but we can't store non-strings anyway
                element = element.id;
              }
              stringPieces.push(element, '\x1E');
            }  // Record Separator(s)
            value = stringPieces.join('');
            specialKey = specialValuesToKeys[value];
            if (!specialKey) {
              specialKey = specialKeysToValues.length;
              specialValuesToKeys[value] = specialKey;
              specialKeysToValues.push(value);
              storage[frameIndex] = specialKey;
            }
            storage[frameIndex] = specialKey;
          } else {
            storage[frameIndex] = value;
          }
        }
      }
          //console.log @thang.id, 'assigned prop', originalPropIndex, newPropIndex, value, type, 'at', frameIndex, 'to', storage[frameIndex]
      return null;
    }

    static deserialize(world, frameIndex, thang, trackedPropertyKeys, trackedPropertyTypes, trackedPropertyValues, specialKeysToValues) {
      // Optimize like no tomorrow--most performance-sensitive part of the whole app, called once per WorldFrame per Thang per trackedProperty, blocking the UI
      const ts = new ThangState;
      ts.thang = thang;
      ts.frameIndex = frameIndex;
      ts.trackedPropertyKeys = trackedPropertyKeys;
      ts.trackedPropertyTypes = trackedPropertyTypes;
      ts.trackedPropertyValues = trackedPropertyValues;
      ts.specialKeysToValues = specialKeysToValues;
      return ts;
    }

    static transferableBytesNeededForType(type, nFrames) {
      const bytes = (() => { switch (type) {
        case 'boolean': return 1;
        case 'number': return bytesPerFloat;
        case 'Vector': return bytesPerFloat * 3;
        case 'string': return 4;
        case 'Thang': return 4;  // turn them into strings of their ids
        case 'array':  return 4;  // turn them into strings and hope it doesn't explode?
        default: return 0;
      } })();
      // We need to be a multiple of bytesPerFloat otherwise bigger-byte array (Float64Array, etc.) offsets won't work
      // http://www.kirupa.com/forum/showthread.php?378737-Typed-Arrays-Y-U-No-offset-at-values-other-than-multiples-of-element-size
      return bytesPerFloat * Math.ceil((nFrames * bytes) / bytesPerFloat);
    }

    static createArrayForType(type, nFrames, buffer, offset) {
      const bytes = this.transferableBytesNeededForType(type, nFrames);
      const storage = (() => { switch (type) {
        case 'boolean':
          return new Uint8Array(buffer, offset, nFrames);
        case 'number':
          return new FloatArrayType(buffer, offset, nFrames);
        case 'Vector':
          return new FloatArrayType(buffer, offset, nFrames * 3);
        case 'string':
          return new Uint32Array(buffer, offset, nFrames);
        case 'Thang':
          return new Uint32Array(buffer, offset, nFrames);
        case 'array':
          return new Uint32Array(buffer, offset, nFrames);
        default:
          return [];
      } })();
      return [storage, bytes];
    }
  };
  ThangState.initClass();
  return ThangState;
})();

if (!typedArraySupport) {
  // Fall back to normal arrays in IE 9
  ThangState.createArrayForType = function(type, nFrames, buffer, offset) {
    const bytes = this.transferableBytesNeededForType(type, nFrames);
    const elementsPerFrame = type === 'Vector' ? 3 : 1;
    const storage = (__range__(0, nFrames * elementsPerFrame, false).map((i) => 0));
    return [storage, bytes];
  };
}

function __range__(left, right, inclusive) {
  let range = [];
  let ascending = left < right;
  let end = !inclusive ? right : ascending ? right + 1 : right - 1;
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i);
  }
  return range;
}