// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let locsToRange, locToPos, offsetsToRange, offsetToPos, rowColsToRange, rowColToPos, stringifyPos, stringifyRange

module.exports.offsetToPos = offsetToPos = function (offset, source, prefix = '') {
  const rowOffsets = buildRowOffsets(source, prefix)
  offset -= prefix.length
  const row = offsetToRow(offset, rowOffsets)
  const col = offset - rowOffsets[row]
  return {
    ofs: offset,
    row: row,
    col: col
  }
}

module.exports.offsetsToRange = offsetsToRange = function (start, end, source, prefix = '') {
  return {
    start: offsetToPos(start, source, prefix),
    end: offsetToPos(end, source, prefix)
  }
}

module.exports.rowColToPos = rowColToPos = function (row, col, source, prefix = '') {
  const rowOffsets = buildRowOffsets(source, prefix)
  const offset = rowOffsets[row] + col
  return {
    ofs: offset,
    row: row,
    col: col
  }
}

module.exports.rowColsToRange = rowColsToRange = function (start, end, source, prefix = '') {
  return {
    start: rowColToPos(start.row, start.col, source, prefix),
    end: rowColToPos(end.row, end.col, source, prefix)
  }
}

module.exports.locToPos = locToPos = function (loc, source, prefix = '') {
  return rowColToPos(loc.line, loc.column, source, prefix)
}

module.exports.locsToRange = locsToRange = function (start, end, source, prefix = '') {
  return {
    start: locToPos(start, source, prefix),
    end: locToPos(end, source, prefix)
  }
}
module.exports.stringifyPos = stringifyPos = pos => `{ofs: ${pos.ofs}, row: ${pos.row}, col: ${pos.col}}`

module.exports.stringifyRange = stringifyRange = (start, end) => `[${stringifyPos(start)}, ${stringifyPos(end)}]`

let lastRowOffsets = null
let lastRowOffsetsSource = null
let lastRowOffsetsPrefix = null

const buildRowOffsets = function (source, prefix = '') {
  if ((source === lastRowOffsetsSource) && (prefix === lastRowOffsetsPrefix)) { return lastRowOffsets }
  const rowOffsets = [0]
  const iterable = source.substr(prefix.length)
  for (let offset = 0; offset < iterable.length; offset++) {
    const c = iterable[offset]
    if (c === '\n') {
      rowOffsets.push(offset + 1)
    }
  }
  lastRowOffsets = rowOffsets
  lastRowOffsetsSource = source
  lastRowOffsetsPrefix = prefix
  return rowOffsets
}

const offsetToRow = function (offset, rowOffsets) {
  const alen = rowOffsets.length
  if (offset <= 0) { return 0 }
  if (offset >= rowOffsets[alen - 1]) { return alen - 1 }
  let lo = 0
  let hi = alen - 1
  while (lo < hi) {
    const mid = ~~((hi + lo) / 2)
    if ((offset >= rowOffsets[mid]) && (offset < rowOffsets[mid + 1])) { return mid }
    if (offset < rowOffsets[mid]) {
      hi = mid
    } else {
      lo = mid
    }
  }
  throw new Error('Bug in offsetToRow()')
}
