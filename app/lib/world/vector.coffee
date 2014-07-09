# https://github.com/hornairs/blog/blob/master/assets/coffeescripts/flocking/vector.coffee
class Vector
  @className: 'Vector'
  # Class methods for nondestructively operating
  for name in ['add', 'subtract', 'multiply', 'divide', 'limit', 'normalize']
    do (name) ->
      Vector[name] = (a, b, useZ) ->
        a.copy()[name](b, useZ)

  isVector: true
  apiProperties: ['x', 'y', 'z', 'magnitude', 'heading', 'distance', 'dot', 'equals', 'copy', 'distanceSquared']

  constructor: (@x=0, @y=0, @z=0) ->

  copy: ->
    new Vector(@x, @y, @z)

  magnitude: (useZ) ->
    sum = @x * @x + @y * @y
    sum += @z * @z if useZ
    Math.sqrt sum

  magnitudeSquared: (useZ) ->
    sum = @x * @x + @y * @y
    sum += @z * @z if useZ
    sum

  normalize: (useZ) ->
    m = @magnitude useZ
    @divide m, useZ if m > 0
    @

  limit: (max) ->
    if @magnitude() > max
      @normalize()
      return @multiply(max)
    else
      @

  heading: ->
    -1 * Math.atan2(-1 * @y, @x)

  distance: (other, useZ) ->
    dx = @x - other.x
    dy = @y - other.y
    sum = dx * dx + dy * dy
    if useZ
      dz = @z - other.z
      sum += dz * dz
    Math.sqrt sum

  distanceSquared: (other, useZ) ->
    dx = @x - other.x
    dy = @y - other.y
    sum = dx * dx + dy * dy
    if useZ
      dz = @z - other.z
      sum += dz * dz
    sum

  subtract: (other, useZ) ->
    @x -= other.x
    @y -= other.y
    @z -= other.z if useZ
    @

  add: (other, useZ) ->
    @x += other.x
    @y += other.y
    @z += other.z if useZ
    @

  divide: (n, useZ) ->
    [@x, @y] = [@x / n, @y / n]
    @z = @z / n if useZ
    @

  multiply: (n, useZ) ->
    [@x, @y] = [@x * n, @y * n]
    @z = @z * n if useZ
    @

  dot: (other, useZ) ->
    sum = @x * other.x + @y * other.y
    sum += @z + other.z if useZ
    sum

  # Not the strict projection, the other isn't converted to a unit vector first.
  projectOnto: (other, useZ) ->
    other.copy().multiply(@dot(other, useZ), useZ)

  isZero: (useZ) ->
    result = @x is 0 and @y is 0
    result = result and @z is 0 if useZ
    result

  equals: (other, useZ) ->
    result = other and @x is other.x and @y is other.y
    result = result and @z is other.z if useZ
    result

  # Rotate it around the origin
  # If we ever want to make this also use z: https://en.wikipedia.org/wiki/Axes_conventions
  rotate: (theta) ->
    return @ unless theta
    [@x, @y] = [Math.cos(theta) * @x - Math.sin(theta) * @y, Math.sin(theta) * @x + Math.cos(theta) * @y]
    @

  invalid: () ->
    return (@x is Infinity) || isNaN(@x) || @y is Infinity || isNaN(@y) || @z is Infinity || isNaN(@z)

  toString: (useZ) ->
    useZ = true
    return "{x: #{@x.toFixed(0)}, y: #{@y.toFixed(0)}, z: #{@z.toFixed(0)}}" if useZ
    return "{x: #{@x.toFixed(0)}, y: #{@y.toFixed(0)}}"

  serialize: ->
    {CN: @constructor.className, x: @x, y: @y, z: @z}

  @deserialize: (o, world, classMap) ->
    new Vector o.x, o.y, o.z

  serializeForAether: -> @serialize()
  @deserializeFromAether: (o) -> @deserialize o

module.exports = Vector
