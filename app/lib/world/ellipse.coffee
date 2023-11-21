Vector = require './vector'
LineSegment = require './line_segment'
Rectangle = require './rectangle'

class Ellipse
  @className: "Ellipse"

  # TODO: add class methods for add, multiply, subtract, divide, rotate

  isEllipse: true
  apiProperties: ['x', 'y', 'width', 'height', 'rotation', 'distanceToPoint', 'distanceSquaredToPoint', 'distanceToRectangle', 'distanceSquaredToRectangle', 'distanceToEllipse', 'distanceSquaredToEllipse', 'distanceToShape', 'distanceSquaredToShape', 'containsPoint', 'intersectsLineSegment', 'intersectsRectangle', 'intersectsEllipse', 'getPos', 'containsPoint', 'copy']

  constructor: (@x=0, @y=0, @width=0, @height=0, @rotation=0) ->

  copy: ->
    new Ellipse(@x, @y, @width, @height, @rotation)

  getPos: ->
    new Vector(@x, @y)

  rectangle: ->
    new Rectangle(@x, @y, @width, @height, @rotation)

  axisAlignedBoundingBox: (rounded=true) ->
    @rectangle().axisAlignedBoundingBox()

  distanceToPoint: (p) ->
    @rectangle().distanceToPoint p  # TODO: actually implement ellipse ellipse-point distance

  distanceSquaredToPoint: (p) ->
    # Doesn't handle rotation; just supposed to be faster than distanceToPoint.
    @rectangle().distanceSquaredToPoint p  # TODO: actually implement ellipse-point distance

  distanceToRectangle: (other) ->
    Math.sqrt @distanceSquaredToRectangle other

  distanceSquaredToRectangle: (other) ->
    @rectangle().distanceSquaredToRectangle other  # TODO: actually implement ellipse-rectangle distance

  distanceToEllipse: (ellipse) ->
    Math.sqrt @distanceSquaredToEllipse ellipse

  distanceSquaredToEllipse: (ellipse) ->
    @rectangle().distanceSquaredToEllipse ellipse  # TODO: actually implement ellipse-ellipse distance

  distanceToShape: (shape) ->
    Math.sqrt @distanceSquaredToShape shape

  distanceSquaredToShape: (shape) ->
    if shape.isEllipse then @distanceSquaredToEllipse shape else @distanceSquaredToRectangle shape

  containsPoint: (p, withRotation=true) ->
    # "ellipse space" is the cartesian space
    # where the ellipse becomes the unit
    # circle centered at (0, 0)
    [x, y] = [p.x - @x, p.y - @y] # translate point into ellipse space
    if withRotation and @rotation # optionally rotate point into ellipse space
      c = Math.cos(@rotation)
      s = Math.sin(@rotation)
      [x, y] = [x*c + y*s, y*c - x*s]
    x = x / @width * 2 # scale point into ellipse space
    y = y / @height * 2
    x*x + y*y <= 1 #if the resulting point falls on/in the unit circle at 0, 0


  intersectsLineSegment: (p1, p2) ->
    [px1, py1, px2, py2] = [p1.x, p1.y, p2.x, p2.y]
    m = (py1 - py2) / (px1 - px2)
    m2 = Math.pow(m, 2)
    c = py1 - (m * px1)
    c2 = Math.pow(c, 2)
    [a, b] = [@width / 2, @height / 2]
    [h, k] = [@x, @y]
    a2 = Math.pow(a, 2)
    a4 = Math.pow(a, 2)
    b2 = Math.pow(b, 2)
    b4 = Math.pow(b, 4)
    h2 = Math.pow(h, 2)
    k2 = Math.pow(k, 2)
    sint = Math.sin(@rotation)
    sin2t = Math.sin(2 * @rotation)
    cost = Math.cos(@rotation)
    cos2t = Math.cos(2 * @rotation)
    if (not isNaN m) and m != Infinity and m != -Infinity
      numeratorLeft = (-a2 * c * m * cos2t) - (a2 * c * m) + (a2 * c * sin2t) - (a2 * h * m * sin2t) - (a2 * h * cos2t) + (a2 * h) + (a2 * k * m * cos2t) + (a2 * k * m) - (a2 * k * sin2t)
      numeratorMiddle = Math.SQRT2 * Math.sqrt((a4 * b2 * m2 * cos2t) + (a4 * b2 * m2) - (2 * a4 * b2 * m * sin2t) - (a4 * b2 * cos2t) + (a4 * b2) - (a2 * b4 * m2 * cos2t) + (a2 * b4 * m2) + (2 * a2 * b4 * m * sin2t) + (a2 * b4 * cos2t) + (a2 * b4) - (2 * a2 * b2 * c2) - (4 * a2 * b2 * c * h * m) + (4 * a2 * b2 * c * k) - (2 * a2 * b2 * h2 * m2) + (4 * a2 * b2 * h * k * m) - (2 * a2 * b2 * k2))
      numeratorRight = (b2 * c * m * cos2t) - (b2 * c * m) - (b2 * c * sin2t) + (b2 * h * m * sin2t) + (b2 * h * cos2t) + (b2 * h) - (b2 * k * m * cos2t) + (b2 * k * m) + (b2 * k * sin2t)
      denominator = (a2 * m2 * cos2t) + (a2 * m2) - (2 * a2 * m * sin2t) - (a2 * cos2t) + a2 - (b2 * m2 * cos2t) + (b2 * m2) + (2 * b2 * m * sin2t) + (b2 * cos2t) + b2
      solution1 = (-numeratorLeft - numeratorMiddle + numeratorRight) / denominator
      solution2 = (-numeratorLeft + numeratorMiddle + numeratorRight) / denominator
      if (not isNaN solution1) and (not isNaN solution2)
        [littleX, bigX] = if px1 < px2 then [px1, px2] else [px2, px1]
        if (littleX <= solution1 and bigX >= solution1) or (littleX <= solution2 and bigX >= solution2)
          return true
      if (not isNaN solution1) or (not isNaN solution2)
        solution = if not isNaN solution1 then solution1 else solution2
        [littleX, bigX] = if px1 < px2 then [px1, px2] else [px2, px1]
        if littleX <= solution and bigX >= solution
          return true
      else
        return false
    else
      x = px1
      x2 = Math.pow(x, 2)
      numeratorLeft = (-a2 * h * sin2t) + (a2 * k * cos2t) + (a2 * k) + (a2 * x * sin2t)
      numeratorMiddle = Math.SQRT2 * Math.sqrt((a4 * b2 * cos2t) + (a4 * b2) - (a2 * b4 * cos2t) + (a2 * b4) - (2 * a2 * b2 * h2) + (4 * a2 * b2 * h * x) - (2 * a2 * b2 * x2))
      numeratorRight = (b2 * h * sin2t) - (b2 * k * cos2t) + (b2 * k) - (b2 * x * sin2t)
      denominator = (a2 * cos2t) + a2 - (b2 * cos2t) + b2
      solution1 = (numeratorLeft - numeratorMiddle + numeratorRight) / denominator
      solution2 = (numeratorLeft + numeratorMiddle + numeratorRight) / denominator
      if (not isNaN solution1) or (not isNaN solution2)
        solution = if not isNaN solution1 then solution1 else solution2
        [littleY, bigY] = if py1 < py2 then [py1, py2] else [py2, py1]
        if littleY <= solution and bigY >= solution
          return true
      else
        return false
    false

  intersectsRectangle: (rectangle) ->
    rectangle.intersectsEllipse @

  intersectsEllipse: (ellipse) ->
    @rectangle().intersectsEllipse ellipse  # TODO: actually implement ellipse-ellipse intersection
    #return true if @containsPoint ellipse.getPos()

  intersectsShape: (shape) ->
    if shape.isEllipse then @intersectsEllipse shape else @intersectsRectangle shape

  toString: ->
    return "{x: #{@x.toFixed(0)}, y: #{@y.toFixed(0)}, w: #{@width.toFixed(0)}, h: #{@height.toFixed(0)}, rot: #{@rotation.toFixed(3)}}"

  serialize: ->
    {CN: @constructor.className, x: @x, y: @y, w: @width, h: @height, r: @rotation}

  @deserialize: (o, world, classMap) ->
    new Ellipse o.x, o.y, o.w, o.h, o.r

  serializeForAether: -> @serialize()
  @deserializeFromAether: (o) -> @deserialize o

module.exports = Ellipse
