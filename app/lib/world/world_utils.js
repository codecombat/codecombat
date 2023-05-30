// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ArrayBufferView;
import Vector from './vector';
import Rectangle from './rectangle';
import Ellipse from './ellipse';
import LineSegment from './line_segment';
import Grid from './Grid';

export const typedArraySupport = (typeof Float32Array !== 'undefined' && Float32Array !== null);  // Not in IE until IE 10; we'll fall back to normal arrays
//module.exports.typedArraySupport = typedArraySupport = false  # imitate IE9 (and in God.coffee)

if (ArrayBufferView == null) {
  // https://code.google.com/p/chromium/issues/detail?id=60449
  if (typedArraySupport) {
    // We have it, it's just not exposed
    const someArray = new Uint8Array(0);
    if (someArray.__proto__) {
      // Most browsers
      ArrayBufferView = someArray.__proto__.__proto__.constructor;
    } else {
      // IE before 11
      ArrayBufferView = Object.getPrototypeOf(Object.getPrototypeOf(someArray)).constructor;
    }
  } else {
    // If we don't have typed arrays, we don't need an ArrayBufferView
    ArrayBufferView = null;
  }
}

export const clone = function(obj, skipThangs) {
  // http://coffeescriptcookbook.com/chapters/classes_and_objects/cloning
  if (skipThangs == null) { skipThangs = false; }
  if ((obj == null) || (typeof obj !== 'object')) {
    return obj;
  }

  if (obj instanceof Date) {
    return new Date(obj.getTime());
  }

  if (obj instanceof RegExp) {
    let flags = '';
    if (obj.global != null) { flags += 'g'; }
    if (obj.ignoreCase != null) { flags += 'i'; }
    if (obj.multiline != null) { flags += 'm'; }
    if (obj.sticky != null) { flags += 'y'; }
    return new RegExp(obj.source, flags);
  }

  if ((obj instanceof Vector) || (obj instanceof Rectangle) || (obj instanceof Ellipse) || (obj instanceof LineSegment)) {
    return obj.copy();
  }

  if (skipThangs && obj.isThang) {
    return obj;
  }

  if (_.isArray(obj)) {
    return obj.slice();
  }

  if (ArrayBufferView && obj instanceof ArrayBufferView) {
    return new obj.constructor(obj);
  }

  const newInstance = new obj.constructor();
  for (var key in obj) {
    newInstance[key] = clone(obj[key], skipThangs);
  }

  return newInstance;
};

// Walk a key chain down to the value. Can optionally set newValue instead.
// Same as in core utils, but don't want mutual imports
export const downTheChain = function(obj, keyChain, newValue) {
  if (newValue == null) { newValue = undefined; }
  if (!obj) { return null; }
  if (!_.isArray(keyChain)) { return obj[keyChain]; }
  let value = obj;
  while (keyChain.length && value) {
    if ((newValue !== undefined) && (keyChain.length === 1)) {
      value[keyChain[0]] = newValue;
      return newValue;
    }
    value = value[keyChain[0]];
    keyChain = keyChain.slice(1);
  }
  return value;
};

export const now = (__guard__(typeof window !== 'undefined' && window !== null ? window.performance : undefined, x => x.now) != null) ? (() => window.performance.now()) : (() => new Date());

export const consolidateThangs = function(thangs) {
  // We can gain a performance increase by consolidating all regular walls into a minimal covering, non-intersecting set a la Gridmancer.
  const debug = false;
  const isStructural = t => // Grid doesn't handle negative numbers, so don't coalesce walls below/left of 0, 0.
  t.stateless && t.collides && (t.collisionCategory === 'obstacles') && ['box', 'sheet'].includes(t.shape) &&  // Can only do wall-like obstacle Thangs.
  (t.spriteName !== 'Ice Wall') && (t.restitution === 1.0) &&  // Fixed restitution value on 2016-03-15, but it causes discrepancies, so disabled for Kelvintaph levels.
  /Wall/.test(t.spriteName) &&  // Not useful to do Thangs that aren't actually walls because they're usually not on a grid
  ((t.pos.x - (t.width / 2)) >= 0) && (t.pos.y - (t.height / 2)) >= 0;
  const structural = _.remove(thangs, isStructural);
  if (!structural.length) { return; }
  const rightmost = _.max(structural, t => t.pos.x + (t.width / 2));
  const topmost = _.max(structural, t => t.pos.y + (t.height / 2));
  const leftmost = _.min(structural, t => t.pos.x - (t.width / 2));
  const bottommost = _.min(structural, t => t.pos.y - (t.height / 2));
  if (debug) { console.log('got rightmost', rightmost.id, 'topmost', topmost.id, 'lefmostmost', leftmost.id, 'bottommost', bottommost.id, 'out of', structural.length, 'structural thangs'); }
  let left = Math.min(0, leftmost.pos.x - (leftmost.width / 2));
  let bottom = Math.min(0, bottommost.pos.y - (bottommost.height / 2));
  if ((left < 0) || (bottom < 0)) {
    console.error('Negative structural Thangs aren\'t supported, sorry!');  // TODO: largestRectangle, AI System, and anything else that accesses grid directly need updating to finish this
  }
  left = 0;
  bottom = 0;
  const width = (rightmost.pos.x + (rightmost.width / 2)) - left;
  const height = (topmost.pos.y + (topmost.height / 2)) - bottom;
  const padding = 0;
  if (debug) { console.log('got max width', width, 'height', height, 'left', left, 'bottom', bottom, 'of thangs', thangs.length, 'structural', structural.length); }
  const grid = new Grid(structural, width, height, padding, left, bottom);

  const dissection = [];
  const addStructuralThang = function(rect) {
    const thang = structural[dissection.length];  // Grab one we already know is configured properly.
    if (!thang) { console.error('Hmm, our dissection has more Thangs than the original structural Thangs?', dissection.length); }
    thang.pos.x = rect.x;
    thang.pos.y = rect.y;
    thang.width = rect.width;
    thang.height = rect.height;
    thang.destroyBody();
    thang.createBodyDef();
    thang.createBody();
    return dissection.push(thang);
  };

  dissectRectangles(grid, addStructuralThang, false, debug);

  // Now add the new structural thangs back to thangs and return the ones not in the dissection.
  console.log('Turned', structural.length, 'structural Thangs into', dissection.length, 'dissecting Thangs.');
  thangs.push(...Array.from(dissection || []));
  return structural.slice(dissection.length ,  structural.length);
};

export const dissectRectangles = function(grid, rectangleCallback, wantEmpty, debug) {
  // Mark Maxham's fast sweeper approach: https://github.com/codecombat/codecombat/issues/1090
  if (debug) { console.log(grid.toString()); }
  return (() => {
    const result = [];
    for (var x of Array.from(grid.rows(grid.left, grid.left + grid.width))) {
      var y = grid.clampColumn(grid.bottom);
      result.push((() => {
        const result1 = [];
        while (y < grid.clampColumn(grid.bottom + grid.height)) {
          var y2 = y;  // Note our current y.
          while (!occ(x, y2, grid, wantEmpty)) { ++y2; }  // Sweep through y to expand 1xN rect.
          if (y2 > y) {  // If we get a hit, sweep X with that swath.
            var x2 = x + 1;
            while (!occCol(x2, y, y2, grid, wantEmpty)) { ++x2; }
            var w = x2 - x;
            var h = y2 - y;
            var rect = addRect(grid, x, y, w, h, wantEmpty);
            rectangleCallback(rect);
            if (debug) { console.log(grid.toString()); }
            y = y2;
          }
          result1.push(++y);
        }
        return result1;
      })());
    }
    return result;
  })();
};

var occ = function(x, y, grid, wantEmpty) {
  if ((y > (grid.bottom + grid.height)) || (x > (grid.left + grid.width))) { return true; }
  if (!(grid.grid[y] != null ? grid.grid[y][x] : undefined)) { console.error('trying to check invalid coordinates', x, y, 'from grid', grid.bottom, grid.left, grid.width, grid.height); }
  return Boolean(grid.grid[y][x].length) === wantEmpty;
};

var occCol = function(x, y1, y2, grid, wantEmpty) {
  for (let j = y1, end = y2, asc = y1 <= end; asc ? j < end : j > end; asc ? j++ : j--) {
    if (occ(x, j, grid, wantEmpty)) {
      return true;
    }
  }
  return false;
};

var addRect = function(grid, leftX, bottomY, width, height, wantEmpty) {
  for (let x = leftX, end = leftX + width, asc = leftX <= end; asc ? x < end : x > end; asc ? x++ : x--) {
    for (var y = bottomY, end1 = bottomY + height, asc1 = bottomY <= end1; asc1 ? y < end1 : y > end1; asc1 ? y++ : y--) {
      grid.grid[y][x] = wantEmpty ? [true] : [];
    }
  }
  return new Rectangle(leftX + (width / 2), bottomY + (height / 2), width, height);
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
