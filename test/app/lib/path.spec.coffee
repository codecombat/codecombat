describe('Path.createPath', ->
  path = require 'lib/surface/path'
  it('ignores the first point', ->
    points = [[0,0], [1,1], [2,2]]
    g = new createjs.Graphics()
    g.lineTo = jasmine.createSpy('graphicz')
    path.createPath(points, {tail_color:[100,100,100,0.0]}, g)
    expect(g.lineTo.calls.length).toBe(2)
    expect(g.lineTo.calls[0].args[0]).toBe(points[1][0])
  )
  
#  # BROKEN
  xit('dots correctly', ->
    points = ([x,x] for x in [0..30])
    g = new createjs.Graphics()
    calls = []
    funcs = ['lineTo', 'moveTo', 'beginStroke', 'endStroke', 'setStrokeStyle']
    for funcName in funcs
      f = (funcName) => (args...) =>
        calls.push("#{funcName}(#{args})")
      g[funcName] = jasmine.createSpy('graphics').andCallFake(f(funcName))
    path.createPath(points, {dotted:true}, g)
    expect(g.beginStroke.calls.length).toBe(4)
  )
)

