# TODO: this thing needs a bit of thinking/testing for grid square alignments, exclusive vs. inclusive mins/maxes, etc.

module.exports = class Grid
  constructor: (thangs, @width, @height, @padding=0, @left=0, @bottom=0) ->
    @width = Math.ceil @width
    @height = Math.ceil @height
    @left = Math.floor @left
    @bottom = Math.floor @bottom
    @update thangs

  update: (thangs) ->
    @grid = []
    for y in [0 .. @height]
      @grid.push []
      for x in [0 .. @width]
        @grid[y].push []
    for thang in thangs when thang.collides
      rect = thang.rectangle()
      [minX, maxX, minY, maxY] = [9001, -9001, 9001, -9001]
      for v in rect.vertices()
        minX = Math.min(minX, v.x - @padding)
        minY = Math.min(minY, v.y - @padding)
        maxX = Math.max(maxX, v.x + @padding)
        maxY = Math.max(maxY, v.y + @padding)
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

  clampColumn: (y) ->
    y = Math.max 0, Math.floor(y) - @bottom
    Math.min @grid.length, Math.ceil(y) - @bottom

  clampRow: (x) ->
    x = Math.max 0, Math.floor(x) - @left
    Math.min @grid[0]?.length or 0, Math.ceil(x) - @left

  columns: (minY, maxY) ->
    [@clampColumn(minY) ... @clampColumn(maxY)]

  rows: (minX, maxX) ->
    [@clampRow(minX) ... @clampRow(maxX)]

  toString: ->
    upsideDown = _.clone @grid
    upsideDown.reverse()
    (((if thangs.length then ('' + thangs.length) else ' ') for thangs in row).join(' ') for row in upsideDown).join("\n")
