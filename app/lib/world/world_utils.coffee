Vector = require './vector'
Rectangle = require './rectangle'
Ellipse = require './ellipse'
LineSegment = require './line_segment'
Grid = require './Grid'

module.exports.typedArraySupport = typedArraySupport = Float32Array?  # Not in IE until IE 10; we'll fall back to normal arrays
#module.exports.typedArraySupport = typedArraySupport = false  # imitate IE9 (and in God.coffee)

unless ArrayBufferView?
  # https://code.google.com/p/chromium/issues/detail?id=60449
  if typedArraySupport
    # We have it, it's just not exposed
    someArray = new Uint8Array(0)
    if someArray.__proto__
      # Most browsers
      ArrayBufferView = someArray.__proto__.__proto__.constructor
    else
      # IE before 11
      ArrayBufferView = Object.getPrototypeOf(Object.getPrototypeOf(someArray)).constructor
  else
    # If we don't have typed arrays, we don't need an ArrayBufferView
    ArrayBufferView = null

module.exports.clone = clone = (obj, skipThangs=false) ->
  # http://coffeescriptcookbook.com/chapters/classes_and_objects/cloning
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime())

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags)

  if (obj instanceof Vector) or (obj instanceof Rectangle) or (obj instanceof Ellipse) or (obj instanceof LineSegment)
    return obj.copy()

  if skipThangs and obj.isThang
    return obj

  if _.isArray obj
    return obj.slice()

  if ArrayBufferView and obj instanceof ArrayBufferView
    return new obj.constructor obj

  newInstance = new obj.constructor()
  for key of obj
    newInstance[key] = clone obj[key], skipThangs

  newInstance

# Walk a key chain down to the value. Can optionally set newValue instead.
module.exports.downTheChain = downTheChain = (obj, keyChain, newValue=undefined) ->
  return null unless obj
  return obj[keyChain] unless _.isArray keyChain
  value = obj
  while keyChain.length and value
    if newValue isnt undefined and keyChain.length is 1
      value[keyChain[0]] = newValue
      return newValue
    value = value[keyChain[0]]
    keyChain = keyChain[1..]
  return value

module.exports.now = (if window?.performance?.now? then (-> window.performance.now()) else (-> new Date()))

module.exports.consolidateThangs = consolidateThangs = (thangs) ->
  # We can gain a performance increase by consolidating all regular walls into a minimal covering, non-intersecting set a la Gridmancer.
  debug = false
  isStructural = (t) ->
    t.stateless and t.collides and t.collisionCategory is 'obstacles' and t.shape in ['box', 'sheet'] and  # Can only do wall-like obstacle Thangs.
    t.spriteName isnt 'Ice Wall' and t.restitution is 1.0 and  # Fixed restitution value on 2016-03-15, but it causes discrepancies, so disabled for Kelvintaph levels.
    /Wall/.test(t.spriteName) and  # Not useful to do Thangs that aren't actually walls because they're usually not on a grid
    (t.pos.x - t.width / 2 >= 0) and (t.pos.y - t.height / 2 >= 0)  # Grid doesn't handle negative numbers, so don't coalesce walls below/left of 0, 0.
  structural = _.remove thangs, isStructural
  return unless structural.length
  rightmost = _.max structural, (t) -> t.pos.x + t.width / 2
  topmost = _.max structural, (t) -> t.pos.y + t.height / 2
  leftmost = _.min structural, (t) -> t.pos.x - t.width / 2
  bottommost = _.min structural, (t) -> t.pos.y - t.height / 2
  console.log 'got rightmost', rightmost.id, 'topmost', topmost.id, 'lefmostmost', leftmost.id, 'bottommost', bottommost.id, 'out of', structural.length, 'structural thangs' if debug
  left = Math.min 0, leftmost.pos.x - leftmost.width / 2
  bottom = Math.min 0, bottommost.pos.y - bottommost.height / 2
  if (left < 0) or (bottom < 0)
    console.error 'Negative structural Thangs aren\'t supported, sorry!'  # TODO: largestRectangle, AI System, and anything else that accesses grid directly need updating to finish this
  left = 0
  bottom = 0
  width = rightmost.pos.x + rightmost.width / 2 - left
  height = topmost.pos.y + topmost.height / 2 - bottom
  padding = 0
  console.log 'got max width', width, 'height', height, 'left', left, 'bottom', bottom, 'of thangs', thangs.length, 'structural', structural.length if debug
  grid = new Grid structural, width, height, padding, left, bottom

  dissection = []
  addStructuralThang = (rect) ->
    thang = structural[dissection.length]  # Grab one we already know is configured properly.
    console.error 'Hmm, our dissection has more Thangs than the original structural Thangs?', dissection.length unless thang
    thang.pos.x = rect.x
    thang.pos.y = rect.y
    thang.width = rect.width
    thang.height = rect.height
    thang.destroyBody()
    thang.createBodyDef()
    thang.createBody()
    dissection.push thang

  dissectRectangles grid, addStructuralThang, false, debug

  # Now add the new structural thangs back to thangs and return the ones not in the dissection.
  console.log 'Turned', structural.length, 'structural Thangs into', dissection.length, 'dissecting Thangs.'
  thangs.push dissection...
  structural[dissection.length ... structural.length]


module.exports.dissectRectangles = dissectRectangles = (grid, rectangleCallback, wantEmpty, debug) ->
  # Mark Maxham's fast sweeper approach: https://github.com/codecombat/codecombat/issues/1090
  console.log grid.toString() if debug
  for x in grid.rows grid.left, grid.left + grid.width
    y = grid.clampColumn grid.bottom
    while y < grid.clampColumn grid.bottom + grid.height
      y2 = y  # Note our current y.
      ++y2 until occ x, y2, grid, wantEmpty  # Sweep through y to expand 1xN rect.
      if y2 > y  # If we get a hit, sweep X with that swath.
        x2 = x + 1
        ++x2 until occCol x2, y, y2, grid, wantEmpty
        w = x2 - x
        h = y2 - y
        rect = addRect grid, x, y, w, h, wantEmpty
        rectangleCallback rect
        console.log grid.toString() if debug
        y = y2
      ++y

occ = (x, y, grid, wantEmpty) ->
  return true if y > grid.bottom + grid.height or x > grid.left + grid.width
  console.error 'trying to check invalid coordinates', x, y, 'from grid', grid.bottom, grid.left, grid.width, grid.height unless grid.grid[y]?[x]
  Boolean(grid.grid[y][x].length) is wantEmpty

occCol = (x, y1, y2, grid, wantEmpty) ->
  for j in [y1 ... y2]
    if occ(x, j, grid, wantEmpty)
      return true
  false

addRect = (grid, leftX, bottomY, width, height, wantEmpty) ->
  for x in [leftX ... leftX + width]
    for y in [bottomY ... bottomY + height]
      grid.grid[y][x] = if wantEmpty then [true] else []
  new Rectangle leftX + width / 2, bottomY + height / 2, width, height
