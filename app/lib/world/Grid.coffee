# TODO: this thing needs a bit of thinking/testing for grid square alignments, exclusive vs. inclusive mins/maxes, etc.

module.exports = class Grid
  constructor: (thangs, @width, @height, @padding=0, @left=0, @bottom=0, @rogue=false) ->
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
    if @rogue
      thangs = (t for t in thangs when t.collides or t.spriteName is 'Gem' and not t.dead)
    else
      thangs = (t for t in thangs when t.collides)
    for thang in thangs
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

  toString: (rogue=false) ->
    upsideDown = _.clone @grid
    upsideDown.reverse()
    ((@charForThangs thangs, rogue for thangs in row).join(' ') for row in upsideDown).join("\n")

  charForThangs: (thangs, rogue) ->
    return thangs.length or ' ' unless rogue
    return '.' unless thangs.length
    return '@' if _.find thangs, (t) -> /Hero Placeholder/.test t.id
    return '>' if _.find thangs, spriteName: 'Spike Walls'
    return 'F' if _.find thangs, spriteName: 'Fence Wall'
    return 'T' if _.find thangs, spriteName: 'Fire Trap'
    return ' ' if _.find thangs, spriteName: 'Dungeon Wall'
    return 'G' if _.find thangs, spriteName: 'Gem'
    return 'C' if _.find thangs, spriteName: 'Treasure Chest'
    return '*' if _.find thangs, spriteName: 'Spear'
    return 'o' if _.find thangs, type: 'munchkin'
    return 'O' if _.find thangs, (t) -> t.team is 'ogres'
    return 'H' if _.find thangs, (t) -> t.team is 'humans'
    return 'N' if _.find thangs, (t) -> t.team is 'neutral'
    return '?'
