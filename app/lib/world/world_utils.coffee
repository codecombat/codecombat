Vector = require './vector'
Rectangle = require './rectangle'
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

  if (obj instanceof Vector) or (obj instanceof Rectangle)
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
  debug = false
  isStructural = (t) -> t.stateless and t.collides and t.collisionCategory is 'obstacles' and t.shape in ['box', 'sheet'] and t.restitution is 1.5 and (t.pos.x - t.width / 2 >= 0) and (t.pos.y - t.height / 2 >= 0)
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
  console.log grid.toString() if debug

  # Approach: start at bottom left. Go right, then up. At each occupied grid square, find the largest rectangle we can make starting at that corner, add a corresponding Thang to the grid, and unmark all occupied grid squares.
  # Since it's not like we're going to do any of these:
  # http://stackoverflow.com/questions/5919298/algorithm-for-finding-the-fewest-rectangles-to-cover-a-set-of-rectangles
  # http://stackoverflow.com/questions/4701887/find-the-set-of-largest-contiguous-rectangles-to-cover-multiple-areas
  dissection = []
  for y in grid.columns bottom, height
    for x in grid.rows left, width
      continue unless grid.grid[y][x].length
      rect = largestRectangle grid, y, x, false, debug
      vertices = rect.vertices()
      for y2 in [vertices[0].y ... vertices[1].y]  # maybe ..?
        for x2 in [vertices[0].x ... vertices[2].x]  # maybe ..?
          grid.grid[y2][x2] = []
      console.log grid.toString() if debug
      thang = structural[dissection.length]  # grab one we already know is configured properly
      console.error 'Hmm, our dissection has more Thangs than the original structural Thangs?', dissection.length unless thang
      thang.width = rect.width
      thang.height = rect.height
      thang.pos.x = rect.x
      thang.pos.y = rect.y
      thang.createBodyDef()
      dissection.push thang
  console.log 'Turned', structural.length, 'structural Thangs into', dissection.length, 'dissecting Thangs.'
  thangs.push dissection...
  structural[dissection.length ... structural.length]

module.exports.largestRectangle = largestRectangle = (grid, bottomY, leftX, wantEmpty, debug) ->
  # If wantEmpty, then we try to cover empty rectangles.
  # Otherwise, we try to cover occupied rectangles.
  coveredRows = []
  shortestCoveredRow = grid.width - leftX
  for y in grid.columns bottomY, grid.height
    coveredRow = 0
    for x in grid.rows leftX, leftX + shortestCoveredRow
      if Boolean(grid.grid[y][x].length) isnt wantEmpty
        ++coveredRow
      else
        break
    break unless coveredRow
    coveredRows.push coveredRow
    shortestCoveredRow = Math.min(shortestCoveredRow, coveredRow)
  console.log 'largestRectangle() for', bottomY, leftX, 'got coveredRows', coveredRows if debug
  [maxArea, maxAreaRows, maxAreaRowLength, shortestRow] = [0, 0, 0, 0]
  for rowLength, rowIndex in coveredRows
    shortestRow ||= rowLength
    area = rowLength * (rowIndex + 1)
    if area > maxArea
      maxAreaRows = rowIndex + 1
      maxAreaRowLength = shortestRow
      maxArea = area
    shortestRow = Math.min(rowLength, shortestRow)
  console.log 'So largest rect has area', maxArea, 'with', maxAreaRows, 'rows of length', maxAreaRowLength if debug
  rect = new Rectangle leftX + maxAreaRowLength / 2, bottomY + maxAreaRows / 2, maxAreaRowLength, maxAreaRows
  console.log 'That corresponds to a rectangle', rect.toString() if debug
  rect
