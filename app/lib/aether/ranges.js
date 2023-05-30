// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
export const offsetToPos = function(offset, source, prefix) {
  if (prefix == null) { prefix = ''; }
  const rowOffsets = buildRowOffsets(source, prefix);
  offset -= prefix.length;
  const row = offsetToRow(offset, rowOffsets);
  const col = offset - rowOffsets[row];
  return {ofs: offset, row, col};
};

export const offsetsToRange = function(start, end, source, prefix) {
  if (prefix == null) { prefix = ''; }
  return {start: offsetToPos(start, source, prefix), end: offsetToPos(end, source, prefix)};
};

export const rowColToPos = function(row, col, source, prefix) {
  if (prefix == null) { prefix = ''; }
  const rowOffsets = buildRowOffsets(source, prefix);
  const offset = rowOffsets[row] + col;
  return {ofs: offset, row, col};
};

export const rowColsToRange = function(start, end, source, prefix) {
  if (prefix == null) { prefix = ''; }
  return {start: rowColToPos(start.row, start.col, source, prefix), end: rowColToPos(end.row, end.col, source, prefix)};
};

export const locToPos = function(loc, source, prefix) {
  if (prefix == null) { prefix = ''; }
  return rowColToPos(loc.line, loc.column, source, prefix);
};

export const locsToRange = function(start, end, source, prefix) {
  if (prefix == null) { prefix = ''; }
  return {start: locToPos(start, source, prefix), end: locToPos(end, source, prefix)};
};

export const stringifyPos = pos => `{ofs: ${pos.ofs}, row: ${pos.row}, col: ${pos.col}}`;
export const stringifyRange = (start, end) => `[${stringifyPos(start)}, ${stringifyPos(end)}]`;

// Since we're probably going to be searching the same source many times in a row,
// this simple form of caching should get the job done.
let lastRowOffsets = null;
let lastRowOffsetsSource = null;
let lastRowOffsetsPrefix = null;
var buildRowOffsets = function(source, prefix) {
  if (prefix == null) { prefix = ''; }
  if ((source === lastRowOffsetsSource) && (prefix === lastRowOffsetsPrefix)) { return lastRowOffsets; }
  const rowOffsets = [0];
  const iterable = source.substr(prefix.length);
  for (let offset = 0; offset < iterable.length; offset++) {
    var c = iterable[offset];
    if (c === '\n') {
      rowOffsets.push(offset+1);
    }
  }
  lastRowOffsets = rowOffsets;
  lastRowOffsetsSource = source;
  lastRowOffsetsPrefix = prefix;
  return rowOffsets;
};

// Fast version using binary search
var offsetToRow = function(offset, rowOffsets) {
  const alen = rowOffsets.length;
  if (offset <= 0) { return 0; }  // First row
  if (offset >= rowOffsets[alen - 1]) { return alen - 1; }  // Last row
  let lo = 0;
  let hi = alen - 1;
  while (lo < hi) {
    var mid = ~~((hi + lo) / 2);  // ~~ is a faster, better Math.floor()
    if ((offset >= rowOffsets[mid]) && (offset < rowOffsets[mid + 1])) { return mid; }
    if (offset < rowOffsets[mid]) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  throw new Error("Bug in offsetToRow()");
};
