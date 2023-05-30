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
import Vector from './vector';

import LineSegment from './line_segment';
import Rectangle from './rectangle';

class Ellipse {
  static initClass() {
    this.className = "Ellipse";
  
    // TODO: add class methods for add, multiply, subtract, divide, rotate
  
    this.prototype.isEllipse = true;
    this.prototype.apiProperties = ['x', 'y', 'width', 'height', 'rotation', 'distanceToPoint', 'distanceSquaredToPoint', 'distanceToRectangle', 'distanceSquaredToRectangle', 'distanceToEllipse', 'distanceSquaredToEllipse', 'distanceToShape', 'distanceSquaredToShape', 'containsPoint', 'intersectsLineSegment', 'intersectsRectangle', 'intersectsEllipse', 'getPos', 'containsPoint', 'copy'];
  }

  constructor(x, y, width, height, rotation) {
    if (x == null) { x = 0; }
    this.x = x;
    if (y == null) { y = 0; }
    this.y = y;
    if (width == null) { width = 0; }
    this.width = width;
    if (height == null) { height = 0; }
    this.height = height;
    if (rotation == null) { rotation = 0; }
    this.rotation = rotation;
  }

  copy() {
    return new Ellipse(this.x, this.y, this.width, this.height, this.rotation);
  }

  getPos() {
    return new Vector(this.x, this.y);
  }

  rectangle() {
    return new Rectangle(this.x, this.y, this.width, this.height, this.rotation);
  }

  axisAlignedBoundingBox(rounded) {
    if (rounded == null) { rounded = true; }
    return this.rectangle().axisAlignedBoundingBox();
  }

  distanceToPoint(p) {
    return this.rectangle().distanceToPoint(p);  // TODO: actually implement ellipse ellipse-point distance
  }

  distanceSquaredToPoint(p) {
    // Doesn't handle rotation; just supposed to be faster than distanceToPoint.
    return this.rectangle().distanceSquaredToPoint(p);  // TODO: actually implement ellipse-point distance
  }

  distanceToRectangle(other) {
    return Math.sqrt(this.distanceSquaredToRectangle(other));
  }

  distanceSquaredToRectangle(other) {
    return this.rectangle().distanceSquaredToRectangle(other);  // TODO: actually implement ellipse-rectangle distance
  }

  distanceToEllipse(ellipse) {
    return Math.sqrt(this.distanceSquaredToEllipse(ellipse));
  }

  distanceSquaredToEllipse(ellipse) {
    return this.rectangle().distanceSquaredToEllipse(ellipse);  // TODO: actually implement ellipse-ellipse distance
  }

  distanceToShape(shape) {
    return Math.sqrt(this.distanceSquaredToShape(shape));
  }

  distanceSquaredToShape(shape) {
    if (shape.isEllipse) { return this.distanceSquaredToEllipse(shape); } else { return this.distanceSquaredToRectangle(shape); }
  }

  containsPoint(p, withRotation) {
    // "ellipse space" is the cartesian space
    // where the ellipse becomes the unit
    // circle centered at (0, 0)
    if (withRotation == null) { withRotation = true; }
    let [x, y] = Array.from([p.x - this.x, p.y - this.y]); // translate point into ellipse space
    if (withRotation && this.rotation) { // optionally rotate point into ellipse space
      const c = Math.cos(this.rotation);
      const s = Math.sin(this.rotation);
      [x, y] = Array.from([(x*c) + (y*s), (y*c) - (x*s)]);
    }
    x = (x / this.width) * 2; // scale point into ellipse space
    y = (y / this.height) * 2;
    return ((x*x) + (y*y)) <= 1; //if the resulting point falls on/in the unit circle at 0, 0
  }


  intersectsLineSegment(p1, p2) {
    let denominator, numeratorLeft, numeratorMiddle, numeratorRight, solution, solution1, solution2;
    const [px1, py1, px2, py2] = Array.from([p1.x, p1.y, p2.x, p2.y]);
    const m = (py1 - py2) / (px1 - px2);
    const m2 = Math.pow(m, 2);
    const c = py1 - (m * px1);
    const c2 = Math.pow(c, 2);
    const [a, b] = Array.from([this.width / 2, this.height / 2]);
    const [h, k] = Array.from([this.x, this.y]);
    const a2 = Math.pow(a, 2);
    const a4 = Math.pow(a, 2);
    const b2 = Math.pow(b, 2);
    const b4 = Math.pow(b, 4);
    const h2 = Math.pow(h, 2);
    const k2 = Math.pow(k, 2);
    const sint = Math.sin(this.rotation);
    const sin2t = Math.sin(2 * this.rotation);
    const cost = Math.cos(this.rotation);
    const cos2t = Math.cos(2 * this.rotation);
    if ((!isNaN(m)) && (m !== Infinity) && (m !== -Infinity)) {
      let bigX, littleX;
      numeratorLeft = (((((-a2 * c * m * cos2t) - (a2 * c * m)) + (a2 * c * sin2t)) - (a2 * h * m * sin2t) - (a2 * h * cos2t)) + (a2 * h) + (a2 * k * m * cos2t) + (a2 * k * m)) - (a2 * k * sin2t);
      numeratorMiddle = Math.SQRT2 * Math.sqrt(((((((((((a4 * b2 * m2 * cos2t) + (a4 * b2 * m2)) - (2 * a4 * b2 * m * sin2t) - (a4 * b2 * cos2t)) + (a4 * b2)) - (a2 * b4 * m2 * cos2t)) + (a2 * b4 * m2) + (2 * a2 * b4 * m * sin2t) + (a2 * b4 * cos2t) + (a2 * b4)) - (2 * a2 * b2 * c2) - (4 * a2 * b2 * c * h * m)) + (4 * a2 * b2 * c * k)) - (2 * a2 * b2 * h2 * m2)) + (4 * a2 * b2 * h * k * m)) - (2 * a2 * b2 * k2));
      numeratorRight = ((((b2 * c * m * cos2t) - (b2 * c * m) - (b2 * c * sin2t)) + (b2 * h * m * sin2t) + (b2 * h * cos2t) + (b2 * h)) - (b2 * k * m * cos2t)) + (b2 * k * m) + (b2 * k * sin2t);
      denominator = (((((a2 * m2 * cos2t) + (a2 * m2)) - (2 * a2 * m * sin2t) - (a2 * cos2t)) + a2) - (b2 * m2 * cos2t)) + (b2 * m2) + (2 * b2 * m * sin2t) + (b2 * cos2t) + b2;
      solution1 = ((-numeratorLeft - numeratorMiddle) + numeratorRight) / denominator;
      solution2 = (-numeratorLeft + numeratorMiddle + numeratorRight) / denominator;
      if ((!isNaN(solution1)) && (!isNaN(solution2))) {
        [littleX, bigX] = Array.from(px1 < px2 ? [px1, px2] : [px2, px1]);
        if (((littleX <= solution1) && (bigX >= solution1)) || ((littleX <= solution2) && (bigX >= solution2))) {
          return true;
        }
      }
      if ((!isNaN(solution1)) || (!isNaN(solution2))) {
        solution = !isNaN(solution1) ? solution1 : solution2;
        [littleX, bigX] = Array.from(px1 < px2 ? [px1, px2] : [px2, px1]);
        if ((littleX <= solution) && (bigX >= solution)) {
          return true;
        }
      } else {
        return false;
      }
    } else {
      const x = px1;
      const x2 = Math.pow(x, 2);
      numeratorLeft = (-a2 * h * sin2t) + (a2 * k * cos2t) + (a2 * k) + (a2 * x * sin2t);
      numeratorMiddle = Math.SQRT2 * Math.sqrt(((((((a4 * b2 * cos2t) + (a4 * b2)) - (a2 * b4 * cos2t)) + (a2 * b4)) - (2 * a2 * b2 * h2)) + (4 * a2 * b2 * h * x)) - (2 * a2 * b2 * x2));
      numeratorRight = (((b2 * h * sin2t) - (b2 * k * cos2t)) + (b2 * k)) - (b2 * x * sin2t);
      denominator = (((a2 * cos2t) + a2) - (b2 * cos2t)) + b2;
      solution1 = ((numeratorLeft - numeratorMiddle) + numeratorRight) / denominator;
      solution2 = (numeratorLeft + numeratorMiddle + numeratorRight) / denominator;
      if ((!isNaN(solution1)) || (!isNaN(solution2))) {
        solution = !isNaN(solution1) ? solution1 : solution2;
        const [littleY, bigY] = Array.from(py1 < py2 ? [py1, py2] : [py2, py1]);
        if ((littleY <= solution) && (bigY >= solution)) {
          return true;
        }
      } else {
        return false;
      }
    }
    return false;
  }

  intersectsRectangle(rectangle) {
    return rectangle.intersectsEllipse(this);
  }

  intersectsEllipse(ellipse) {
    return this.rectangle().intersectsEllipse(ellipse);  // TODO: actually implement ellipse-ellipse intersection
  }
    //return true if @containsPoint ellipse.getPos()

  intersectsShape(shape) {
    if (shape.isEllipse) { return this.intersectsEllipse(shape); } else { return this.intersectsRectangle(shape); }
  }

  toString() {
    return `{x: ${this.x.toFixed(0)}, y: ${this.y.toFixed(0)}, w: ${this.width.toFixed(0)}, h: ${this.height.toFixed(0)}, rot: ${this.rotation.toFixed(3)}}`;
  }

  serialize() {
    return {CN: this.constructor.className, x: this.x, y: this.y, w: this.width, h: this.height, r: this.rotation};
  }

  static deserialize(o, world, classMap) {
    return new Ellipse(o.x, o.y, o.w, o.h, o.r);
  }

  serializeForAether() { return this.serialize(); }
  static deserializeFromAether(o) { return this.deserialize(o); }
}
Ellipse.initClass();

export default Ellipse;
