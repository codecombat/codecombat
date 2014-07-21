describe 'LineSegment', ->
  LineSegment = require 'lib/world/line_segment'
  Vector = require 'lib/world/vector'

  v00 = new Vector(0, 0)
  v11 = new Vector(1, 1)
  v22 = new Vector(2, 2)
  v34 = new Vector(3, 4)
  v04 = new Vector(0, 4)
  v30 = new Vector(3, 0)
  vneg = new Vector(-1, -1)

  it 'intersects itself', ->
    lineSegment = new LineSegment v00, v34
    expect(lineSegment.intersectsLineSegment lineSegment).toBe true

  it 'intersects other segments properly', ->
    l1 = new LineSegment v00, v34
    l2 = new LineSegment v04, v30
    l3 = new LineSegment v00, v11
    expect(l1.intersectsLineSegment l2).toBe true
    expect(l2.intersectsLineSegment l1).toBe true
    expect(l1.intersectsLineSegment l3).toBe true
    expect(l3.intersectsLineSegment l1).toBe true
    expect(l2.intersectsLineSegment l3).toBe false
    expect(l3.intersectsLineSegment l2).toBe false

  it 'can tell when a point is on a line or segment', ->
    lineSegment = new LineSegment v00, v11
    expect(lineSegment.pointOnLine v22, false).toBe true
    expect(lineSegment.pointOnLine v22, true).toBe false
    expect(lineSegment.pointOnLine v00, false).toBe true
    expect(lineSegment.pointOnLine v00, true).toBe true
    expect(lineSegment.pointOnLine v11, true).toBe true
    expect(lineSegment.pointOnLine v11, false).toBe true
    expect(lineSegment.pointOnLine v34, false).toBe false
    expect(lineSegment.pointOnLine v34, true).toBe false

  it 'correctly calculates distance to points', ->
    lineSegment = new LineSegment v00, v11
    expect(lineSegment.distanceToPoint v00).toBe 0
    expect(lineSegment.distanceToPoint v11).toBe 0
    expect(lineSegment.distanceToPoint v22).toBeCloseTo Math.SQRT2
    expect(lineSegment.distanceToPoint v34).toBeCloseTo Math.sqrt(2 * 2 + 3 * 3)
    expect(lineSegment.distanceToPoint v04).toBeCloseTo Math.sqrt(1 * 1 + 3 * 3)
    expect(lineSegment.distanceToPoint v30).toBeCloseTo Math.sqrt(2 * 2 + 1 * 1)
    expect(lineSegment.distanceToPoint vneg).toBeCloseTo Math.SQRT2

    nullSegment = new LineSegment v11, v11
    expect(lineSegment.distanceToPoint v11).toBe 0
    expect(lineSegment.distanceToPoint v22).toBeCloseTo Math.SQRT2
