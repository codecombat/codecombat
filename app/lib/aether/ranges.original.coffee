module.exports.offsetToPos = offsetToPos = (offset, source, prefix='') ->
  rowOffsets = buildRowOffsets source, prefix
  offset -= prefix.length
  row = offsetToRow offset, rowOffsets
  col = offset - rowOffsets[row]
  {ofs: offset, row: row, col: col}

module.exports.offsetsToRange = offsetsToRange = (start, end, source, prefix='') ->
  start: offsetToPos(start, source, prefix), end: offsetToPos(end, source, prefix)

module.exports.rowColToPos = rowColToPos = (row, col, source, prefix='') ->
  rowOffsets = buildRowOffsets source, prefix
  offset = rowOffsets[row] + col
  {ofs: offset, row: row, col: col}

module.exports.rowColsToRange = rowColsToRange = (start, end, source, prefix='') ->
  start: rowColToPos(start.row, start.col, source, prefix), end: rowColToPos(end.row, end.col, source, prefix)

module.exports.locToPos = locToPos = (loc, source, prefix='') ->
  rowColToPos loc.line, loc.column, source, prefix

module.exports.locsToRange = locsToRange = (start, end, source, prefix='') ->
  start: locToPos(start, source, prefix), end: locToPos(end, source, prefix)

module.exports.stringifyPos = stringifyPos = (pos) ->
  "{ofs: #{pos.ofs}, row: #{pos.row}, col: #{pos.col}}"

module.exports.stringifyRange = stringifyRange = (start, end) ->
  "[#{stringifyPos start}, #{stringifyPos end}]"

# Since we're probably going to be searching the same source many times in a row,
# this simple form of caching should get the job done.
lastRowOffsets = null
lastRowOffsetsSource = null
lastRowOffsetsPrefix = null
buildRowOffsets = (source, prefix='') ->
  return lastRowOffsets if source is lastRowOffsetsSource and prefix is lastRowOffsetsPrefix
  rowOffsets = [0]
  for c, offset in source.substr prefix.length
    if c is '\n'
      rowOffsets.push offset+1
  lastRowOffsets = rowOffsets
  lastRowOffsetsSource = source
  lastRowOffsetsPrefix = prefix
  rowOffsets

# Fast version using binary search
offsetToRow = (offset, rowOffsets) ->
  alen = rowOffsets.length
  return 0 if offset <= 0  # First row
  return alen - 1 if offset >= rowOffsets[alen - 1]  # Last row
  lo = 0
  hi = alen - 1
  while lo < hi
    mid = ~~((hi + lo) / 2)  # ~~ is a faster, better Math.floor()
    return mid if offset >= rowOffsets[mid] and offset < rowOffsets[mid + 1]
    if offset < rowOffsets[mid]
      hi = mid
    else
      lo = mid
  throw new Error "Bug in offsetToRow()"
