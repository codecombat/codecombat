# https://github.com/hornairs/blog/blob/master/assets/coffeescripts/flocking/vector.coffee
class Vector
  @className: 'Vector'
  # Class methods for nondestructively operating
  for name in ['add', 'subtract', 'multiply', 'divide', 'limit', 'normalize', 'rotate']
    do (name) ->
      Vector[name] = (a, b, useZ) ->
        a.copy()[name](b, useZ)
  for name in ['magnitude', 'heading', 'distance', 'dot', 'equals', 'copy', 'distanceSquared']
    do (name) ->
      Vector[name] = (a, b, useZ) ->
        a[name](b, useZ)

  isVector: true
  apiProperties: ['x', 'y', 'z', 'magnitude', 'heading', 'distance', 'dot', 'equals', 'copy', 'distanceSquared', 'add', 'subtract', 'multiply', 'divide', 'limit', 'normalize', 'rotate']

  constructor: (x=0, y=0, z=0) ->
    return new Vector x, y, z unless @ instanceof Vector
    [@x, @y, @z] = [x, y, z]

  copy: ->
    new Vector(@x, @y, @z)


  # Mutating methods:

  normalize: (useZ) ->
    m = @magnitude useZ
    @divide m, useZ if m > 0
    @

  esper_normalize: (useZ) ->
    @copy().normalize(useZ)

  limit: (max) ->
    if @magnitude() > max
      @normalize()
      @multiply(max)
    else
      @

  esper_limit: (max) ->
    @copy().limit(max)

  subtract: (other, useZ) ->
    @x -= other.x
    @y -= other.y
    @z -= other.z if useZ
    @

  esper_subtract: (other, useZ) ->
    @copy().subtract(other, useZ)

  add: (other, useZ) ->
    @x += other.x
    @y += other.y
    @z += other.z if useZ
    @

  esper_add: (other, useZ) ->
    @copy().add(other, useZ)

  divide: (n, useZ) ->
    [@x, @y] = [@x / n, @y / n]
    @z = @z / n if useZ
    @

  esper_divide: (n, useZ) ->
    @copy().divide(n, useZ)

  multiply: (n, useZ) ->
    [@x, @y] = [@x * n, @y * n]
    @z = @z * n if useZ
    @

  esper_multiply: (n, useZ) ->
    @copy().multiply(n, useZ)

  # Rotate it around the origin
  # If we ever want to make this also use z: https://en.wikipedia.org/wiki/Axes_conventions
  rotate: (theta) ->
    return @ unless theta
    [@x, @y] = [Math.cos(theta) * @x - Math.sin(theta) * @y, Math.sin(theta) * @x + Math.cos(theta) * @y]
    @

  esper_rotate: (theta) ->
    @copy().rotate(theta)

  # Non-mutating methods:

  magnitude: (useZ) ->
    sum = @x * @x + @y * @y
    sum += @z * @z if useZ
    Math.sqrt sum

  magnitudeSquared: (useZ) ->
    sum = @x * @x + @y * @y
    sum += @z * @z if useZ
    sum

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

  dot: (other, useZ) ->
    sum = @x * other.x + @y * other.y
    sum += @z * other.z if useZ
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

  invalid: () ->
    return (@x is Infinity) || isNaN(@x) || @y is Infinity || isNaN(@y) || @z is Infinity || isNaN(@z)

  toString: (precision = 2) ->
    return "{x: #{@x.toFixed(precision)}, y: #{@y.toFixed(precision)}, z: #{@z.toFixed(precision)}}"


  serialize: ->
    {CN: @constructor.className, x: @x, y: @y, z: @z}

  @deserialize: (o, world, classMap) ->
    new Vector o.x, o.y, o.z

  serializeForAether: -> @serialize()
  @deserializeFromAether: (o) -> @deserialize o

module.exports = Vector
