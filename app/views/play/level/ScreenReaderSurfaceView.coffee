require('app/styles/play/level/screen-reader-surface-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/play/level/screen-reader-surface'
utils = require 'core/utils'

module.exports = class ScreenReaderSurfaceView extends CocoView
  id: 'screen-reader-surface-view'
  template: template

  subscriptions:
    'surface:update-screen-reader-map': 'onUpdateScreenReaderMap'
    'camera:zoom-updated': 'onUpdateScreenReaderMap'

  constructor: (options) ->
    super options

  afterInsert: ->
    super()
    $(window).on('keydown', @onKeyEvent)
    $(window).on('keyup', @onKeyEvent)
    @updateScale()

  destroy: ->
    $(window).off('keydown', @onKeyEvent)
    $(window).off('keyup', @onKeyEvent)
    super()

  onUpdateScreenReaderMap: (e) ->
    # Called whenver we need to instantiate/update the map and what's in it
    if e?.grid
      @grid = e.grid
      @gridChars = @grid.toSimpleMovementChars(true, false)
      @gridNames = @grid.toSimpleMovementNames()
    @updateCells()
    @updateScale()

  onKeyEvent: (e) =>
    event = _.pick(e, 'type', 'key', 'keyCode', 'ctrlKey', 'metaKey', 'shiftKey')
    return unless @cursor
    return unless event.type is 'keydown'
    if /^arrow/i.test event.key
      return @handleArrowKey event.key
    if event.key is ' '  # space
      return @announceCursor true
    if event.key.toLowerCase() in ['h', '@']
      @moveToHero()
      return @announceCursor()

  handleArrowKey: (key) ->
    # Move cursor in the specified direction, if valid
    adjacent = @adjacentCells @cursor
    newCursor = switch key.toLowerCase()
      when 'arrowleft'  then adjacent.left
      when 'arrowright' then adjacent.right
      when 'arrowup'    then adjacent.up
      when 'arrowdown'  then adjacent.down
    if newCursor
      @cursor.$cell.removeClass 'cursor'
      newCursor.$cell.addClass 'cursor'
      @cursor = newCursor
      @announceCursor()
      pan = Math.max -1, Math.min 1, -1 + 2 * newCursor.col / (@gridNames[0].length - 1)
      @playSound 'game-menu-tab-switch', 1, 0, null, pan  # temporary sfx we already have
    else
      # There's nothing there, so the hero can't move there--don't move the highlight cursor
      pan = Math.max -1, Math.min 1, -1 + 2 * @cursor.col / (@gridNames[0].length - 1)
      @playSound 'menu-button-click', 1, 0, null, pan  # temporary sfx we already have, need something more different from success sound

  moveToHero: ->
    for row, r in @gridChars
      cells = @mapCells[r]
      for char, c in row
        $cell = cells[c]
        if char is '@'
          @cursor.$cell.removeClass 'cursor'
          @cursor = {row: r, col: c, $cell: $cell}
          $cell.addClass 'cursor'
          return @cursor

  adjacentCells: (cell) ->
    # Find the visitable cells next to this cell
    result = {}
    for dirName, dirVec of {
      left:  [-1,  0]
      right: [ 1,  0]
      up:    [ 0, -1]  # y is inverted for the screen
      down:  [ 0,  1]
    }
      $cell = @mapCells[cell.row + dirVec[1]]?[cell.col + dirVec[0]]
      if $cell?.previousChar.trim()
        # There's something there (a movable area and/or an object)
        result[dirName] = row: cell.row + dirVec[1], col: cell.col + dirVec[0], $cell: $cell
    result

  formatCellContents: (cell) ->
    @gridNames[cell.row][cell.col].replace /,? ?Dot,? ?/g, ''

  announceCursor: (full=false) ->
    # Say what's at the current cursor, if a screen reader is active. Full: includes extra detail on what's around this cell.
    update = @formatCellContents @cursor
    if full
      update ||= 'Empty'
      contentful = []
      contentless = []
      for dirName, cell of @adjacentCells @cursor
        contents = @formatCellContents cell
        (if contents then contentful else contentless).push {dirName, cell, contents}
      for {dirName, cell, contents} in contentful
        update += ". #{dirName} has #{contents}"
      if contentless.length
        update += ". Can #{if contentful.length then 'also ' else ''}move #{(cell.dirName for cell in contentless).join(', ')}."
    @$el.find('.map-screen-reader-live-updates').text(update)

  updateCells: ->
    # Create/remove/update .map-cell divs to visually correspond to the current state of the level map grid
    return unless @gridChars
    @mapRows ?= []
    @mapCells ?= []
    $mapGrid = @$el.find('.map-grid')
    for row, r in @gridChars
      $row = @mapRows[r]
      cells = @mapCells[r]
      if not $row
        $mapGrid.append($row = $('<div class="map-row"></div>'))
        @mapRows.push $row
        @mapCells.push cells = []
      for char, c in row
        $cell = cells[c]
        name = @gridNames[r][c] or 'Blank'
        if not $cell
          $row.append($cell = $("<div class='map-cell'></div>"))
          cells.push $cell
          $cell.append($("<span aria-hidden='true'>#{char}</span>"))
          $cell.append($("<span class='sr-only'>#{name}</span>"))
        else
          if $cell.previousChar isnt char
            utils.replaceText $cell.find('span[aria-hidden="true"]'), char
          if $cell.previousName isnt name
            utils.replaceText $cell.find('span.sr-only'), name
        if char is '@' and not @cursor
          @cursor = {row: r, col: c, $cell: $cell}
          $cell.addClass 'cursor'
        $cell.previousChar = char
        $cell.previousName = name
      if c < cells.length - 1
        # Grid has shrunk width; remove extra cells
        $cell.remove() for $cell in cells.splice c + 1
    if r < @mapRows.length - 1
      # Grid has shrunk height; remove extra rows and their cells
      $row.remove() for $row in @mapRows.splice r + 1
      for cells in @mapCells.splice r + 1
        $cell.remove() for $cell in cells

  updateScale: ->
    # Scale the map to match how the visual surface is scaled
    availableWidth = @$el.parent().innerWidth()
    availableHeight = @$el.parent().innerHeight()
    return if availableWidth is @lastAvailableWidth and availableHeight is @lastAvailableHeight
    @$el.css 'transform', 'initial'
    fullWidth = @$el.innerWidth()
    fullHeight = @$el.innerHeight()
    scaleX = availableWidth / fullWidth
    scaleY = availableHeight / fullHeight
    @$el.css 'transform', "scaleX(#{scaleX}) scaleY(#{scaleY})"
    @lastAvailableWidth = availableWidth
    @lastAvailableHeight = availableHeight
