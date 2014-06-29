describe 'Rectangle', ->
  Rectangle = require 'lib/world/rectangle'
  Vector = require 'lib/world/vector'

  it 'contains its own center', ->
    rect = new Rectangle 0, 0, 10, 10
    expect(rect.containsPoint(new Vector 0, 0)).toBe true

  it 'contains a point when rotated', ->
    rect = new Rectangle 0, -20, 40, 40, 3 * Math.PI / 4
    p = new Vector 0, 2
    expect(rect.containsPoint(p, true)).toBe true

  it 'correctly calculates distance to a faraway point', ->
    rect = new Rectangle 100, 50, 20, 40
    p = new Vector 200, 300
    d = 10 * Math.sqrt(610)
    expect(rect.distanceToPoint(p)).toBeCloseTo d
    rect.rotation = Math.PI / 2
    d = 80 * Math.sqrt(10)
    expect(rect.distanceToPoint(p)).toBeCloseTo d

  it 'does not modify itself or target Vector when calculating distance', ->
    rect = new Rectangle -100, -200, 1, 100
    rect2 = rect.copy()
    p = new Vector -100.25, -101
    p2 = p.copy()
    rect.distanceToPoint(p)
    expect(p.x).toEqual p2.x
    expect(p.y).toEqual p2.y
    expect(rect.x).toEqual rect2.x
    expect(rect.y).toEqual rect2.y
    expect(rect.width).toEqual rect2.width
    expect(rect.height).toEqual rect2.height
    expect(rect.rotation).toEqual rect2.rotation

  it 'correctly calculates distance to contained point', ->
    rect = new Rectangle -100, -200, 1, 100
    rect2 = rect.copy()
    p = new Vector -100.25, -160
    p2 = p.copy()
    expect(rect.distanceToPoint(p)).toBe 0
    rect.rotation = 0.00000001 * Math.PI
    expect(rect.distanceToPoint(p)).toBe 0

  it 'has predictable vertices', ->
    rect = new Rectangle 50, 50, 100, 100
    v = rect.vertices()
    expect(v[0].x).toEqual 0
    expect(v[0].y).toEqual 0
    expect(v[1].x).toEqual 0
    expect(v[1].y).toEqual 100
    expect(v[2].x).toEqual 100
    expect(v[2].y).toEqual 100
    expect(v[3].x).toEqual 100
    expect(v[3].y).toEqual 0

  it 'has predictable vertices when rotated', ->
    rect = new Rectangle 50, 50, 100, 100, Math.PI / 4
    v = rect.vertices()
    d = (Math.sqrt(2 * 100 * 100) - 100) / 2
    expect(v[0].x).toBeCloseTo -d
    expect(v[0].y).toBeCloseTo 50
    expect(v[1].x).toBeCloseTo 50
    expect(v[1].y).toBeCloseTo 100 + d
    expect(v[2].x).toBeCloseTo 100 + d
    expect(v[2].y).toBeCloseTo 50
    expect(v[3].x).toBeCloseTo 50
    expect(v[3].y).toBeCloseTo -d

  it 'is its own AABB when not rotated', ->
    rect = new Rectangle 10, 20, 30, 40
    aabb = rect.axisAlignedBoundingBox()
    for prop in ['x', 'y', 'width', 'height']
      expect(rect[prop]).toBe aabb[prop]

  it 'is its own AABB when rotated 180', ->
    rect = new Rectangle 10, 20, 30, 40, Math.PI
    aabb = rect.axisAlignedBoundingBox()
    for prop in ['x', 'y', 'width', 'height']
      expect(rect[prop]).toBe aabb[prop]
