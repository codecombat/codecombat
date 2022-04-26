createjs = require 'lib/createjs-parts'

DEFAULT_DISPLAY_OPTIONS = {
  fontWeight: 'bold',
  fontSize: '16px',
  fontFamily: 'Arial',
  fontColor: '#FFFFFF',
  templateString: '<%= x %>, <%= y %>',
  backgroundFillColor: 'rgba(0,0,0,0.4)',
  backgroundStrokeColor: 'rgba(0,0,0,0.6)',
  backgroundStroke: 1,
  backgroundMargin: 3,
  pointMarkerColor: 'rgb(255, 255, 255)',
  pointMarkerLength: 8,
  pointMarkerStroke: 2
}

module.exports = class CoordinateDisplay extends createjs.Container
  layerPriority: -10
  subscriptions:
    'surface:mouse-moved': 'onMouseMove'
    'surface:mouse-out': 'onMouseOut'
    'surface:mouse-over': 'onMouseOver'
    'surface:stage-mouse-down': 'onMouseDown'
    'camera:zoom-updated': 'onZoomUpdated'
    'level:flag-color-selected': 'onFlagColorSelected'
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'

  constructor: (options) ->
    super()
    @initialize()
    @camera = options.camera
    @layer = options.layer
    @displayOptions = _.merge({}, DEFAULT_DISPLAY_OPTIONS, options.displayOptions or {})
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @build()
    @disabled = false
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
    @addChild @label = new createjs.Text('', "#{@displayOptions.fontWeight} #{@displayOptions.fontSize} #{@displayOptions.fontFamily}", @displayOptions.fontColor)
    @addChild @pointMarker = new createjs.Shape()
    @label.name = 'Coordinate Display Text'
    @label.shadow = new createjs.Shadow('#000000', 1, 1, 0)
    @background.name = 'Coordinate Display Background'
    @pointMarker.name = 'Point Marker'
    @layer.addChild @

  onMouseOver: (e) -> @mouseInBounds = true
  onMouseOut: (e) -> @mouseInBounds = false

  onMouseMove: (e) ->
    return if @disabled
    wop = @camera.screenToWorld x: e.x, y: e.y
    if key.alt
      wop.x = Math.round(wop.x * 1000) / 1000
      wop.y = Math.round(wop.y * 1000) / 1000
    else
      wop.x = Math.round(wop.x)
      wop.y = Math.round(wop.y)
    return if wop.x is @lastPos?.x and wop.y is @lastPos?.y
    @lastPos = wop
    @lastSurfacePos = @camera.worldToSurface(@lastPos)
    @lastScreenPos = x: e.x, y: e.y
    if key.alt
      @performShow()
    else
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

  onRealTimePlaybackStarted: (e) ->
    return if @disabled
    @disabled = true
    @hide()

  onRealTimePlaybackEnded: (e) ->
    @disabled = false

  hide: ->
    return unless @label.parent
    @removeChild @label
    @removeChild @background
    @removeChild @pointMarker
    @uncache()

  updateSize: ->
    margin = @displayOptions.backgroundMargin
    contentWidth = @label.getMeasuredWidth() + (2 * margin)
    contentHeight = @label.getMeasuredHeight() + (2 * margin)

    # Shift pointmarker up so it centers at pointer (affects container cache position)
    @pointMarker.regY = contentHeight

    pointMarkerStroke = @displayOptions.pointMarkerStroke
    pointMarkerLength = @displayOptions.pointMarkerLength
    fullPointMarkerLength = pointMarkerLength + (pointMarkerStroke / 2)
    contributionsToTotalSize = []
    contributionsToTotalSize = contributionsToTotalSize.concat @updateCoordinates contentWidth, contentHeight, fullPointMarkerLength
    contributionsToTotalSize = contributionsToTotalSize.concat @updatePointMarker 0, contentHeight, pointMarkerLength, pointMarkerStroke

    totalWidth = contentWidth + contributionsToTotalSize.reduce (a, b) -> a + b
    totalHeight = contentHeight + contributionsToTotalSize.reduce (a, b) -> a + b

    if @isNearTopEdge(totalHeight)
      verticalEdge =
        startPos: -fullPointMarkerLength
        posShift: -2 * fullPointMarkerLength
    else
      verticalEdge =
        startPos: -totalHeight + fullPointMarkerLength
        posShift: contentHeight

    if @isNearRightEdge(totalWidth)
      horizontalEdge =
        startPos: -totalWidth + fullPointMarkerLength
        posShift: totalWidth
    else
      horizontalEdge =
        startPos: -fullPointMarkerLength
        posShift: 0

    @orient verticalEdge, horizontalEdge, totalHeight, totalWidth

  isNearTopEdge: (height) ->
    height - @lastSurfacePos.y > @camera.surfaceViewport.height

  isNearRightEdge: (width) ->
    @lastSurfacePos.x + width > @camera.surfaceViewport.width
    
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
      .beginFill(@displayOptions.backgroundFillColor)
      .beginStroke(@displayOptions.backgroundStrokeColor)
      .setStrokeStyle(backgroundStroke = @displayOptions.backgroundStroke)
      .drawRoundRect(offset, -offset, contentWidth, contentHeight, radius = 2.5)
      .endFill()
      .endStroke()
    contributionsToTotalSize = [offset, backgroundStroke]

  updatePointMarker: (centerX, centerY, length, strokeSize) ->
    strokeStyle = 'square'
    @pointMarker.graphics
      .beginStroke(@displayOptions.pointMarkerColor)
      .setStrokeStyle(strokeSize, strokeStyle)
      .moveTo(centerX, centerY - length)
      .lineTo(centerX, centerY + length)
      .moveTo(centerX - length, centerY)
      .lineTo(centerX + length, centerY)
      .endStroke()
    contributionsToTotalSize = [strokeSize, length]

  show: =>
    return unless @mouseInBounds and @lastPos and not @destroyed
    @label.text = _.template(@displayOptions.templateString, {x: @lastPos.x, y: @lastPos.y})
    @updateSize()
    @x = @lastSurfacePos.x
    @y = @lastSurfacePos.y
    @addChild @background
    @addChild @label
    @addChild @pointMarker unless @placingFlag
    @updateCache()
    Backbone.Mediator.publish 'surface:coordinates-shown', {}
