/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('Rectangle', function() {
  const Rectangle = require('lib/world/rectangle');
  const Vector = require('lib/world/vector');
  const Ellipse = require('lib/world/ellipse');

  it('creates a rectangle from vertices', function() {
    const rects = [
      new Rectangle(0, 0, 10, 10, 0),
      new Rectangle(0, 0, 10, 10, 2),
      new Rectangle(20, 10, 1, 100, 3.2)
    ];

    return Array.from(rects).map((rect) =>
      expect(Rectangle.approxEqualsByVertices(rect, Rectangle.fromVertices(rect.vertices()))).toBe(true));
  });

  it('contains its own center', function() {
    const rect = new Rectangle(0, 0, 10, 10, 0);
    return expect(rect.containsPoint(new Vector(0, 0))).toBe(true);
  });

  it('contains a point when rotated', function() {
    let rect = new Rectangle(0, -20, 40, 40, (3 * Math.PI) / 4);
    const p = new Vector(0, 2);
    expect(rect.containsPoint(p, true)).toBe(true);

    // https://www.desmos.com/calculator/po8ifjklfs
    rect = Rectangle.fromVertices([new Vector(13.516, -25.286), new Vector(-1.728, 6.305), new Vector(77.682, 44.622), new Vector(92.926, 13.031)]);
    return expect(rect.containsPoint(new Vector(8.650, 0.499))).toBe(true);
  });

  it('correctly calculates distance to a faraway point', function() {
    const rect = new Rectangle(100, 50, 20, 40);
    const p = new Vector(200, 300);
    let d = 10 * Math.sqrt(610);
    expect(rect.distanceToPoint(p)).toBeCloseTo(d);
    rect.rotation = Math.PI / 2;
    d = 80 * Math.sqrt(10);
    return expect(rect.distanceToPoint(p)).toBeCloseTo(d);
  });

  it('does not modify itself or target Vector when calculating distance', function() {
    const rect = new Rectangle(-100, -200, 1, 100);
    const rect2 = rect.copy();
    const p = new Vector(-100.25, -101);
    const p2 = p.copy();
    rect.distanceToPoint(p);
    expect(p.x).toEqual(p2.x);
    expect(p.y).toEqual(p2.y);
    expect(rect.x).toEqual(rect2.x);
    expect(rect.y).toEqual(rect2.y);
    expect(rect.width).toEqual(rect2.width);
    expect(rect.height).toEqual(rect2.height);
    return expect(rect.rotation).toEqual(rect2.rotation);
  });

  it('correctly calculates distance to contained point', function() {
    const rect = new Rectangle(-100, -200, 1, 100);
    const p = new Vector(-100.25, -160);
    expect(rect.distanceToPoint(p)).toBe(0);
    rect.rotation = 0.00000001 * Math.PI;
    return expect(rect.distanceToPoint(p)).toBe(0);
  });

  it('correctly calculates distance to other rectangles', function() {
    expect(new Rectangle(0, 0, 4, 4, Math.PI / 4).distanceToRectangle(new Rectangle(4, -4, 2, 2, 0))).toBeCloseTo(2.2426);
    expect(new Rectangle(0, 0, 3, 3, 0).distanceToRectangle(new Rectangle(0, 0, 2, 2, 0))).toBe(0);
    expect(new Rectangle(0, 0, 3, 3, 0).distanceToRectangle(new Rectangle(0, 0, 2.5, 2.5, Math.PI / 4))).toBe(0);
    expect(new Rectangle(0, 0, 4, 4, 0).distanceToRectangle(new Rectangle(4, 2, 2, 2, 0))).toBe(1);
    expect(new Rectangle(0, 0, 4, 4, 0).distanceToRectangle(new Rectangle(4, 2, 2, 2, Math.PI / 4))).toBeCloseTo(2 - Math.SQRT2);

    // https://www.desmos.com/calculator/po8ifjklfs
    const rect1 = Rectangle.fromVertices([new Vector(89.936, 100.355), new Vector(105.842, 88.077), new Vector(54.581, 21.670), new Vector(38.675, 33.948)]);
    const rect2 = Rectangle.fromVertices([new Vector(116.029, 61.108), new Vector(87.422, 9.247), new Vector(68.955, 19.433), new Vector(97.563, 71.294)]);
    return expect(rect1.distanceToRectangle(rect2)).toBeCloseTo(3.701777957811988);
  });

  it('has predictable vertices', function() {
    const rect = new Rectangle(50, 50, 100, 100);
    const v = rect.vertices();
    expect(v[0].x).toEqual(0);
    expect(v[0].y).toEqual(0);
    expect(v[1].x).toEqual(0);
    expect(v[1].y).toEqual(100);
    expect(v[2].x).toEqual(100);
    expect(v[2].y).toEqual(100);
    expect(v[3].x).toEqual(100);
    return expect(v[3].y).toEqual(0);
  });

  it('has predictable vertices when rotated', function() {
    const rect = new Rectangle(50, 50, 100, 100, Math.PI / 4);
    const v = rect.vertices();
    const d = (Math.sqrt(2 * 100 * 100) - 100) / 2;
    expect(v[0].x).toBeCloseTo(-d);
    expect(v[0].y).toBeCloseTo(50);
    expect(v[1].x).toBeCloseTo(50);
    expect(v[1].y).toBeCloseTo(100 + d);
    expect(v[2].x).toBeCloseTo(100 + d);
    expect(v[2].y).toBeCloseTo(50);
    expect(v[3].x).toBeCloseTo(50);
    return expect(v[3].y).toBeCloseTo(-d);
  });

  it('is its own AABB when not rotated', function() {
    const rect = new Rectangle(10, 20, 30, 40);
    const aabb = rect.axisAlignedBoundingBox();
    return ['x', 'y', 'width', 'height'].map((prop) =>
      expect(rect[prop]).toBe(aabb[prop]));
});

  it('is its own AABB when rotated 180', function() {
    const rect = new Rectangle(10, 20, 30, 40, Math.PI);
    const aabb = rect.axisAlignedBoundingBox();
    return ['x', 'y', 'width', 'height'].map((prop) =>
      expect(rect[prop]).toBe(aabb[prop]));
});

  it('calculates rectangle intersections properly', function() {
    const rect = new Rectangle(1, 1, 2, 2, 0);
    expect(rect.intersectsShape(new Rectangle(3, 1, 2, 2, 0))).toBe(true);
    expect(rect.intersectsShape(new Rectangle(3, 3, 2, 2, 0))).toBe(true);
    expect(rect.intersectsShape(new Rectangle(1, 1, 2, 2, 0))).toBe(true);
    expect(rect.intersectsShape(new Rectangle(1, 1, Math.SQRT1_2, Math.SQRT1_2, Math.PI / 4))).toBe(true);
    expect(rect.intersectsShape(new Rectangle(4, 1, 2, 2, 0))).toBe(false);
    expect(rect.intersectsShape(new Rectangle(3, 4, 2, 2, 0))).toBe(false);
    expect(rect.intersectsShape(new Rectangle(1, 4, 2 * Math.SQRT1_2, 2 * Math.SQRT1_2, Math.PI / 4))).toBe(false);
    expect(rect.intersectsShape(new Rectangle(3, 1, 2, 2, Math.PI / 4))).toBe(true);
    expect(rect.intersectsShape(new Rectangle(1, 2, 2 * Math.SQRT2, 2 * Math.SQRT2, Math.PI / 4))).toBe(true);

    // https://www.desmos.com/calculator/po8ifjklfs
    const rect1 = Rectangle.fromVertices([new Vector(89.936, 100.355), new Vector(105.842, 88.077), new Vector(54.581, 21.670), new Vector(38.675, 33.948)]);
    const rect2 = Rectangle.fromVertices([new Vector(116.029, 61.108), new Vector(87.422, 9.247), new Vector(68.955, 19.433), new Vector(97.563, 71.294)]);
    return expect(rect1.intersectsShape(rect2)).toBe(false);
  });

  it('calculates ellipse intersections properly', function() {
    const rect = new Rectangle(1, 1, 2, 2, 0);
    expect(rect.intersectsShape(new Ellipse(1, 1, Math.SQRT1_2, Math.SQRT1_2, Math.PI / 4))).toBe(true);
    expect(rect.intersectsShape(new Ellipse(4, 1, 2, 2, 0))).toBe(false);
    expect(rect.intersectsShape(new Ellipse(3, 4, 2, 2, 0))).toBe(false);
    return expect(rect.intersectsShape(new Ellipse(1, 4, 2 * Math.SQRT1_2, 2 * Math.SQRT1_2, Math.PI / 4))).toBe(false);
  });

  return it('calculates line segment intersections properly', function() {
    const rect = new Rectangle(1, 1, 2, 2, 0);
    expect(rect.intersectsLineSegment(new Vector(2.1, -1), new Vector(2.1, 3))).toBe(false);

    // https://www.desmos.com/calculator/po8ifjklfs
    const rect1 = Rectangle.fromVertices([new Vector(-26.780, -25.019), new Vector(-32.317, 71.140), new Vector(39.084, 75.251), new Vector(44.621, -20.907)]);
    const rect2 = Rectangle.fromVertices([new Vector(13.516, -25.286), new Vector(-1.728, 6.305), new Vector(77.682, 44.622), new Vector(92.926, 13.031)]);

    const p1 = new Vector(8.650, 0.499);
    const p2 = new Vector(0.284, 8.543);

    expect(rect1.intersectsLineSegment(p1, p2)).toBe(true);
    return expect(rect2.intersectsLineSegment(p1, p2)).toBe(true);
  });
});
