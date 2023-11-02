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
    [
      new LineSegment vertices[0], vertices[1]
      new LineSegment vertices[1], vertices[2]
      new LineSegment vertices[2], vertices[3]
      new LineSegment vertices[3], vertices[0]
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
    # Generates 1 rotated point and directly calculates the min and max

    cos = Math.cos(@rotation)
    sin = Math.sin(@rotation)
    rot = @rotation % (2 * Math.PI)

    Ax = @x - (@width / 2 * cos - @height / 2 * sin)
    Ay = @y - (@width / 2 * sin + @height / 2 * cos)

    xmin = ymin = 0
    if rot > Math.PI
      if rot < 3 * Math.PI / 2
        xmin = Ax + @width  * cos
        ymin = Ay + @height * cos + @width * sin
      else
        xmin = Ax
        ymin = Ay + @width * sin
    else
      if rot > Math.PI / 2
        xmin = Ax + @width  * cos - @height * sin
        ymin = Ay + @height * cos
      else
        xmin = Ax - @height * sin
        ymin = Ay

    if rounded
      xmin = Math.round(xmin)
      ymin = Math.round(ymin)

    new Rectangle @x, @y, 2 * (@x - xmin), 2 * (@y - ymin), 0

  distanceToPoint: (p) ->
    # Get p in rect's coordinate space, then operate in one quadrant.

    cos = Math.cos(@rotation)
    sin = Math.sin(@rotation)
    px = (p.x - @x) * cos - (p.y - @y) * sin
    py = (p.x - @x) * sin + (p.y - @y) * cos

    dx = Math.max(Math.abs(px) - @width / 2, 0)
    dy = Math.max(Math.abs(py) - @height / 2, 0)
    Math.sqrt dx * dx + dy * dy

  distanceSquaredToPoint: (p) ->
    # Doesn't handle rotation and is significantly faster than distanceToPoint.
    dx = Math.max(Math.abs(p.x - @x) - @width / 2, 0)
    dy = Math.max(Math.abs(p.y - @y) - @height / 2, 0)
    dx * dx + dy * dy

  distanceToRectangle: (other) ->
    Math.sqrt @distanceSquaredToRectangle other

  distanceSquaredToRectangle: (rect) ->
    return 0 if @intersectsRectangle rect

    distanceSquaredSegmentPoint = (a, b, point) ->
      # Assuming a != b

      t = ((point.x - a.x) * (b.x - a.x) + (point.y - a.y) * (b.y - a.y)) / a.distanceSquared(b)
      return point.distanceSquared a if t <= 0
      return point.distanceSquared b if t >= 1

      dx = point.x - (a.x + t * (b.x - a.x))
      dy = point.y - (a.y + t * (b.y - a.y))
      return dx * dx + dy * dy


    # Find the indices of the point on each rect furthest from the center of the other rect
    # Then, find the minimum distSq of every pair of vertices from one rect and sides from another
    #   excluding all points and sides that are/include the furthest points decided above (12 pairs)

    verts1 = @vertices()
    verts2 = rect.vertices()

    # Index of furthest vertex in verts1
    d0 = Math.pow(verts1[0].x - rect.x, 2) + Math.pow(verts1[0].y - rect.y, 2)
    d1 = Math.pow(verts1[1].x - rect.x, 2) + Math.pow(verts1[1].y - rect.y, 2)
    d2 = Math.pow(verts1[2].x - rect.x, 2) + Math.pow(verts1[2].y - rect.y, 2)
    idx1 = if d0 < d1 then (if d1 < d2 then 2 else 1) else (if d1 < d2 then 3 else 0)

    # Index of furthest vertex in verts2
    d0 = Math.pow(verts2[0].x - @x, 2) + Math.pow(verts2[0].y - @y, 2)
    d1 = Math.pow(verts2[1].x - @x, 2) + Math.pow(verts2[1].y - @y, 2)
    d2 = Math.pow(verts2[2].x - @x, 2) + Math.pow(verts2[2].y - @y, 2)
    idx2 = if d0 < d1 then (if d1 < d2 then 2 else 1) else (if d1 < d2 then 3 else 0)

    minDist = Infinity

    for i in [1..2] # 2 segments per rectangle
      a1 = verts1[(idx1 + i    ) % 4]
      a2 = verts1[(idx1 + i + 1) % 4]
      b1 = verts2[(idx2 + i    ) % 4]
      b2 = verts2[(idx2 + i + 1) % 4]

      for j in [1..3] # 3 points per rectangle
        minDist = Math.min(
          minDist,
          distanceSquaredSegmentPoint(a1, a2, verts2[(idx2 + j) % 4])
          distanceSquaredSegmentPoint(b1, b2, verts1[(idx1 + j) % 4])
        )

    minDist

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
    # Optimized @intersectsRectangle(rect)
    # where rect = Rectangle((p1.x + p2.x) / 2, (p1.y + p2.y) / 2, 0, dist(p1, p2), atan2(p2.x - p1.x, p2.y - p1.y))
    # essentially considers the line segment a zero-width rectangle

    Tx = (p1.x + p2.x) / 2 - @x
    Ty = (p1.y + p2.y) / 2 - @y

    Acos = Math.cos(@rotation)
    Asin = Math.sin(@rotation)
    Axx = -Acos
    Axy =  Asin
    Ayx =  Asin
    Ayy =  Acos

    # B rotation = atan2(p2.x - p1.x, p2.y - p1.y)
    # when r = sqrt(x*x + y*y)
    #   cos(atan2(y, x)) == x / r
    #   sin(atan2(y, x)) == y / r

    dx = p2.x - p1.x
    dy = p2.y - p1.y
    r = dx * dx + dy * dy

    Bcos = dy / r
    Bsin = dx / r
    Bxx = -Bcos
    Bxy =  Bsin
    Byx =  Bsin
    Byy =  Bcos

    Aw = @width  / 2
    Ah = @height / 2
    Bh = r / 2

    not (
      Math.abs(Tx * Axx + Ty * Axy) > Aw + Math.abs((Byx * Bh) * Axx + (Byy * Bh) * Axy) or
      Math.abs(Tx * Ayx + Ty * Ayy) > Ah + Math.abs((Byx * Bh) * Ayx + (Byy * Bh) * Ayy) or
      Math.abs(Tx * Bxx + Ty * Bxy) > Math.abs((Axx * Aw) * Bxx + (Axy * Aw) * Bxy) + Math.abs((Ayx * Ah) * Bxx + (Ayy * Ah) * Bxy) or
      Math.abs(Tx * Byx + Ty * Byy) > Math.abs((Axx * Aw) * Byx + (Axy * Aw) * Byy) + Math.abs((Ayx * Ah) * Byx + (Ayy * Ah) * Byy) + Bh
    )

  intersectsRectangle: (rect) ->
    # "intersects" includes the case when one rectangle is entirely inside another

    # Rectangle-specific form of SAT
    # https://www.jkh.me/files/tutorials/Separating%20Axis%20Theorem%20for%20Oriented%20Bounding%20Boxes.pdf

    Tx = rect.x - @x
    Ty = rect.y - @y

    # Ax = [-1, 0].rotate -@rotation
    # Ay = [ 0, 1].rotate -@rotation
    Acos = Math.cos(@rotation)
    Asin = Math.sin(@rotation)
    Axx = -Acos
    Axy =  Asin
    Ayx =  Asin
    Ayy =  Acos

    # Bx = [-1, 0].rotate -rect.rotation
    # By = [ 0, 1].rotate -rect.rotation
    Bcos = Math.cos(rect.rotation)
    Bsin = Math.sin(rect.rotation)
    Bxx = -Bcos
    Bxy =  Bsin
    Byx =  Bsin
    Byy =  Bcos

    Aw = @width  / 2
    Ah = @height / 2
    Bw = rect.width  / 2
    Bh = rect.height / 2

    not (
      Math.abs(Tx * Axx + Ty * Axy) > Aw + Math.abs((Bxx * Bw) * Axx + (Bxy * Bw) * Axy) + Math.abs((Byx * Bh) * Axx + (Byy * Bh) * Axy) or
      Math.abs(Tx * Ayx + Ty * Ayy) > Ah + Math.abs((Bxx * Bw) * Ayx + (Bxy * Bw) * Ayy) + Math.abs((Byx * Bh) * Ayx + (Byy * Bh) * Ayy) or
      Math.abs(Tx * Bxx + Ty * Bxy) > Math.abs((Axx * Aw) * Bxx + (Axy * Aw) * Bxy) + Math.abs((Ayx * Ah) * Bxx + (Ayy * Ah) * Bxy) + Bw or
      Math.abs(Tx * Byx + Ty * Byy) > Math.abs((Axx * Aw) * Byx + (Axy * Aw) * Byy) + Math.abs((Ayx * Ah) * Byx + (Ayy * Ah) * Byy) + Bh
    )

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

  @fromVertices: (vertices) ->
    # Create a rectangle from a list of vertices. Inverse of @vertices()
    [a, b, c, d] = vertices

    p1 = new Vector (a.x + d.x) / 2, (a.y + d.y) / 2
    p2 = new Vector (b.x + c.x) / 2, (b.y + c.y) / 2

    new Rectangle(
      (p1.x + p2.x) / 2,
      (p1.y + p2.y) / 2,
      p1.distance(a) * 2,
      p1.distance(p2),
      Math.atan2(p2.x - p1.x, p2.y - p1.y)
    )

  @equals: (a, b) ->
    # Tests if two rectangles' x, y, width, heigth, and rotation are exactly equal
    a.x == b.x and a.y == b.y and a.width == b.width and a.height == b.height and a.rotation == b.rotation

  @equalsByVertices: (a, b) ->
    # Tests if a.vertices() and b.vertices() are exactly equal (same order, same x and y values)
    v1 = a.vertices()
    v2 = b.vertices()
    v1.every((v, i) -> v.x == v2[i].x && v.y == v2[i].y)

  @approxEquals: (a, b, epsilon=1e-13) ->
    # Tests if the difference between two rectangles' x, y, width, heigth, and rotation are all within epsilon
    Math.abs(a.x        - b.x       ) < epsilon and
    Math.abs(a.y        - b.y       ) < epsilon and
    Math.abs(a.width    - b.width   ) < epsilon and
    Math.abs(a.height   - b.height  ) < epsilon and
    Math.abs(a.rotation - b.rotation) < epsilon

  @approxEqualsByVertices: (a, b, epsilon=1e-13) ->
    # Tests if every vertex in a.vertices() and b.vertices() are within epsilon x-wise and y-wise
    # Requires vertices to be in the same order
    v1 = a.vertices()
    v2 = b.vertices()

    v1.every((v, i) ->
      Math.abs(v.x - v2[i].x) < epsilon and
      Math.abs(v.y - v2[i].y) < epsilon
    )

module.exports = Rectangle
