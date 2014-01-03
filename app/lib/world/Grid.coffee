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
          thangs.push thang if thang.collides and not (thang in thangs) and thang.id isnt "Add Thang Phantom"
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
    (((if thangs.length then ("" + thangs.length) else " ") for thangs in row).join(" ") for row in upsideDown).join("\n")

  wallNameFor: (gx, gy, tileSize) ->
    # This doesn't work because we need to be able to place more than one tile at once
    # Also since refactoring grid to have @left and @bottom, this logic doesn't work.
    wallNames = ["dungeon_wall_000011011", "dungeon_wall_000110110", "dungeon_wall_000111111", "dungeon_wall_011011000", "dungeon_wall_110110000", "dungeon_wall_011011011", "dungeon_wall_110110110", "dungeon_wall_011111111", "dungeon_wall_110111111", "dungeon_wall_111111000", "dungeon_wall_111111011", "dungeon_wall_111111110", "dungeon_wall_111111111"]
    s = "dungeon_wall_"
    for y in [gy - tileSize, gy, gy + tileSize]
      for x in [gx - tileSize, gx, gx + tileSize]
        thangs = @grid[y][x]
        if thangs.length is 0
          if y == gy and x == gx
            s += "1"  # the center wall we're placing
          else
            s += "0"
        else if thangs.length is 1 and (thangs[0].spriteName is "Dungeon Wall" or thangs[0].spriteName.match "dungeon_wall")
          s += "1"
        else
          return null
    if s is "dungeon_wall_000010000"
      s = "dungeon_wall_111111000"
    if s not in wallNames
      return null
    return s
