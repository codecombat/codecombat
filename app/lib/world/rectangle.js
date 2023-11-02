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
const Vector = require('./vector');
const LineSegment = require('./line_segment');

class Rectangle {
  static initClass() {
    this.className = 'Rectangle';
    // Class methods for nondestructively operating - TODO: add rotate
    for (var name of ['add', 'subtract', 'multiply', 'divide']) {
      ((name => Rectangle[name] = (a, b) => a.copy()[name](b)))(name);
    }
  
    this.prototype.isRectangle = true;
    this.prototype.apiProperties = ['x', 'y', 'width', 'height', 'rotation', 'getPos', 'vertices', 'touchesRect', 'touchesPoint', 'distanceToPoint', 'distanceSquaredToPoint', 'distanceToRectangle', 'distanceSquaredToRectangle', 'distanceToEllipse', 'distanceSquaredToEllipse', 'distanceToShape', 'distanceSquaredToShape', 'containsPoint', 'copy', 'intersectsLineSegment', 'intersectsEllipse', 'intersectsRectangle', 'intersectsShape'];
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
    return new Rectangle(this.x, this.y, this.width, this.height, this.rotation);
  }

  getPos() {
    return new Vector(this.x, this.y);
  }

  vertices() {
    // Counter-clockwise, starting from bottom left (when unrotated)
    const [w2, h2, cos, sin] = Array.from([this.width / 2, this.height / 2, Math.cos(this.rotation), Math.sin(-this.rotation)]);
    return [
      new Vector(this.x - ((w2 * cos) - (h2 * sin)), this.y - ((w2 * sin) + (h2 * cos))),
      new Vector(this.x - ((w2 * cos) + (h2 * sin)), this.y - ((w2 * sin) - (h2 * cos))),
      new Vector(this.x + ((w2 * cos) - (h2 * sin)), this.y + ((w2 * sin) + (h2 * cos))),
      new Vector(this.x + ((w2 * cos) + (h2 * sin)), this.y + ((w2 * sin) - (h2 * cos)))
    ];
  }

  lineSegments() {
    const vertices = this.vertices();
    return [
      new LineSegment(vertices[0], vertices[1]),
      new LineSegment(vertices[1], vertices[2]),
      new LineSegment(vertices[2], vertices[3]),
      new LineSegment(vertices[3], vertices[0])
    ];
  }

  touchesRect(other) {
    // Whether this rect shares part of any edge with other rect, for non-rotated, non-overlapping rectangles.
    // I think it says kitty-corner rects touch, but I don't think I want that.
    // Float instability might get me, too.
    const [bl1, tl1, tr1, br1] = Array.from(this.vertices());
    const [bl2, tl2, tr2, br2] = Array.from(other.vertices());
    if ((tl1.x > tr2.x) || (tl2.x > tr1.x)) { return false; }
    if ((bl1.y > tl2.y) || (bl2.y > tl1.y)) { return false; }
    if ((tl1.x === tr2.x) || (tl2.x === tr1.x)) { return true; }
    if ((tl1.y === bl2.y) || (tl2.y === bl1.y)) { return true; }
    return false;
  }

  touchesPoint(p) {
    // Whether this rect has point p exactly on one of its edges, assuming no rotation.
    const [bl, tl, tr, br] = Array.from(this.vertices());
    if (!(p.y >= bl.y) || !(p.y <= tl.y)) { return false; }
    if (!(p.x >= bl.x) || !(p.x <= br.x)) { return false; }
    if ((p.x === bl.x) || (p.x === br.x)) { return true; }
    if ((p.y === bl.y) || (p.y === tl.y)) { return true; }
    return false;
  }

  axisAlignedBoundingBox(rounded) {
    // Generates 1 rotated point and directly calculates the min and max

    let ymin;
    if (rounded == null) { rounded = true; }
    const cos = Math.cos(this.rotation);
    const sin = Math.sin(this.rotation);
    const rot = this.rotation % (2 * Math.PI);

    const Ax = this.x - (((this.width / 2) * cos) - ((this.height / 2) * sin));
    const Ay = this.y - (((this.width / 2) * sin) + ((this.height / 2) * cos));

    let xmin = (ymin = 0);
    if (rot > Math.PI) {
      if (rot < ((3 * Math.PI) / 2)) {
        xmin = Ax + (this.width  * cos);
        ymin = Ay + (this.height * cos) + (this.width * sin);
      } else {
        xmin = Ax;
        ymin = Ay + (this.width * sin);
      }
    } else {
      if (rot > (Math.PI / 2)) {
        xmin = (Ax + (this.width  * cos)) - (this.height * sin);
        ymin = Ay + (this.height * cos);
      } else {
        xmin = Ax - (this.height * sin);
        ymin = Ay;
      }
    }

    if (rounded) {
      xmin = Math.round(xmin);
      ymin = Math.round(ymin);
    }

    return new Rectangle(this.x, this.y, 2 * (this.x - xmin), 2 * (this.y - ymin), 0);
  }

  distanceToPoint(p) {
    // Get p in rect's coordinate space, then operate in one quadrant.

    const cos = Math.cos(this.rotation);
    const sin = Math.sin(this.rotation);
    const px = ((p.x - this.x) * cos) - ((p.y - this.y) * sin);
    const py = ((p.x - this.x) * sin) + ((p.y - this.y) * cos);

    const dx = Math.max(Math.abs(px) - (this.width / 2), 0);
    const dy = Math.max(Math.abs(py) - (this.height / 2), 0);
    return Math.sqrt((dx * dx) + (dy * dy));
  }

  distanceSquaredToPoint(p) {
    // Doesn't handle rotation and is significantly faster than distanceToPoint.
    const dx = Math.max(Math.abs(p.x - this.x) - (this.width / 2), 0);
    const dy = Math.max(Math.abs(p.y - this.y) - (this.height / 2), 0);
    return (dx * dx) + (dy * dy);
  }

  distanceToRectangle(other) {
    return Math.sqrt(this.distanceSquaredToRectangle(other));
  }

  distanceSquaredToRectangle(rect) {
    if (this.intersectsRectangle(rect)) { return 0; }

    const distanceSquaredSegmentPoint = function(a, b, point) {
      // Assuming a != b

      const t = (((point.x - a.x) * (b.x - a.x)) + ((point.y - a.y) * (b.y - a.y))) / a.distanceSquared(b);
      if (t <= 0) { return point.distanceSquared(a); }
      if (t >= 1) { return point.distanceSquared(b); }

      const dx = point.x - (a.x + (t * (b.x - a.x)));
      const dy = point.y - (a.y + (t * (b.y - a.y)));
      return (dx * dx) + (dy * dy);
    };


    // Find the indices of the point on each rect furthest from the center of the other rect
    // Then, find the minimum distSq of every pair of vertices from one rect and sides from another
    //   excluding all points and sides that are/include the furthest points decided above (12 pairs)

    const verts1 = this.vertices();
    const verts2 = rect.vertices();

    // Index of furthest vertex in verts1
    let d0 = Math.pow(verts1[0].x - rect.x, 2) + Math.pow(verts1[0].y - rect.y, 2);
    let d1 = Math.pow(verts1[1].x - rect.x, 2) + Math.pow(verts1[1].y - rect.y, 2);
    let d2 = Math.pow(verts1[2].x - rect.x, 2) + Math.pow(verts1[2].y - rect.y, 2);
    const idx1 = d0 < d1 ? (d1 < d2 ? 2 : 1) : (d1 < d2 ? 3 : 0);

    // Index of furthest vertex in verts2
    d0 = Math.pow(verts2[0].x - this.x, 2) + Math.pow(verts2[0].y - this.y, 2);
    d1 = Math.pow(verts2[1].x - this.x, 2) + Math.pow(verts2[1].y - this.y, 2);
    d2 = Math.pow(verts2[2].x - this.x, 2) + Math.pow(verts2[2].y - this.y, 2);
    const idx2 = d0 < d1 ? (d1 < d2 ? 2 : 1) : (d1 < d2 ? 3 : 0);

    let minDist = Infinity;

    for (let i = 1; i <= 2; i++) { // 2 segments per rectangle
      var a1 = verts1[(idx1 + i    ) % 4];
      var a2 = verts1[(idx1 + i + 1) % 4];
      var b1 = verts2[(idx2 + i    ) % 4];
      var b2 = verts2[(idx2 + i + 1) % 4];

      for (var j = 1; j <= 3; j++) { // 3 points per rectangle
        minDist = Math.min(
          minDist,
          distanceSquaredSegmentPoint(a1, a2, verts2[(idx2 + j) % 4]),
          distanceSquaredSegmentPoint(b1, b2, verts1[(idx1 + j) % 4])
        );
      }
    }

    return minDist;
  }

  distanceToEllipse(ellipse) {
    return Math.sqrt(this.distanceSquaredToEllipse(ellipse));
  }

  distanceSquaredToEllipse(ellipse) {
    return this.distanceSquaredToRectangle(ellipse.rectangle());  // TODO: actually implement rectangle-ellipse distance
  }

  distanceToShape(shape) {
    return Math.sqrt(this.distanceSquaredToShape(shape));
  }

  distanceSquaredToShape(shape) {
    if (shape.isEllipse) { return this.distanceSquaredToEllipse(shape); } else { return this.distanceSquaredToRectangle(shape); }
  }

  containsPoint(p, withRotation) {
    if (withRotation == null) { withRotation = true; }
    if (withRotation && this.rotation) {
      return !this.distanceToPoint(p);
    } else {
      return (this.x - (this.width / 2) < p.x && p.x < this.x + (this.width / 2)) && (this.y - (this.height / 2) < p.y && p.y < this.y + (this.height / 2));
    }
  }

  intersectsLineSegment(p1, p2) {
    // Optimized @intersectsRectangle(rect)
    // where rect = Rectangle((p1.x + p2.x) / 2, (p1.y + p2.y) / 2, 0, dist(p1, p2), atan2(p2.x - p1.x, p2.y - p1.y))
    // essentially considers the line segment a zero-width rectangle

    const Tx = ((p1.x + p2.x) / 2) - this.x;
    const Ty = ((p1.y + p2.y) / 2) - this.y;

    const Acos = Math.cos(this.rotation);
    const Asin = Math.sin(this.rotation);
    const Axx = -Acos;
    const Axy =  Asin;
    const Ayx =  Asin;
    const Ayy =  Acos;

    // B rotation = atan2(p2.x - p1.x, p2.y - p1.y)
    // when r = sqrt(x*x + y*y)
    //   cos(atan2(y, x)) == x / r
    //   sin(atan2(y, x)) == y / r

    const dx = p2.x - p1.x;
    const dy = p2.y - p1.y;
    const r = (dx * dx) + (dy * dy);

    const Bcos = dy / r;
    const Bsin = dx / r;
    const Bxx = -Bcos;
    const Bxy =  Bsin;
    const Byx =  Bsin;
    const Byy =  Bcos;

    const Aw = this.width  / 2;
    const Ah = this.height / 2;
    const Bh = r / 2;

    return !(
      (Math.abs((Tx * Axx) + (Ty * Axy)) > (Aw + Math.abs(((Byx * Bh) * Axx) + ((Byy * Bh) * Axy)))) ||
      (Math.abs((Tx * Ayx) + (Ty * Ayy)) > (Ah + Math.abs(((Byx * Bh) * Ayx) + ((Byy * Bh) * Ayy)))) ||
      (Math.abs((Tx * Bxx) + (Ty * Bxy)) > (Math.abs(((Axx * Aw) * Bxx) + ((Axy * Aw) * Bxy)) + Math.abs(((Ayx * Ah) * Bxx) + ((Ayy * Ah) * Bxy)))) ||
      (Math.abs((Tx * Byx) + (Ty * Byy)) > (Math.abs(((Axx * Aw) * Byx) + ((Axy * Aw) * Byy)) + Math.abs(((Ayx * Ah) * Byx) + ((Ayy * Ah) * Byy)) + Bh))
    );
  }

  intersectsRectangle(rect) {
    // "intersects" includes the case when one rectangle is entirely inside another

    // Rectangle-specific form of SAT
    // https://www.jkh.me/files/tutorials/Separating%20Axis%20Theorem%20for%20Oriented%20Bounding%20Boxes.pdf

    const Tx = rect.x - this.x;
    const Ty = rect.y - this.y;

    // Ax = [-1, 0].rotate -@rotation
    // Ay = [ 0, 1].rotate -@rotation
    const Acos = Math.cos(this.rotation);
    const Asin = Math.sin(this.rotation);
    const Axx = -Acos;
    const Axy =  Asin;
    const Ayx =  Asin;
    const Ayy =  Acos;

    // Bx = [-1, 0].rotate -rect.rotation
    // By = [ 0, 1].rotate -rect.rotation
    const Bcos = Math.cos(rect.rotation);
    const Bsin = Math.sin(rect.rotation);
    const Bxx = -Bcos;
    const Bxy =  Bsin;
    const Byx =  Bsin;
    const Byy =  Bcos;

    const Aw = this.width  / 2;
    const Ah = this.height / 2;
    const Bw = rect.width  / 2;
    const Bh = rect.height / 2;

    return !(
      (Math.abs((Tx * Axx) + (Ty * Axy)) > (Aw + Math.abs(((Bxx * Bw) * Axx) + ((Bxy * Bw) * Axy)) + Math.abs(((Byx * Bh) * Axx) + ((Byy * Bh) * Axy)))) ||
      (Math.abs((Tx * Ayx) + (Ty * Ayy)) > (Ah + Math.abs(((Bxx * Bw) * Ayx) + ((Bxy * Bw) * Ayy)) + Math.abs(((Byx * Bh) * Ayx) + ((Byy * Bh) * Ayy)))) ||
      (Math.abs((Tx * Bxx) + (Ty * Bxy)) > (Math.abs(((Axx * Aw) * Bxx) + ((Axy * Aw) * Bxy)) + Math.abs(((Ayx * Ah) * Bxx) + ((Ayy * Ah) * Bxy)) + Bw)) ||
      (Math.abs((Tx * Byx) + (Ty * Byy)) > (Math.abs(((Axx * Aw) * Byx) + ((Axy * Aw) * Byy)) + Math.abs(((Ayx * Ah) * Byx) + ((Ayy * Ah) * Byy)) + Bh))
    );
  }

  intersectsEllipse(ellipse) {
    if (this.containsPoint(ellipse.getPos())) { return true; }
    for (var lineSegment of Array.from(this.lineSegments())) { if (ellipse.intersectsLineSegment(lineSegment.a, lineSegment.b)) { return true; } }
    return false;
  }

  intersectsShape(shape) {
    if (shape.isEllipse) { return this.intersectsEllipse(shape); } else { return this.intersectsRectangle(shape); }
  }

  subtract(point) {
    this.x -= point.x;
    this.y -= point.y;
    this.pos.subtract(point);
    return this;
  }

  add(point) {
    this.x += point.x;
    this.y += point.y;
    this.pos.add(point);
    return this;
  }

  divide(n) {
    [this.width, this.height] = Array.from([this.width / n, this.height / n]);
    return this;
  }

  multiply(n) {
    [this.width, this.height] = Array.from([this.width * n, this.height * n]);
    return this;
  }

  isEmpty() {
    return (this.width === 0) && (this.height === 0);
  }

  invalid() {
    return (this.x === Infinity) || isNaN(this.x) || (this.y === Infinity) || isNaN(this.y) || (this.width === Infinity) || isNaN(this.width) || (this.height === Infinity) || isNaN(this.height) || (this.rotation === Infinity) || isNaN(this.rotation);
  }

  toString() {
    return `{x: ${this.x.toFixed(0)}, y: ${this.y.toFixed(0)}, w: ${this.width.toFixed(0)}, h: ${this.height.toFixed(0)}, rot: ${this.rotation.toFixed(3)}}`;
  }

  serialize() {
    return {CN: this.constructor.className, x: this.x, y: this.y, w: this.width, h: this.height, r: this.rotation};
  }

  static deserialize(o, world, classMap) {
    return new Rectangle(o.x, o.y, o.w, o.h, o.r);
  }

  serializeForAether() { return this.serialize(); }
  static deserializeFromAether(o) { return this.deserialize(o); }

  static fromVertices(vertices) {
    // Create a rectangle from a list of vertices. Inverse of @vertices()
    const [a, b, c, d] = Array.from(vertices);

    const p1 = new Vector((a.x + d.x) / 2, (a.y + d.y) / 2);
    const p2 = new Vector((b.x + c.x) / 2, (b.y + c.y) / 2);

    return new Rectangle(
      (p1.x + p2.x) / 2,
      (p1.y + p2.y) / 2,
      p1.distance(a) * 2,
      p1.distance(p2),
      Math.atan2(p2.x - p1.x, p2.y - p1.y)
    );
  }

  static equals(a, b) {
    // Tests if two rectangles' x, y, width, heigth, and rotation are exactly equal
    return (a.x === b.x) && (a.y === b.y) && (a.width === b.width) && (a.height === b.height) && (a.rotation === b.rotation);
  }

  static equalsByVertices(a, b) {
    // Tests if a.vertices() and b.vertices() are exactly equal (same order, same x and y values)
    const v1 = a.vertices();
    const v2 = b.vertices();
    return v1.every((v, i) => (v.x === v2[i].x) && (v.y === v2[i].y));
  }

  static approxEquals(a, b, epsilon) {
    // Tests if the difference between two rectangles' x, y, width, heigth, and rotation are all within epsilon
    if (epsilon == null) { epsilon = 1e-13; }
    return (Math.abs(a.x        - b.x       ) < epsilon) &&
    (Math.abs(a.y        - b.y       ) < epsilon) &&
    (Math.abs(a.width    - b.width   ) < epsilon) &&
    (Math.abs(a.height   - b.height  ) < epsilon) &&
    (Math.abs(a.rotation - b.rotation) < epsilon);
  }

  static approxEqualsByVertices(a, b, epsilon) {
    // Tests if every vertex in a.vertices() and b.vertices() are within epsilon x-wise and y-wise
    // Requires vertices to be in the same order
    if (epsilon == null) { epsilon = 1e-13; }
    const v1 = a.vertices();
    const v2 = b.vertices();

    return v1.every((v, i) => (Math.abs(v.x - v2[i].x) < epsilon) &&
    (Math.abs(v.y - v2[i].y) < epsilon));
  }
}
Rectangle.initClass();

module.exports = Rectangle;
