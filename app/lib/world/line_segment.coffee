class LineSegment
  @className: "LineSegment"

  constructor: (@a, @b) ->
    @slope = (@a.y - @b.y) / (@a.x - @b.x)
    @y0 = @a.y - (@slope * @a.x)
    @left = if @a.x < @b.x then @a else @b
    @right = if @a.x > @b.x then @a else @b
    @bottom = if @a.y < @b.y then @a else @b
    @top = if @a.y > @b.y then @a else @b

  y: (x) ->
    (@slope * x) + @y0

  x: (y) ->
    (y - @y0) / @slope

  intersectsLineSegment: (lineSegment) ->
    if lineSegment.slope is @slope
      if lineSegment.y0 is @y0
        if lineSegment.left.x is @left.x or lineSegment.left.x is @right.x or lineSegment.right.x is @right.x or lineSegment.right.x is @left.x
          # Special case then segments are vertical both and have the same 'x'
          if Math.abs(@slope) is Infinity
            return (@bottom.y <= lineSegment.top.y <= @top.y) or (lineSegment.bottom.y <= @top.y <= lineSegment.top.y)
          else
            # segments are of the same line with shared start and/or end points
            return true
        else
          [left, right] = if lineSegment.left.x < @left.x then [lineSegment, @] else [@, lineSegment]
          if left.right.x > right.left.x
            # segments are of the same line and one is contained within the other
            return true
    else if Math.abs(@slope) isnt Infinity and Math.abs(lineSegment.slope) isnt Infinity
      x = (lineSegment.y0 - @y0) / (@slope - lineSegment.slope)
      if x >= @left.x and x <= @right.x and x >= lineSegment.left.x and x <= lineSegment.right.x
        return true
    else if Math.abs(@slope) isnt Infinity or Math.abs(lineSegment.slope) isnt Infinity
      [vertical, nonvertical] = if Math.abs(@slope) isnt Infinity then [lineSegment, @] else [@, lineSegment]
      x = vertical.a.x
      bottom = vertical.bottom.y
      top = vertical.top.y
      y = nonvertical.y(x)
      left = nonvertical.left.x
      right = nonvertical.right.x
      if y >= bottom and y <= top and x >= left and x <= right
        return true
    false

  pointOnLine: (point, segment=true) ->
    if point.y is @y(point.x)
      if segment
        [littleY, bigY] = if @a.y < @b.y then [@a.y, @b.y] else [@b.y, @a.y]
        if littleY <= point.y and bigY >= point.y
          return true
      else
        return true
    false

  distanceSquaredToPoint: (point) ->
    # http://stackoverflow.com/a/1501725/540620
    return @a.distanceSquared point if @a.equals @b
    res = Math.min point.distanceSquared(@a), point.distanceSquared(@b)
    lineMagnitudeSquared = @a.distanceSquared @b
    t = ((point.x - @a.x) * (@b.x - @a.x) + (point.y - @a.y) * (@b.y - @a.y)) / lineMagnitudeSquared
    return @a.distanceSquared point if t < 0
    return @b.distanceSquared point if t > 1
    point.distanceSquared x: @a.x + t * (@b.x - @a.x), y: @a.y + t * (@b.y - @a.y)

  distanceToPoint: (point) ->
    Math.sqrt @distanceSquaredToPoint point

  toString: ->
    "lineSegment(a=#{@a}, b=#{@b}, slope=#{@slope}, y0=#{@y0}, left=#{@left}, right=#{@right}, bottom=#{@bottom}, top=#{@top})"

  serialize: ->
    {CN: @constructor.className, a: @a, b: @b}

  @deserialize: (o, world, classMap) ->
    new LineSegment o.a, o.b

  serializeForAether: -> @serialize()
  @deserializeFromAether: (o) -> @deserialize o

module.exports = LineSegment
