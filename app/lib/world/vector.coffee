# https://github.com/hornairs/blog/blob/master/assets/coffeescripts/flocking/vector.coffee
class Vector
  @className: 'Vector'
  # Class methods for nondestructively operating
  for name in ['add', 'subtract', 'multiply', 'divide', 'limit', 'normalize', 'rotate']
    do (name) ->
      Vector[name] = (a, b, useZ) ->
        a.copy()["#{name}Self"](b, useZ)
  for name in ['magnitude', 'heading', 'distance', 'dot', 'equals', 'copy', 'distanceSquared']
    do (name) ->
      Vector[name] = (a, b, useZ) ->
        a[name](b, useZ)

  isVector: true
  apiProperties: ['x', 'y', 'z', 'magnitude', 'heading', 'distance', 'dot', 'equals', 'copy', 'distanceSquared', 'rotate', 'add', 'subtract', 'multiply', 'divide', 'limit', 'normalize', 'rotate']

  constructor: (x=0, y=0, z=0) ->
    return new Vector x, y, z unless @ instanceof Vector
    [@x, @y, @z] = [x, y, z]

  copy: ->
    new Vector(@x, @y, @z)


  # Mutating methods:

  normalizeSelf: (useZ) ->
    m = @magnitude useZ
    @divideSelf m, useZ if m > 0
    @

  normalize: (useZ) ->
    # Hack to detect when we are in player code so we can avoid mutation
    (if @__aetherAPIValue? then @copy() else @).normalizeSelf(useZ)

  limitSelf: (max) ->
    if @magnitude() > max
      @normalizeSelf()
      @multiplySelf(max)
    else
      @

  limit: (useZ) ->
    (if @__aetherAPIValue? then @copy() else @).limitSelf(useZ)

  subtractSelf: (other, useZ) ->
    @x -= other.x
    @y -= other.y
    @z -= other.z if useZ
    @

  subtract: (other, useZ) ->
    (if @__aetherAPIValue? then @copy() else @).subtractSelf(other, useZ)

  addSelf: (other, useZ) ->
    @x += other.x
    @y += other.y
    @z += other.z if useZ
    @

  add: (other, useZ) ->
    (if @__aetherAPIValue? then @copy() else @).addSelf(other, useZ)

  divideSelf: (n, useZ) ->
    [@x, @y] = [@x / n, @y / n]
    @z = @z / n if useZ
    @

  divide: (n, useZ) ->
    (if @__aetherAPIValue? then @copy() else @).divideSelf(n, useZ)

  multiplySelf: (n, useZ) ->
    [@x, @y] = [@x * n, @y * n]
    @z = @z * n if useZ
    @

  multiply: (n, useZ) ->
    (if @__aetherAPIValue? then @copy() else @).multiplySelf(n, useZ)

  # Rotate it around the origin
  # If we ever want to make this also use z: https://en.wikipedia.org/wiki/Axes_conventions
  rotateSelf: (theta) ->
    return @ unless theta
    [@x, @y] = [Math.cos(theta) * @x - Math.sin(theta) * @y, Math.sin(theta) * @x + Math.cos(theta) * @y]
    @

  rotate: (theta) ->
    (if @__aetherAPIValue? then @copy() else @).rotateSelf(theta)

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
    sum += @z + other.z if useZ
    sum

  # Not the strict projection, the other isn't converted to a unit vector first.
  projectOnto: (other, useZ) ->
    other.copy().multiplySelf(@dot(other, useZ), useZ)

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
