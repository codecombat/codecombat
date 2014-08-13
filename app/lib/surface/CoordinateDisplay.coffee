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
    @containerOverlay = new createjs.Shape() # FOR TESTING - REMOVE BEFORE COMMIT

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
    @removeChild @containerOverlay  # FOR TESTING - REMOVE BEFORE COMMIT
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

    # Orientation
    #find the current orientation and store it in an instance variable
    # i.e.: topright, bottomright, bottomleft, topleft (default is topright)
    #can be done separately:
    #  -use regx and y to adjust label and background position
    #  -adjust the cache position
    # both can use the current orientation to do their work without knowing about the other

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
    @camera.distanceToTopEdge(@lastPos.y) <= 1

  isNearRightEdge: ->
    @camera.distanceToRightEdge(@lastPos.x) <= 4

  orient: (verticalEdge, horizontalEdge, totalHeight, totalWidth) ->
    @label.regY = @background.regY = verticalEdge.posShift
    @label.regX = @background.regX = horizontalEdge.posShift

    @containerOverlay.graphics
      .clear()
      .beginFill('rgba(255,0,0,0.4)') # Actual position
      .drawRect(0, 0, totalWidth, totalHeight)
      .endFill()
      .beginFill('rgba(0,0,255,0.4)') # Cache position
      .drawRect(horizontalEdge.startPos, verticalEdge.startPos, totalWidth, totalHeight)
      .endFill()

    #@cache horizontalEdge.startPos, verticalEdge.startPos, totalWidth, totalHeight

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
    @addChild @pointMarker
    @addChild @containerOverlay  # FOR TESTING - REMOVE BEFORE COMMIT
    #@updateCache()
    Backbone.Mediator.publish 'surface:coordinates-shown', {}
