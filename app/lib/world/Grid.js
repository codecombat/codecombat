/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// TODO: this thing needs a bit of thinking/testing for grid square alignments, exclusive vs. inclusive mins/maxes, etc.
let Grid;
const Rectangle = require('./rectangle');

module.exports = (Grid = class Grid {
  constructor(thangs, width, height, padding, left, bottom, rogue, resolution) {
    // Round grid size to integer multiple of resolution
    // Ex.: if resolution is 2, then w: 8.1, h: 9.9, l: 1.9, b: -0.1 -> w: 10, h: 10, l: 0, b: -2
    this.width = width;
    this.height = height;
    if (padding == null) { padding = 0; }
    this.padding = padding;
    if (left == null) { left = 0; }
    this.left = left;
    if (bottom == null) { bottom = 0; }
    this.bottom = bottom;
    if (rogue == null) { rogue = false; }
    this.rogue = rogue;
    if (resolution == null) { resolution = 1; }
    this.resolution = resolution;
    this.width  = Math.ceil( this.width  / this.resolution) * this.resolution;
    this.height = Math.ceil( this.height / this.resolution) * this.resolution;
    if (!this.rogue) { this.left   = Math.floor(this.left   / this.resolution) * this.resolution; }
    if (!this.rogue) { this.bottom = Math.floor(this.bottom / this.resolution) * this.resolution; }
    this.update(thangs);
  }

  update(thangs) {
    let x, y;
    let asc, end, step;
    let t;
    this.grid = [];
    for (y = this.bottom, end = this.height + this.bottom, step = this.resolution, asc = step > 0; asc ? y <= end : y >= end; y += step) {
      var asc1, end1, step1;
      this.grid.push([]);
      for (x = this.left, end1 = this.width + this.left, step1 = this.resolution, asc1 = step1 > 0; asc1 ? x <= end1 : x >= end1; x += step1) {
        this.grid[Math.floor((y - this.bottom) / this.resolution)].push([]);
      }
    }
    if (this.rogue) {
      thangs = ((() => {
        const result = [];
        for (t of Array.from(thangs)) {           if (t.collides || (!t.dead && /Hero Goal|Dog Goal|Subgoal|Dot|Switch|Lever|Door|Power Channel/.test(t.spriteName))) {
            result.push(t);
          }
        }
        return result;
      })());
    } else {
      thangs = ((() => {
        const result1 = [];
        for (t of Array.from(thangs)) {           if (t.collides) {
            result1.push(t);
          }
        }
        return result1;
      })());
    }
    return (() => {
      const result2 = [];
      for (var thang of Array.from(thangs)) {
        var rect;
        if (thang.rectangle) {
          rect = thang.rectangle();
        } else {
          rect = new Rectangle(thang.pos.x, thang.pos.y, thang.width || 2, thang.height || 2, thang.rotation || 0);
        }
        if (this.rogue) {
          // Just put it in one place: the center
          result2.push(__guard__(__guard__(this.grid[this.yToCol(rect.y, Math.round)], x2 => x2[this.xToRow(rect.x, Math.round)]), x1 => x1.push(thang)));
        } else {
          // Put it in all the places it touches
          var [minX, maxX, minY, maxY] = Array.from([9001, -9001, 9001, -9001]);
          for (var v of Array.from(rect.vertices())) {
            minX = Math.min(minX, Math.max(this.left,             v.x - this.padding));
            minY = Math.min(minY, Math.max(this.bottom,           v.y - this.padding));
            maxX = Math.max(maxX, Math.min(this.left   + this.width,  v.x + this.padding));
            maxY = Math.max(maxY, Math.min(this.bottom + this.height, v.y + this.padding));
          }
          result2.push((() => {
            const result3 = [];
            for (y of Array.from(this.columns(minY, maxY))) {
              result3.push((() => {
                const result4 = [];
                for (x of Array.from(this.rows(minX, maxX))) {
                  result4.push(this.grid[y][x].push(thang));
                }
                return result4;
              })());
            }
            return result3;
          })());
        }
      }
      return result2;
    })();
  }

  contents(gx, gy, width, height) {
    if (width == null) { width = 1; }
    if (height == null) { height = 1; }
    const thangs = [];
    for (var y of Array.from(this.columns(gy - (height / 2), gy + (height / 2)))) {
      for (var x of Array.from(this.rows(gx - (width / 2), gx + (width / 2)))) {
        for (var thang of Array.from(this.grid[y][x])) {
          if (thang.collides && !(Array.from(thangs).includes(thang)) && (thang.id !== 'Add Thang Phantom')) { thangs.push(thang); }
        }
      }
    }
    return thangs;
  }

  yToCol(y, rounding) { return (rounding != null ? rounding : Math.floor)((y - this.bottom) / this.resolution); }

  xToRow(x, rounding) { return (rounding != null ? rounding : Math.floor)((x - this.left) / this.resolution); }

  clampColumn(y, rounding) {
    y = Math.max(y, this.bottom);
    y = Math.min(y, this.bottom + this.height);
    return this.yToCol(y, rounding);
  }

  clampRow(x, rounding) {
    x = Math.max(x, this.left);
    x = Math.min(x, this.left + this.width);
    return this.xToRow(x, rounding);
  }

  columns(minY, maxY) {
    //[@clampColumn(minY) .. @clampColumn(maxY, (y) -> Math.ceil(y))]  # TODO: breaks CoCo level collisions, had put in for screen reader mode. Should figure out what's right when I have more time.
    return __range__(this.clampColumn(minY), this.clampColumn(maxY), false);
  }

  rows(minX, maxX) {
    //[@clampRow(minX) .. @clampRow(maxX, (x) -> Math.ceil(x))]  # TODO: breaks CoCo level collisions, had put in for screen reader mode. Should figure out what's right when I have more time.
    return __range__(this.clampRow(minX), this.clampRow(maxX), false);
  }

  toString(rogue, axisLabels) {
    if (rogue == null) { rogue = false; }
    if (axisLabels == null) { axisLabels = false; }
    const upsideDown = _.clone(this.grid);
    upsideDown.reverse();
    return (Array.from(upsideDown).map((row, r) => (Array.from(row).map((thangs, c) => this.charForThangs(thangs, rogue, r, c, axisLabels))).join(' '))).join("\n");
  }

  toSimpleMovementChars(rogue, axisLabels) {
    if (rogue == null) { rogue = false; }
    if (axisLabels == null) { axisLabels = true; }
    const upsideDown = _.clone(this.grid);
    upsideDown.reverse();
    return (Array.from(upsideDown).map((row, r) => (Array.from(row).map((thangs, c) => this.charForThangs(thangs, rogue, r, c, axisLabels)))));
  }

  toSimpleMovementNames() {
    const upsideDown = _.clone(this.grid);
    upsideDown.reverse();
    // Comma-separated list of names for all Thangs significant enough to read aloud to the player
    return Array.from(upsideDown).map((row, r) => (Array.from(row).map((thangs, c) => (Array.from(thangs).map((thang) => this.nameForThangs([thang], r, c))).filter(name => name !== ' ').join(', '))));
  }

  charForThangs(thangs, rogue, row, col, axisLabels) {
    // TODO: have the Thang know its own letter
    let t;
    if (!rogue) { return thangs.length || ' '; }
    const isXAxis = !col;
    const isYAxis = !row;
    const isAxis = isXAxis || isYAxis;
    const isOrigin = isXAxis && isYAxis;
    if (false) {  //  debugging border
      if (isAxis) { return '#'; }
      if (row === (this.grid[0].length - 1)) { return '#'; }
      if (col === (this.grid.length - 1)) { return '#'; }
    }
    if (!thangs.length && (!axisLabels || !isAxis)) { return ' '; }
    for (t of Array.from(thangs)) {
      // TODO: order thangs by significance
      if (/Hero Placeholder/.test(t.id)) { return '@'; }
      if (/Hero Goal/.test(t.spriteName)) { return '$'; }
      if (/Dog Goal/.test(t.spriteName)) { return '%'; }
      if (/Subgoal/.test(t.spriteName)) { return 'G'; }
      if (/Power Channel/.test(t.spriteName)) { return 'X'; }
      if (/Switch/.test(t.spriteName)) { return 'S'; }
      if (/Lever/.test(t.spriteName)) { return 'L'; }
      if (/(Door|Entrance)/.test(t.spriteName)) { return 'D'; }
      if (t.spriteName === 'Mouse') { return 'M'; }
      if (t.spriteName === 'Noodles') { return 'N'; }
      if (/Quetzal/.test(t.spriteName)) { return 'Q'; }
      if (/Tengshe/.test(t.spriteName)) { return 'T'; }
      if (/^Dot/.test(t.spriteName)) { return '*'; }
    }
    if (axisLabels) {
      // 1-indexed, with 1 at top, to match how screen readers think of tables
      if (isOrigin) { return 1; }
      if (isYAxis) { return col + 1; }
      if (isXAxis) { return row + 1; }
    }
    for (t of Array.from(thangs)) {
      if (t.spriteName === 'Obstacle') { return ' '; }
    }
    //console.log 'Screen reader mode: do not know what to show for', ("#{t.spriteName}\t#{t.id}" for t in thangs).join(', ')
    return '?';
  }

  nameForThangs(thangs, row, col) {
    // TODO: have the Thang know its own name, including state ("Open Door" vs. "Closed Door")
    if (false) {  //  debugging border
      if (!row || !col) { return 'Edge'; }
      if (row === (this.grid[0].length - 1)) { return 'Edge'; }
      if (col === (this.grid.length - 1)) { return 'Edge'; }
    }
    if (!thangs.length) { return ' '; }
    for (var t of Array.from(thangs)) {
      // TODO: order thangs by significance
      if (/Hero Placeholder/.test(t.id)) { return 'Hero'; }
      if (/Hero Goal/.test(t.spriteName)) { return 'Goal'; }
      if (/Dog Goal/.test(t.spriteName)) { return 'Dog Goal'; }
      if (/Subgoal/.test(t.spriteName)) { return 'Subgoal'; }
      if (/Power Channel/.test(t.spriteName)) { return 'Energy River'; }
      if (/Switch/.test(t.spriteName)) { return 'Switch'; }
      if (/Lever/.test(t.spriteName)) { return 'Lever'; }
      if (/(Door|Entrance)/.test(t.spriteName)) { return 'Door'; }
      if (t.priteName === 'Mouse') { return 'Mouse'; }
      if (t.spriteName === 'Noodles') { return 'Noodles'; }
      if (/Quetzal/.test(t.spriteName)) { return 'Quetzal'; }
      if (/Tengshe/.test(t.spriteName)) { return 'Tengshe'; }
      if (/^Dot/.test(t.spriteName)) { return 'Dot'; }
      if (t.spriteName === 'Obstacle') { return ' '; }
    }
    return thangs[0].spriteName;
  }
});

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
function __range__(left, right, inclusive) {
  let range = [];
  let ascending = left < right;
  let end = !inclusive ? right : ascending ? right + 1 : right - 1;
  for (let i = left; ascending ? i < end : i > end; ascending ? i++ : i--) {
    range.push(i);
  }
  return range;
}