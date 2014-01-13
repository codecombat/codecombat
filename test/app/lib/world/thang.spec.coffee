describe 'Thang', ->
  Thang = require 'lib/world/thang'
  World = require 'lib/world/world'
  Rectangle = require 'lib/world/rectangle'
  Vector = require 'lib/world/vector'
  world = new World()

  #it 'intersects itself', ->
  #  spyOn(Vector, 'subtract').andCallThrough()
  #  for thang in world.thangs
  #    spyOn(thang, 'intersects').andCallThrough()
  #    expect(thang.intersects thang).toBeTruthy()
  #    #console.log thang.intersects.calls[0].args + ''
  #  #console.log "Vector.subtract calls: " + Vector.subtract.calls.length
