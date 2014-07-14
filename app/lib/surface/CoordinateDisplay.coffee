module.exports = class CoordinateDisplay extends createjs.Container
  layerPriority: -10
  subscriptions:
    'surface:mouse-moved': 'onMouseMove'
    'surface:mouse-out': 'onMouseOut'
    'surface:mouse-over': 'onMouseOver'
    'surface:stage-mouse-down': 'onMouseDown'
    'camera:zoom-updated': 'onZoomUpdated'

  constructor: (options) ->
    super()
    @initialize()
    @camera = options.camera
    console.error 'CoordinateDisplay needs camera.' unless @camera
    @build()
    @show = _.debounce @show, 125
    Backbone.Mediator.subscribe(channel, @[func], @) for channel, func of @subscriptions

  destroy: ->
    Backbone.Mediator.unsubscribe(channel, @[func], @) for channel, func of @subscriptions
    @show = null
    @destroyed = true

  build: ->
    @mouseEnabled = @mouseChildren = false
    @addChild @background = new createjs.Shape()
    @addChild @label = new createjs.Text('', 'bold 16px Arial', '#FFFFFF')
    @addChild @pointMarker = new createjs.Shape()
    @label.name = 'Coordinate Display Text'
    @label.shadow = new createjs.Shadow('#000000', 1, 1, 0)
    @background.name = 'Coordinate Display Background'
    @pointMarker.name = 'Point Marker'

  onMouseOver: (e) -> @mouseInBounds = true
  onMouseOut: (e) -> @mouseInBounds = false

  onMouseMove: (e) ->
    if @mouseInBounds and key.shift
      $('#surface').addClass('flag-cursor') unless $('#surface').hasClass('flag-cursor')
    else if @mouseInBounds
      $('#surface').removeClass('flag-cursor') if $('#surface').hasClass('flag-cursor')
    wop = @camera.screenToWorld x: e.x, y: e.y
    wop.x = Math.round(wop.x)
    wop.y = Math.round(wop.y)
    return if wop.x is @lastPos?.x and wop.y is @lastPos?.y
    @lastPos = wop
    @hide()
    @show()  # debounced

  onMouseDown: (e) ->
    return unless key.shift
    wop = @camera.screenToWorld x: e.x, y: e.y
    wop.x = Math.round wop.x
    wop.y = Math.round wop.y
    Backbone.Mediator.publish 'surface:coordinate-selected', wop

  onZoomUpdated: (e) ->
    @hide()
    @show()

  hide: ->
    return unless @label.parent
    @removeChild @label
    @removeChild @background
    @removeChild @pointMarker
    @uncache()

  updateSize: ->
    margin = 3
    contentWidth = @label.getMeasuredWidth() + (2 * margin)
    contentHeight = @label.getMeasuredHeight() + (2 * margin)

    # Shift all contents up so marker is at pointer (affects container cache position)
    @label.regY = @background.regY = @pointMarker.regY = contentHeight

    pointMarkerStroke = 2
    pointMarkerLength = 3
    contributionsToTotalSize = []
    contributionsToTotalSize = contributionsToTotalSize.concat @updateCoordinates contentWidth, contentHeight, pointMarkerStroke
    contributionsToTotalSize = contributionsToTotalSize.concat @updatePointMarker contentHeight, pointMarkerLength, pointMarkerStroke

    totalWidth = contentWidth + contributionsToTotalSize.reduce (a, b) -> a + b
    totalHeight = contentHeight + contributionsToTotalSize.reduce (a, b) -> a + b
    [totalWidth, totalHeight]

  updateCoordinates: (contentWidth, contentHeight, initialXYOffset) ->
    gap = 2
    labelAndBgMarkerOffset = initialXYOffset * gap

    # Center label horizontally and vertically
    @label.x = contentWidth / 2 - (@label.getMeasuredWidth() / 2) + labelAndBgMarkerOffset
    @label.y = contentHeight / 2 - (@label.getMeasuredHeight() / 2) - labelAndBgMarkerOffset

    @background.graphics
      .clear()
      .beginFill('rgba(0,0,0,0.4)')
      .beginStroke('rgba(0,0,0,0.6)')
      .setStrokeStyle(backgroundStroke = 1)
      .drawRoundRect(labelAndBgMarkerOffset, -labelAndBgMarkerOffset, contentWidth, contentHeight, radius = 2.5)
      .endFill()
      .endStroke()
    contributionsToTotalSize = [labelAndBgMarkerOffset, backgroundStroke]

  updatePointMarker: (contentHeight, length, strokeSize) ->
    shiftToLineupWithGrid = strokeSize / 2
    pointMarkerInitialX = strokeSize - shiftToLineupWithGrid
    pointMarkerInitialY = contentHeight - strokeSize + shiftToLineupWithGrid
    @pointMarker.graphics
      .beginStroke('rgb(142, 198, 67')
      .setStrokeStyle(strokeSize, 'square')
      .moveTo(pointMarkerInitialX, pointMarkerInitialY)
      .lineTo(pointMarkerInitialX, pointMarkerInitialY - length)
      .moveTo(pointMarkerInitialX, pointMarkerInitialY)
      .lineTo(pointMarkerInitialX + length, pointMarkerInitialY)
      .endStroke()
    contributionsToTotalSize = [strokeSize]

  show: =>
    return unless @mouseInBounds and @lastPos and not @destroyed
    @label.text = "{x: #{@lastPos.x}, y: #{@lastPos.y}}"
    [width, height] = @updateSize()
    sup = @camera.worldToSurface @lastPos
    @x = sup.x
    @y = sup.y
    @addChild @background
    @addChild @label
    @addChild @pointMarker
    @cache 0, -height, width, height
    Backbone.Mediator.publish 'surface:coordinates-shown', {}
