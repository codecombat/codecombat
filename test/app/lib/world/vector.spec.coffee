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

  it 'has class methods equivalent to the instance methods', ->
    expectEquivalentMethods = (method, arg) ->
      v = new Vector 7, 7
      classResult = Vector[method](v, arg)
      instanceResult = v[method](arg)
      expect(classResult).toEqual instanceResult

    expectEquivalentMethods 'add', new Vector 1, 1
    expectEquivalentMethods 'subtract', new Vector 3, 3
    expectEquivalentMethods 'multiply', 4
    expectEquivalentMethods 'divide', 2
    expectEquivalentMethods 'limit', 3
    expectEquivalentMethods 'normalize'
    expectEquivalentMethods 'rotate', 0.3
    expectEquivalentMethods 'magnitude'
    expectEquivalentMethods 'heading'
    expectEquivalentMethods 'distance', new Vector 2, 2
    expectEquivalentMethods 'distanceSquared', new Vector 4, 4
    expectEquivalentMethods 'dot', new Vector 3, 3
    expectEquivalentMethods 'equals', new Vector 7, 7
    expectEquivalentMethods 'copy'

  xit "doesn't mutate when in player code", ->
    # We can't run these tests easily because it depends on being in interpreter mode now
    expectNoMutation = (fn) ->
      v = new Vector 5, 5
      v2 = fn v
      expect(v.x).toEqual 5
      expect(v).not.toBe v2

    expectNoMutation (v) -> v.normalize()
    expectNoMutation (v) -> v.limit 2
    expectNoMutation (v) -> v.subtract new Vector 2, 2
    expectNoMutation (v) -> v.add new Vector 2, 2
    expectNoMutation (v) -> v.divide 2
    expectNoMutation (v) -> v.multiply 2
    expectNoMutation (v) -> v.rotate 0.5

  it 'mutates when not in player code', ->
    expectMutation = (fn) ->
      v = new Vector 5, 5
      v2 = fn v
      expect(v.x).not.toEqual 5
      expect(v).toBe v2

    expectMutation (v) -> v.normalize()
    expectMutation (v) -> v.limit 2
    expectMutation (v) -> v.subtract new Vector 2, 2
    expectMutation (v) -> v.add new Vector 2, 2
    expectMutation (v) -> v.divide 2
    expectMutation (v) -> v.multiply 2
    expectMutation (v) -> v.rotate 0.5
