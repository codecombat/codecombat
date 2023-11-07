// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// https://github.com/hornairs/blog/blob/master/assets/coffeescripts/flocking/vector.coffee
class Vector {
  static initClass() {
    let name;
    this.className = 'Vector';
    // Class methods for nondestructively operating
    for (name of ['add', 'subtract', 'multiply', 'divide', 'limit', 'normalize', 'rotate']) {
      ((name => Vector[name] = (a, b, useZ) => a.copy()[name](b, useZ)))(name);
    }
    for (name of ['magnitude', 'heading', 'distance', 'dot', 'equals', 'copy', 'distanceSquared']) {
      ((name => Vector[name] = (a, b, useZ) => a[name](b, useZ)))(name);
    }

    this.prototype.isVector = true;
    this.prototype.apiProperties = ['x', 'y', 'z', 'magnitude', 'heading', 'distance', 'dot', 'equals', 'copy', 'distanceSquared', 'add', 'subtract', 'multiply', 'divide', 'limit', 'normalize', 'rotate'];
  }

  constructor (x = 0, y = 0, z = 0) {
    if (!(this instanceof Vector)) { return new Vector(x, y, z) }
    [this.x, this.y, this.z] = Array.from([x, y, z]);
  }

  copy() {
    return new Vector(this.x, this.y, this.z);
  }

  // Mutating methods:

  normalize(useZ) {
    const m = this.magnitude(useZ);
    if (m > 0) { this.divide(m, useZ); }
    return this;
  }

  esper_normalize(useZ) {
    return this.copy().normalize(useZ);
  }

  limit(max) {
    if (this.magnitude() > max) {
      this.normalize();
      return this.multiply(max);
    } else {
      return this;
    }
  }

  esper_limit(max) {
    return this.copy().limit(max);
  }

  subtract(other, useZ) {
    this.x -= other.x;
    this.y -= other.y;
    if (useZ) { this.z -= other.z; }
    return this;
  }

  esper_subtract(other, useZ) {
    return this.copy().subtract(other, useZ);
  }

  add(other, useZ) {
    this.x += other.x;
    this.y += other.y;
    if (useZ) { this.z += other.z; }
    return this;
  }

  esper_add(other, useZ) {
    return this.copy().add(other, useZ);
  }

  divide(n, useZ) {
    [this.x, this.y] = Array.from([this.x / n, this.y / n]);
    if (useZ) { this.z = this.z / n; }
    return this;
  }

  esper_divide(n, useZ) {
    return this.copy().divide(n, useZ);
  }

  multiply(n, useZ) {
    [this.x, this.y] = Array.from([this.x * n, this.y * n]);
    if (useZ) { this.z = this.z * n; }
    return this;
  }

  esper_multiply(n, useZ) {
    return this.copy().multiply(n, useZ);
  }

  // Rotate it around the origin
  // If we ever want to make this also use z: https://en.wikipedia.org/wiki/Axes_conventions
  rotate(theta) {
    if (!theta) { return this; }
    [this.x, this.y] = Array.from([(Math.cos(theta) * this.x) - (Math.sin(theta) * this.y), (Math.sin(theta) * this.x) + (Math.cos(theta) * this.y)]);
    return this;
  }

  esper_rotate(theta) {
    return this.copy().rotate(theta);
  }

  // Non-mutating methods:

  magnitude(useZ) {
    let sum = (this.x * this.x) + (this.y * this.y);
    if (useZ) { sum += this.z * this.z; }
    return Math.sqrt(sum);
  }

  magnitudeSquared(useZ) {
    let sum = (this.x * this.x) + (this.y * this.y);
    if (useZ) { sum += this.z * this.z; }
    return sum;
  }

  heading() {
    return -1 * Math.atan2(-1 * this.y, this.x);
  }

  distance(other, useZ) {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    let sum = (dx * dx) + (dy * dy);
    if (useZ) {
      const dz = this.z - other.z;
      sum += dz * dz;
    }
    return Math.sqrt(sum);
  }

  distanceSquared(other, useZ) {
    const dx = this.x - other.x;
    const dy = this.y - other.y;
    let sum = (dx * dx) + (dy * dy);
    if (useZ) {
      const dz = this.z - other.z;
      sum += dz * dz;
    }
    return sum;
  }

  dot(other, useZ) {
    let sum = (this.x * other.x) + (this.y * other.y);
    if (useZ) { sum += this.z * other.z; }
    return sum;
  }

  // Not the strict projection, the other isn't converted to a unit vector first.
  projectOnto(other, useZ) {
    return other.copy().multiply(this.dot(other, useZ), useZ);
  }

  isZero(useZ) {
    let result = (this.x === 0) && (this.y === 0);
    if (useZ) { result = result && (this.z === 0); }
    return result;
  }

  equals(other, useZ) {
    let result = other && (this.x === other.x) && (this.y === other.y);
    if (useZ) { result = result && (this.z === other.z); }
    return result;
  }

  invalid() {
    return (this.x === Infinity) || isNaN(this.x) || (this.y === Infinity) || isNaN(this.y) || (this.z === Infinity) || isNaN(this.z);
  }

  toString(precision) {
    if (precision == null) { precision = 2; }
    return `{x: ${this.x.toFixed(precision)}, y: ${this.y.toFixed(precision)}, z: ${this.z.toFixed(precision)}}`;
  }


  serialize() {
    return {CN: this.constructor.className, x: this.x, y: this.y, z: this.z};
  }

  static deserialize(o, world, classMap) {
    return new Vector(o.x, o.y, o.z);
  }

  serializeForAether() { return this.serialize(); }
  static deserializeFromAether(o) { return this.deserialize(o); }
}
Vector.initClass();

module.exports = Vector;
