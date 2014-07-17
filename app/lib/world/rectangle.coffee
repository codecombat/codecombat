Vector = require './vector'
LineSegment = require './line_segment'

class Rectangle
  @className: 'Rectangle'
  # Class methods for nondestructively operating - TODO: add rotate
  for name in ['add', 'subtract', 'multiply', 'divide']
    do (name) ->
      Rectangle[name] = (a, b) ->
        a.copy()[name](b)

  isRectangle: true
  apiProperties: ['x', 'y', 'width', 'height', 'rotation', 'getPos', 'vertices', 'touchesRect', 'touchesPoint', 'distanceToPoint', 'distanceSquaredToPoint', 'distanceToRectangle', 'distanceSquaredToRectangle', 'distanceToEllipse', 'distanceSquaredToEllipse', 'distanceToShape', 'distanceSquaredToShape', 'containsPoint', 'copy', 'intersectsLineSegment', 'intersectsEllipse', 'intersectsRectangle', 'intersectsShape']

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

  lineSegments: ->
    vertices = @vertices()
    lineSegment0 = new LineSegment vertices[0], vertices[1]
    lineSegment1 = new LineSegment vertices[1], vertices[2]
    lineSegment2 = new LineSegment vertices[2], vertices[3]
    lineSegment3 = new LineSegment vertices[3], vertices[0]
    [lineSegment0, lineSegment1, lineSegment2, lineSegment3]

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
    # Get p in rect's coordinate space, then operate in one quadrant.
    p = Vector.subtract(p, @getPos()).rotate(-@rotation)
    dx = Math.max(Math.abs(p.x) - @width / 2, 0)
    dy = Math.max(Math.abs(p.y) - @height / 2, 0)
    Math.sqrt dx * dx + dy * dy

  distanceSquaredToPoint: (p) ->
    # Doesn't handle rotation; just supposed to be faster than distanceToPoint.
    p = Vector.subtract(p, @getPos())
    dx = Math.max(Math.abs(p.x) - @width / 2, 0)
    dy = Math.max(Math.abs(p.y) - @height / 2, 0)
    dx * dx + dy * dy

  distanceToRectangle: (other) ->
    Math.sqrt @distanceSquaredToRectangle other

  distanceSquaredToRectangle: (other) ->
    return 0 if @intersectsRectangle other
    [firstVertices, secondVertices] = [@vertices(), other.vertices()]
    [firstEdges, secondEdges] = [@lineSegments(), other.lineSegments()]
    ans = Infinity
    for i in [0 ... 4]
      for j in [0 ... firstEdges.length]
        ans = Math.min ans, firstEdges[j].distanceSquaredToPoint(secondVertices[i])
      for j in [0 ... secondEdges.length]
        ans = Math.min ans, secondEdges[j].distanceSquaredToPoint(firstVertices[i])
    ans

  distanceToEllipse: (ellipse) ->
    Math.sqrt @distanceSquaredToEllipse ellipse

  distanceSquaredToEllipse: (ellipse) ->
    @distanceSquaredToRectangle ellipse.rectangle()  # TODO: actually implement rectangle-ellipse distance

  distanceToShape: (shape) ->
    Math.sqrt @distanceSquaredToShape shape

  distanceSquaredToShape: (shape) ->
    if shape.isEllipse then @distanceSquaredToEllipse shape else @distanceSquaredToRectangle shape

  containsPoint: (p, withRotation=true) ->
    if withRotation and @rotation
      not @distanceToPoint(p)
    else
      @x - @width / 2 < p.x < @x + @width / 2 and @y - @height / 2 < p.y < @y + @height / 2

  intersectsLineSegment: (p1, p2) ->
    [px1, py1, px2, py2] = [p1.x, p1.y, p2.x, p2.y]
    m1 = (py1 - py2) / (px1 - px2)
    b1 = py1 - (m1 * px1)
    vertices = @vertices()
    lineSegments = [[vertices[0], vertices[1]], [vertices[1], vertices[2]], [vertices[2], vertices[3]], [vertices[3], vertices[0]]]
    for lineSegment in lineSegments
      [px1, py1, px2, py2] = [p1.x, p1.y, p2.x, p2.y]
      m2 = (py1 - py2) / (px1 - px2)
      b2 = py1 - (m * px1)
      if m1 isnt m2
        m = m1 - m2
        b = b2 - b1
        x = b / m
        [littleX, bigX] = if px1 < px2 then [px1, px2] else [px2, px1]
        if x >= littleX and x <= bigX
          y = (m1 * x) + b1
          [littleY, bigY] = if py1 < py2 then [py1, py2] else [py2, py1]
          if littleY <= solution and bigY >= solution
            return true
    false

  intersectsRectangle: (rectangle) ->
    return true if @containsPoint rectangle.getPos()
    for thisLineSegment in @lineSegments()
      for thatLineSegment in rectangle.lineSegments()
        if thisLineSegment.intersectsLineSegment(thatLineSegment)
          return true
    false

  intersectsEllipse: (ellipse) ->
    return true if @containsPoint ellipse.getPos()
    return true for lineSegment in @lineSegments() when ellipse.intersectsLineSegment lineSegment.a, lineSegment.b
    false

  intersectsShape: (shape) ->
    if shape.isEllipse then @intersectsEllipse shape else @intersectsRectangle shape

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
    @width is 0 and @height is 0

  invalid: () ->
    return (@x is Infinity) || isNaN(@x) || @y is Infinity || isNaN(@y) || @width is Infinity || isNaN(@width) || @height is Infinity || isNaN(@height) || @rotation is Infinity || isNaN(@rotation)

  toString: ->
    return "{x: #{@x.toFixed(0)}, y: #{@y.toFixed(0)}, w: #{@width.toFixed(0)}, h: #{@height.toFixed(0)}, rot: #{@rotation.toFixed(3)}}"

  serialize: ->
    {CN: @constructor.className, x: @x, y: @y, w: @width, h: @height, r: @rotation}

  @deserialize: (o, world, classMap) ->
    new Rectangle o.x, o.y, o.w, o.h, o.r

  serializeForAether: -> @serialize()
  @deserializeFromAether: (o) -> @deserialize o

module.exports = Rectangle
