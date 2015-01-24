describe 'Vector', ->
  Rectangle = require 'lib/world/rectangle'
  Vector = require 'lib/world/vector'

  it 'rotates properly', ->
    v = new Vector 200, 300
    v.rotate Math.PI / 2
    expect(v.x).toBeCloseTo -300
    expect(v.y).toBeCloseTo 200

    v.rotate Math.PI / 4
    expect(v.x).toBeCloseTo -250 * Math.sqrt 2
    expect(v.y).toBeCloseTo -50 * Math.sqrt 2

  it 'hardly moves when rotated a tiny bit', ->
    v = new Vector -100.25, -101
    v2 = v.copy()
    v2.rotate 0.0000001 * Math.PI
    expect(v.distance v2).toBeCloseTo 0

    v = new Vector 100.25, -101
    v2 = v.copy()
    v2.rotate 1.99999999 * Math.PI
    expect(v.distance v2).toBeCloseTo 0

    v = new Vector 10.25, 301
    v2 = v.copy()
    v2.rotate -0.0000001 * Math.PI
    expect(v.distance v2).toBeCloseTo 0
