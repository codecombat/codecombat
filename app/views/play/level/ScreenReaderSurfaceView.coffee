require('app/styles/play/level/screen-reader-surface-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/play/level/screen-reader-surface'
utils = require 'core/utils'

module.exports = class ScreenReaderSurfaceView extends CocoView
  id: 'screen-reader-surface-view'
  template: template
  cursorFollowsHero: true

  subscriptions:
    'tome:change-config': 'onChangeTomeConfig'
    'surface:update-screen-reader-map': 'onUpdateScreenReaderMap'
    'camera:zoom-updated': 'onUpdateScreenReaderMap'

  constructor: (options) ->
    super options

  afterInsert: ->
    super()
    $(window).on('keydown', @onKeyEvent)
    $(window).on('keyup', @onKeyEvent)
    @onChangeTomeConfig()
    @updateScale()

  destroy: ->
    $(window).off('keydown', @onKeyEvent)
    $(window).off('keyup', @onKeyEvent)
    super()

  onChangeTomeConfig: (e) ->
    # TODO: because this view is only present in PlayLevelView, we still also have the below class toggle line in other places this could be changed outside of PlayLevelView; should refactor
    $('body').toggleClass('screen-reader-mode', me.get('aceConfig')?.screenReaderMode)
    if me.get('aceConfig')?.screenReaderMode and not @grid
      # Need to run the code for this to show up properly
      Backbone.Mediator.publish 'tome:manual-cast', { realTime: false }

  onUpdateScreenReaderMap: (e) ->
    # Called whenver we need to instantiate/update the map and what's in it
    if e?.grid
      @grid = e.grid
      @gridChars = @grid.toSimpleMovementChars(true, false)
      @gridNames = @grid.toSimpleMovementNames()
    @updateCells @cursorFollowsHero
    @updateScale e

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
      @cursorFollowsHero = true
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
      @setCursor newCursor
      @announceCursor()
      newCol = newCursor.col
      sound = 'game-menu-switch-tab'  # temporary sfx we already have
      @cursorFollowsHero = false
    else
      # There's nothing there, so the hero can't move there--don't move the highlight cursor
      newCol = @cursor.col
      sound = 'menu-button-click'  # temporary sfx we already have, need something more different from success sound
    if @gridNames[0].length > 1
      pan = Math.max -1, Math.min 1, -1 + 2 * newCol / (@gridNames[0].length - 1)
    else
      pan = 0  # One column, can't pan left/right
    @playSound sound, 1, 0, null, pan

  setCursor: (newCursor) ->
    @cursor?.$cell.removeClass 'cursor'
    newCursor.$cell.addClass 'cursor'
    @cursor = newCursor

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

  updateCells: (followHero=false) ->
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
        if char is '@' and (followHero or not @cursor)
          @setCursor {row: r, col: c, $cell: $cell}
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

  updateScale: (e) ->
    # Scale the map to match how the visual surface is scaled

    # Determine whether we need to update
    @camera = e.camera if e?.camera
    @simpleMovementBounds = e.bounds if e?.bounds
    availableWidth  = @$el.parent().innerWidth()
    availableHeight = @$el.parent().innerHeight()
    return if availableWidth is @lastAvailableWidth and availableHeight is @lastAvailableHeight and _.isEqual(@simpleMovementBounds, @lastSimpleMovementBounds) and _.isEqual(@lastCameraWorldViewport, @camera.worldViewport)
    return unless @camera and @simpleMovementBounds
    @lastAvailableWidth  = availableWidth
    @lastAvailableHeight = availableHeight
    @lastSimpleMovementBounds = @simpleMovementBounds
    @lastCameraWorldViewport = @camera.worldViewport

    # Calculate the new size and offset
    wv = @camera.worldViewport
    gridWorldWidthWithPadding  = @simpleMovementBounds.width  + @grid.resolution
    gridWorldHeightWithPadding = @simpleMovementBounds.height + @grid.resolution
    gridWorldOffsetX = @simpleMovementBounds.left   - wv.x               - @grid.resolution / 2
    gridWorldOffsetY = @simpleMovementBounds.bottom - (wv.y - wv.height) - @grid.resolution / 2
    screenWidth  = availableWidth  * gridWorldWidthWithPadding  / wv.width
    screenHeight = availableHeight * gridWorldHeightWithPadding / wv.height
    screenOffsetX = gridWorldOffsetX / wv.width  * availableWidth
    screenOffsetY = gridWorldOffsetY / wv.height * availableHeight
    @$el.css 'width',  Math.round(screenWidth) + 'px'
    @$el.css 'height', Math.round(screenHeight) + 'px'
    @$el.css 'left',   Math.round(screenOffsetX) + 'px'
    @$el.css 'top',    Math.round(availableHeight - screenHeight - screenOffsetY) + 'px'
