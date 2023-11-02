/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
class LineSegment {
  static initClass() {
    this.className = "LineSegment";
  }

  constructor(a, b) {
    this.a = a;
    this.b = b;
    this.slope = (this.a.y - this.b.y) / (this.a.x - this.b.x);
    this.y0 = this.a.y - (this.slope * this.a.x);
    this.left = this.a.x < this.b.x ? this.a : this.b;
    this.right = this.a.x > this.b.x ? this.a : this.b;
    this.bottom = this.a.y < this.b.y ? this.a : this.b;
    this.top = this.a.y > this.b.y ? this.a : this.b;
  }

  y(x) {
    return (this.slope * x) + this.y0;
  }

  x(y) {
    return (y - this.y0) / this.slope;
  }

  intersectsLineSegment(lineSegment) {
    let left, right, x;
    if (lineSegment.slope === this.slope) {
      if (lineSegment.y0 === this.y0) {
        if ((lineSegment.left.x === this.left.x) || (lineSegment.left.x === this.right.x) || (lineSegment.right.x === this.right.x) || (lineSegment.right.x === this.left.x)) {
          // Special case then segments are vertical both and have the same 'x'
          if (Math.abs(this.slope) === Infinity) {
            return (this.bottom.y <= lineSegment.top.y && lineSegment.top.y <= this.top.y) || (lineSegment.bottom.y <= this.top.y && this.top.y <= lineSegment.top.y);
          } else {
            // segments are of the same line with shared start and/or end points
            return true;
          }
        } else {
          [left, right] = Array.from(lineSegment.left.x < this.left.x ? [lineSegment, this] : [this, lineSegment]);
          if (left.right.x > right.left.x) {
            // segments are of the same line and one is contained within the other
            return true;
          }
        }
      }
    } else if ((Math.abs(this.slope) !== Infinity) && (Math.abs(lineSegment.slope) !== Infinity)) {
      x = (lineSegment.y0 - this.y0) / (this.slope - lineSegment.slope);
      if ((x >= this.left.x) && (x <= this.right.x) && (x >= lineSegment.left.x) && (x <= lineSegment.right.x)) {
        return true;
      }
    } else if ((Math.abs(this.slope) !== Infinity) || (Math.abs(lineSegment.slope) !== Infinity)) {
      const [vertical, nonvertical] = Array.from(Math.abs(this.slope) !== Infinity ? [lineSegment, this] : [this, lineSegment]);
      ({
        x
      } = vertical.a);
      const bottom = vertical.bottom.y;
      const top = vertical.top.y;
      const y = nonvertical.y(x);
      left = nonvertical.left.x;
      right = nonvertical.right.x;
      if ((y >= bottom) && (y <= top) && (x >= left) && (x <= right)) {
        return true;
      }
    }
    return false;
  }

  pointOnLine(point, segment) {
    if (segment == null) { segment = true; }
    if (point.y === this.y(point.x)) {
      if (segment) {
        const [littleY, bigY] = Array.from(this.a.y < this.b.y ? [this.a.y, this.b.y] : [this.b.y, this.a.y]);
        if ((littleY <= point.y) && (bigY >= point.y)) {
          return true;
        }
      } else {
        return true;
      }
    }
    return false;
  }

  distanceSquaredToPoint(point) {
    // http://stackoverflow.com/a/1501725/540620
    if (this.a.equals(this.b)) { return this.a.distanceSquared(point); }
    const res = Math.min(point.distanceSquared(this.a), point.distanceSquared(this.b));
    const lineMagnitudeSquared = this.a.distanceSquared(this.b);
    const t = (((point.x - this.a.x) * (this.b.x - this.a.x)) + ((point.y - this.a.y) * (this.b.y - this.a.y))) / lineMagnitudeSquared;
    if (t < 0) { return this.a.distanceSquared(point); }
    if (t > 1) { return this.b.distanceSquared(point); }
    return point.distanceSquared({x: this.a.x + (t * (this.b.x - this.a.x)), y: this.a.y + (t * (this.b.y - this.a.y))});
  }

  distanceToPoint(point) {
    return Math.sqrt(this.distanceSquaredToPoint(point));
  }

  toString() {
    return `lineSegment(a=${this.a}, b=${this.b}, slope=${this.slope}, y0=${this.y0}, left=${this.left}, right=${this.right}, bottom=${this.bottom}, top=${this.top})`;
  }

  serialize() {
    return {CN: this.constructor.className, a: this.a, b: this.b};
  }

  static deserialize(o, world, classMap) {
    return new LineSegment(o.a, o.b);
  }

  serializeForAether() { return this.serialize(); }
  static deserializeFromAether(o) { return this.deserialize(o); }
}
LineSegment.initClass();

module.exports = LineSegment;
