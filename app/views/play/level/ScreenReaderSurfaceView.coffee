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
    if e?.grid
      @grid = e.grid
      @gridChars = @grid.toSimpleMovementChars(true, false)
      @gridNames = @grid.toSimpleMovementNames()
      #console.log @grid, @gridNames
      #console.log @grid.toString(true, false)
    @updateCells()
    @updateScale()

  onKeyEvent: (e) =>
    event = _.pick(e, 'type', 'key', 'keyCode', 'ctrlKey', 'metaKey', 'shiftKey')
    #console.log 'got event', event, @highlight, /^arrow/.test(event.key.toLowerCase()), event.key.toLowerCase()
    # TODO: only do this if we have the map area focused
    return unless @highlight
    return unless /^arrow/.test event.key.toLowerCase()
    return unless event.type is 'keydown'
    newHighlight = {row: @highlight.row, col: @highlight.col}
    switch event.key.toLowerCase()
      when 'arrowleft'  then --newHighlight.col
      when 'arrowright' then ++newHighlight.col
      when 'arrowup'    then --newHighlight.row
      when 'arrowdown'  then ++newHighlight.row
    pan = Math.max -1, Math.min 1, -1 + 2 * newHighlight.col / (@gridNames[0].length - 1)
    if (newHighlight.$cell = @mapCells[newHighlight.row]?[newHighlight.col]) and newHighlight.$cell.previousChar.trim()
      # There's something here (a movable area and/or an object)
      @highlight.$cell.removeClass 'highlighted'
      newHighlight.$cell.addClass 'highlighted'
      @highlight = newHighlight
      update = @gridNames[@highlight.row][@highlight.col]
      update = update.replace /,? ?Dot,? ?/g, ''
      @$el.find('.map-screen-reader-live-updates').text(update)
      @playSound 'game-menu-tab-switch', 1, 0, null, pan  # temporary sfx we already have
    else
      # There's nothing here, and the hero can't move here--don't move the highlight cursor
      @playSound 'menu-button-click', 1, 0, null, pan  # temporary sfx we already have, need something more different from success sound

  updateCells: ->
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
        if char is '@' and not @highlight
          @highlight = {row: r, col: c, $cell: $cell}
          $cell.addClass 'highlighted'
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
