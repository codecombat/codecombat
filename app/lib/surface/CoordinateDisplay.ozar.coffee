createjs = require 'lib/createjs-parts'

module.exports = class CoordinateDisplay extends createjs.Container
  layerPriority: -10
  subscriptions:
    'surface:mouse-moved': 'onMouseMove'
    'surface:mouse-out': 'onMouseOut'
    'surface:mouse-over': 'onMouseOver'
    'surface:stage-mouse-down': 'onMouseDown'
    'camera:zoom-updated': 'onZoomUpdated'
    'level:flag-color-selected': 'onFlagColorSelected'

  constructor: (options) ->
    super()
    @initialize()
    @camera = options.camera
    @layer = options.layer
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @build()
    @performShow = @show
    @show = _.debounce @show, 125
    Backbone.Mediator.subscribe(channel, @[func], @) for channel, func of @subscriptions

  destroy: ->
    Backbone.Mediator.unsubscribe(channel, @[func], @) for channel, func of @subscriptions
    @show = null
    @destroyed = true

  toString: -> '<CoordinateDisplay>'

  build: ->
    @mouseEnabled = @mouseChildren = false
    @addChild @background = new createjs.Shape()
    @addChild @label = new createjs.Text('', 'bold 16px Arial', '#FFFFFF')
    @addChild @pointMarker = new createjs.Shape()
    @label.name = 'Coordinate Display Text'
    @label.shadow = new createjs.Shadow('#000000', 1, 1, 0)
    @background.name = 'Coordinate Display Background'
    @pointMarker.name = 'Point Marker'
    @layer.addChild @

  onMouseOver: (e) -> @mouseInBounds = true
  onMouseOut: (e) -> @mouseInBounds = false

  onMouseMove: (e) ->
    wop = @camera.screenToWorld x: e.x, y: e.y
    wop.x = Math.round(wop.x)
    wop.y = Math.round(wop.y)
    return if wop.x is @lastPos?.x and wop.y is @lastPos?.y
    @lastPos = wop
    @lastScreenPos = x: e.x, y: e.y
    @hide()
    @show()  # debounced

  onMouseDown: (e) ->
    return unless key.shift
    wop = @camera.screenToWorld x: e.x, y: e.y
    wop.x = Math.round wop.x
    wop.y = Math.round wop.y
    Backbone.Mediator.publish 'tome:focus-editor', {}
    Backbone.Mediator.publish 'surface:coordinate-selected', wop

  onZoomUpdated: (e) ->
    return unless @lastPos
    wop = @camera.screenToWorld @lastScreenPos
    @lastPos.x = Math.round wop.x
    @lastPos.y = Math.round wop.y
    @performShow() if @label.parent

  onFlagColorSelected: (e) ->
    @placingFlag = Boolean e.color

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

    # Shift pointmarker up so it centers at pointer (affects container cache position)
    @pointMarker.regY = contentHeight

    pointMarkerStroke = 2
    pointMarkerLength = 8
    fullPointMarkerLength = pointMarkerLength + (pointMarkerStroke / 2)
    contributionsToTotalSize = []
    contributionsToTotalSize = contributionsToTotalSize.concat @updateCoordinates contentWidth, contentHeight, fullPointMarkerLength
    contributionsToTotalSize = contributionsToTotalSize.concat @updatePointMarker 0, contentHeight, pointMarkerLength, pointMarkerStroke

    totalWidth = contentWidth + contributionsToTotalSize.reduce (a, b) -> a + b
    totalHeight = contentHeight + contributionsToTotalSize.reduce (a, b) -> a + b

    if @isNearTopEdge()
      verticalEdge =
        startPos: -fullPointMarkerLength
        posShift: -contentHeight + 4
    else
      verticalEdge =
        startPos: -totalHeight + fullPointMarkerLength
        posShift: contentHeight

    if @isNearRightEdge()
      horizontalEdge =
        startPos: -totalWidth + fullPointMarkerLength
        posShift: totalWidth
    else
      horizontalEdge =
        startPos: -fullPointMarkerLength
        posShift: 0

    @orient verticalEdge, horizontalEdge, totalHeight, totalWidth

  isNearTopEdge: ->
    yRatio = 1 - (@camera.worldViewport.y - @lastPos.y) / @camera.worldViewport.height
    yRatio > 0.9

  isNearRightEdge: ->
    xRatio = (@lastPos.x - @camera.worldViewport.x) / @camera.worldViewport.width
    xRatio > 0.85

  orient: (verticalEdge, horizontalEdge, totalHeight, totalWidth) ->
    @label.regY = @background.regY = verticalEdge.posShift
    @label.regX = @background.regX = horizontalEdge.posShift
    @cache horizontalEdge.startPos, verticalEdge.startPos, totalWidth, totalHeight

  updateCoordinates: (contentWidth, contentHeight, offset) ->
    # Center label horizontally and vertically
    @label.x = contentWidth / 2 - (@label.getMeasuredWidth() / 2) + offset
    @label.y = contentHeight / 2 - (@label.getMeasuredHeight() / 2) - offset

    @background.graphics
      .clear()
      .beginFill('rgba(0,0,0,0.4)')
      .beginStroke('rgba(0,0,0,0.6)')
      .setStrokeStyle(backgroundStroke = 1)
      .drawRoundRect(offset, -offset, contentWidth, contentHeight, radius = 2.5)
      .endFill()
      .endStroke()
    contributionsToTotalSize = [offset, backgroundStroke]

  updatePointMarker: (centerX, centerY, length, strokeSize) ->
    strokeStyle = 'square'
    @pointMarker.graphics
      .beginStroke('rgb(255, 255, 255)')
      .setStrokeStyle(strokeSize, strokeStyle)
      .moveTo(centerX, centerY - length)
      .lineTo(centerX, centerY + length)
      .moveTo(centerX - length, centerY)
      .lineTo(centerX + length, centerY)
      .endStroke()
    contributionsToTotalSize = [strokeSize, length]

  show: =>
    return unless @mouseInBounds and @lastPos and not @destroyed
    @label.text = "{x: #{@lastPos.x}, y: #{@lastPos.y}}"
    @updateSize()
    sup = @camera.worldToSurface @lastPos
    @x = sup.x
    @y = sup.y
    @addChild @background
    @addChild @label
    @addChild @pointMarker unless @placingFlag
    @updateCache()
    Backbone.Mediator.publish 'surface:coordinates-shown', {}
