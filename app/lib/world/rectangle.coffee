Vector = require './vector'

class Rectangle
  @className: 'Rectangle'
  # Class methods for nondestructively operating
  for name in ['add', 'subtract', 'multiply', 'divide']
    do (name) ->
      Rectangle[name] = (a, b) ->
        a.copy()[name](b)

  apiProperties: ['x', 'y', 'width', 'height', 'rotation', 'getPos', 'vertices', 'touchesRect', 'touchesPoint', 'distanceToPoint', 'containsPoint', 'copy']

  constructor: (@x=0, @y=0, @width=0, @height=0, @rotation=0) ->

  copy: ->
    new Rectangle(@x, @y, @width, @height, @rotation)

  getPos: ->
    new Vector(@x, @y)

  vertices: ->
    # Counter-clockwise, starting from bottom left (when unrotated)
    [w2, h2, cos, sin] = [@width / 2, @height / 2, Math.cos(@rotation), Math.sin(-@rotation)]
    [
      new Vector @x - (w2 * cos - h2 * sin), @y - (w2 * sin + h2 * cos)
      new Vector @x - (w2 * cos + h2 * sin), @y - (w2 * sin - h2 * cos)
      new Vector @x + (w2 * cos - h2 * sin), @y + (w2 * sin + h2 * cos)
      new Vector @x + (w2 * cos + h2 * sin), @y + (w2 * sin - h2 * cos)
    ]

  touchesRect: (other) ->
    # Whether this rect shares part of any edge with other rect, for non-rotated, non-overlapping rectangles.
    # I think it says kitty-corner rects touch, but I don't think I want that.
    # Float instability might get me, too.
    [bl1, tl1, tr1, br1] = @vertices()
    [bl2, tl2, tr2, br2] = other.vertices()
    return false if tl1.x > tr2.x or tl2.x > tr1.x
    return false if bl1.y > tl2.y or bl2.y > tl1.y
    return true if tl1.x is tr2.x or tl2.x is tr1.x
    return true if tl1.y is bl2.y or tl2.y is bl1.y
    false

  touchesPoint: (p) ->
    # Whether this rect has point p exactly on one of its edges, assuming no rotation.
    [bl, tl, tr, br] = @vertices()
    return false unless p.y >= bl.y and p.y <= tl.y
    return false unless p.x >= bl.x and p.x <= br.x
    return true if p.x is bl.x or p.x is br.x
    return true if p.y is bl.y or p.y is tl.y
    false

  axisAlignedBoundingBox: (rounded=true) ->
    box = @copy()
    return box unless @rotation
    box.rotation = 0
    [left, top] = [9001, 9001]
    for vertex in @vertices()
      [left, top] = [Math.min(left, vertex.x), Math.min(top, vertex.y)]
    if rounded
      [left, top] = [Math.round(left), Math.round(top)]
    [box.width, box.height] = [2 * (@x - left), 2 * (@y - top)]
    box

  distanceToPoint: (p) ->
    # Get p in rect's coordinate space, then operate in one quadrant
    p = Vector.subtract(p, @getPos()).rotate(-@rotation)
    dx = Math.max(Math.abs(p.x) - @width / 2, 0)
    dy = Math.max(Math.abs(p.y) - @height / 2, 0)
    Math.sqrt dx * dx + dy * dy

  distanceSquaredToPoint: (p) ->
    # Doesn't handle rotation; just supposed to be faster than distanceToPoint
    p = Vector.subtract(p, @getPos())
    dx = Math.max(Math.abs(p.x) - @width / 2, 0)
    dy = Math.max(Math.abs(p.y) - @height / 2, 0)
    dx * dx + dy * dy

  containsPoint: (p, withRotation=true) ->
    if withRotation and @rotation
      not @distanceToPoint(p)
    else
      @x - @width / 2 < p.x < @x + @width / 2 and @y - @height / 2 < p.y < @y + @height / 2

  subtract: (point) ->
    @x -= point.x
    @y -= point.y
    @pos.subtract point
    @

  add: (point) ->
    @x += point.x
    @y += point.y
    @pos.add point
    @

  divide: (n) ->
    [@width, @height] = [@width / n, @height / n]
    @

  multiply: (n) ->
    [@width, @height] = [@width * n, @height * n]
    @

  isEmpty: () ->
    @width == 0 and @height == 0

  invalid: () ->
    return (@x == Infinity) || isNaN(@x) || @y == Infinity || isNaN(@y) || @width == Infinity || isNaN(@width) || @height == Infinity || isNaN(@height) || @rotation == Infinity || isNaN(@rotation)

  toString: ->
    return "{x: #{@x.toFixed(0)}, y: #{@y.toFixed(0)}, w: #{@width.toFixed(0)}, h: #{@height.toFixed(0)}, rot: #{@rotation.toFixed(3)}}"

  serialize: ->
    {CN: @constructor.className, x: @x, y: @y, w: @width, h: @height, r: @rotation}

  @deserialize: (o, world, classMap) ->
    new Rectangle o.x, o.y, o.w, o.h, o.r

  serializeForAether: -> @serialize()
  @deserializeFromAether: (o) -> @deserialize o

module.exports = Rectangle
