/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
describe('LineSegment', function() {
  const LineSegment = require('lib/world/line_segment');
  const Vector = require('lib/world/vector');

  const v00 = new Vector(0, 0);
  const v11 = new Vector(1, 1);
  const v22 = new Vector(2, 2);
  const v34 = new Vector(3, 4);
  const v04 = new Vector(0, 4);
  const v30 = new Vector(3, 0);
  const vneg = new Vector(-1, -1);

  it('intersects itself', function() {
    const lineSegment = new LineSegment(v00, v34);
    return expect(lineSegment.intersectsLineSegment(lineSegment)).toBe(true);
  });

  it('intersects other segments properly', function() {
    const l1 = new LineSegment(v00, v34);
    const l2 = new LineSegment(v04, v30);
    const l3 = new LineSegment(v00, v11);
    expect(l1.intersectsLineSegment(l2)).toBe(true);
    expect(l2.intersectsLineSegment(l1)).toBe(true);
    expect(l1.intersectsLineSegment(l3)).toBe(true);
    expect(l3.intersectsLineSegment(l1)).toBe(true);
    expect(l2.intersectsLineSegment(l3)).toBe(false);
    return expect(l3.intersectsLineSegment(l2)).toBe(false);
  });

  it('can tell when a point is on a line or segment', function() {
    const lineSegment = new LineSegment(v00, v11);
    expect(lineSegment.pointOnLine(v22, false)).toBe(true);
    expect(lineSegment.pointOnLine(v22, true)).toBe(false);
    expect(lineSegment.pointOnLine(v00, false)).toBe(true);
    expect(lineSegment.pointOnLine(v00, true)).toBe(true);
    expect(lineSegment.pointOnLine(v11, true)).toBe(true);
    expect(lineSegment.pointOnLine(v11, false)).toBe(true);
    expect(lineSegment.pointOnLine(v34, false)).toBe(false);
    return expect(lineSegment.pointOnLine(v34, true)).toBe(false);
  });

  return it('correctly calculates distance to points', function() {
    const lineSegment = new LineSegment(v00, v11);
    expect(lineSegment.distanceToPoint(v00)).toBe(0);
    expect(lineSegment.distanceToPoint(v11)).toBe(0);
    expect(lineSegment.distanceToPoint(v22)).toBeCloseTo(Math.SQRT2);
    expect(lineSegment.distanceToPoint(v34)).toBeCloseTo(Math.sqrt((2 * 2) + (3 * 3)));
    expect(lineSegment.distanceToPoint(v04)).toBeCloseTo(Math.sqrt((1 * 1) + (3 * 3)));
    expect(lineSegment.distanceToPoint(v30)).toBeCloseTo(Math.sqrt((2 * 2) + (1 * 1)));
    expect(lineSegment.distanceToPoint(vneg)).toBeCloseTo(Math.SQRT2);

    const nullSegment = new LineSegment(v11, v11);
    expect(lineSegment.distanceToPoint(v11)).toBe(0);
    return expect(lineSegment.distanceToPoint(v22)).toBeCloseTo(Math.SQRT2);
  });
});
