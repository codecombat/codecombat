# TODO: this thing needs a bit of thinking/testing for grid square alignments, exclusive vs. inclusive mins/maxes, etc.
Rectangle = require './rectangle'

module.exports = class Grid
  constructor: (thangs, @width, @height, @padding=0, @left=0, @bottom=0, @rogue=false, @resolution=1) ->
    # Round grid size to integer multiple of resolution
    # Ex.: if resolution is 2, then w: 8.1, h: 9.9, l: 1.9, b: -0.1 -> w: 10, h: 10, l: 0, b: -2
    @width  = Math.ceil( @width  / @resolution) * @resolution
    @height = Math.ceil( @height / @resolution) * @resolution
    @left   = Math.floor(@left   / @resolution) * @resolution unless @rogue
    @bottom = Math.floor(@bottom / @resolution) * @resolution unless @rogue
    @update thangs

  update: (thangs) ->
    @grid = []
    for y in [@bottom .. @height + @bottom] by @resolution
      @grid.push []
      for x in [@left .. @width + @left] by @resolution
        @grid[Math.floor((y - @bottom) / @resolution)].push []
    if @rogue
      thangs = (t for t in thangs when t.collides or not t.dead and /Hero Goal|Dog Goal|Subgoal|Dot|Switch|Lever|Door|Power Channel/.test(t.spriteName))
    else
      thangs = (t for t in thangs when t.collides)
    for thang in thangs
      if thang.rectangle
        rect = thang.rectangle()
      else
        rect = new Rectangle(thang.pos.x, thang.pos.y, thang.width or 2, thang.height or 2, thang.rotation or 0)
      if @rogue
        # Just put it in one place: the center
        @grid[@yToCol(rect.y, Math.round)]?[@xToRow(rect.x, Math.round)]?.push thang
      else
        # Put it in all the places it touches
        [minX, maxX, minY, maxY] = [9001, -9001, 9001, -9001]
        for v in rect.vertices()
          minX = Math.min(minX, Math.max(@left,             v.x - @padding))
          minY = Math.min(minY, Math.max(@bottom,           v.y - @padding))
          maxX = Math.max(maxX, Math.min(@left   + @width,  v.x + @padding))
          maxY = Math.max(maxY, Math.min(@bottom + @height, v.y + @padding))
        for y in @columns minY, maxY
          for x in @rows minX, maxX
            @grid[y][x].push thang

  contents: (gx, gy, width=1, height=1) ->
    thangs = []
    for y in @columns gy - height / 2, gy + height / 2
      for x in @rows gx - width / 2, gx + width / 2
        for thang in @grid[y][x]
          thangs.push thang if thang.collides and not (thang in thangs) and thang.id isnt 'Add Thang Phantom'
    thangs

  yToCol: (y, rounding) -> (rounding ? Math.floor)((y - @bottom) / @resolution)

  xToRow: (x, rounding) -> (rounding ? Math.floor)((x - @left) / @resolution)

  clampColumn: (y, rounding) ->
    y = Math.max y, @bottom
    y = Math.min y, @bottom + @height
    @yToCol y, rounding

  clampRow: (x, rounding) ->
    x = Math.max x, @left
    x = Math.min x, @left + @width
    @xToRow x, rounding

  columns: (minY, maxY) ->
    #[@clampColumn(minY) .. @clampColumn(maxY, (y) -> Math.ceil(y))]  # TODO: breaks CoCo level collisions, had put in for screen reader mode. Should figure out what's right when I have more time.
    [@clampColumn(minY) ... @clampColumn(maxY)]

  rows: (minX, maxX) ->
    #[@clampRow(minX) .. @clampRow(maxX, (x) -> Math.ceil(x))]  # TODO: breaks CoCo level collisions, had put in for screen reader mode. Should figure out what's right when I have more time.
    [@clampRow(minX) ... @clampRow(maxX)]

  toString: (rogue=false, axisLabels=false) ->
    upsideDown = _.clone @grid
    upsideDown.reverse()
    ((@charForThangs thangs, rogue, r, c, axisLabels for thangs, c in row).join(' ') for row, r in upsideDown).join("\n")

  toSimpleMovementChars: (rogue=false, axisLabels=true) ->
    upsideDown = _.clone @grid
    upsideDown.reverse()
    ((@charForThangs thangs, rogue, r, c, axisLabels for thangs, c in row) for row, r in upsideDown)

  toSimpleMovementNames: ->
    upsideDown = _.clone @grid
    upsideDown.reverse()
    # Comma-separated list of names for all Thangs significant enough to read aloud to the player
    (((@nameForThangs([thang], r, c) for thang in thangs).filter((name) -> name isnt ' ').join(', ') for thangs, c in row) for row, r in upsideDown)

  charForThangs: (thangs, rogue, row, col, axisLabels) ->
    # TODO: have the Thang know its own letter
    return thangs.length or ' ' unless rogue
    isXAxis = not col
    isYAxis = not row
    isAxis = isXAxis or isYAxis
    isOrigin = isXAxis and isYAxis
    if false  #  debugging border
      return '#' if isAxis
      return '#' if row is @grid[0].length - 1
      return '#' if col is @grid.length - 1
    return ' ' unless thangs.length or (axisLabels and isAxis)
    for t in thangs
      # TODO: order thangs by significance
      return '@' if /Hero Placeholder/.test t.id
      return '$' if /Hero Goal/.test t.spriteName
      return '%' if /Dog Goal/.test t.spriteName
      return 'G' if /Subgoal/.test t.spriteName
      return 'X' if /Power Channel/.test t.spriteName
      return 'S' if /Switch/.test t.spriteName
      return 'L' if /Lever/.test t.spriteName
      return 'D' if /(Door|Entrance)/.test t.spriteName
      return 'M' if t.spriteName is 'Mouse'
      return 'N' if t.spriteName is 'Noodles'
      return 'Q' if /Quetzal/.test t.spriteName
      return 'T' if /Tengshe/.test t.spriteName
      return '*' if /^Dot/.test t.spriteName
    if axisLabels
      # 1-indexed, with 1 at top, to match how screen readers think of tables
      return 1 if isOrigin
      return col + 1 if isYAxis
      return row + 1 if isXAxis
    for t in thangs
      return ' ' if t.spriteName is 'Obstacle'
    #console.log 'Screen reader mode: do not know what to show for', ("#{t.spriteName}\t#{t.id}" for t in thangs).join(', ')
    return '?'

  nameForThangs: (thangs, row, col) ->
    # TODO: have the Thang know its own name, including state ("Open Door" vs. "Closed Door")
    if false  #  debugging border
      return 'Edge' if not row or not col
      return 'Edge' if row is @grid[0].length - 1
      return 'Edge' if col is @grid.length - 1
    return ' ' unless thangs.length
    for t in thangs
      # TODO: order thangs by significance
      return 'Hero' if /Hero Placeholder/.test t.id
      return 'Goal' if /Hero Goal/.test t.spriteName
      return 'Dog Goal' if /Dog Goal/.test t.spriteName
      return 'Subgoal' if /Subgoal/.test t.spriteName
      return 'Energy River' if /Power Channel/.test t.spriteName
      return 'Switch' if /Switch/.test t.spriteName
      return 'Lever' if /Lever/.test t.spriteName
      return 'Door' if /(Door|Entrance)/.test t.spriteName
      return 'Mouse' if t.priteName is 'Mouse'
      return 'Noodles' if t.spriteName is 'Noodles'
      return 'Quetzal' if /Quetzal/.test t.spriteName
      return 'Tengshe' if /Tengshe/.test t.spriteName
      return 'Dot' if /^Dot/.test t.spriteName
      return ' ' if t.spriteName is 'Obstacle'
    return thangs[0].spriteName
