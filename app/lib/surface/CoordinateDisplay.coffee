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
    @label.name = 'Coordinate Display Text'
    @label.shadow = new createjs.Shadow('#000000', 1, 1, 0)
    @background.name = 'Coordinate Display Background'

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
    @uncache()

  updateSize: ->
    margin = 3
    radius = 2.5
    width = @label.getMeasuredWidth() + 2 * margin
    height = @label.getMeasuredHeight() + 2 * margin
    @label.regX = @background.regX = width / 2 - margin
    @label.regY = @background.regY = height / 2 - margin
    @background.graphics
      .clear()
      .beginFill('rgba(0,0,0,0.4)')
      .beginStroke('rgba(0,0,0,0.6)')
      .setStrokeStyle(1)
      .drawRoundRect(0, 0, width, height, radius)
      .endFill()
      .endStroke()
    [width, height]

  show: =>
    return unless @mouseInBounds and @lastPos and not @destroyed
    @label.text = "{x: #{@lastPos.x}, y: #{@lastPos.y}}"
    [width, height] = @updateSize()
    sup = @camera.worldToSurface @lastPos
    @x = sup.x
    @y = sup.y - 2.5
    @addChild @background
    @addChild @label
    @cache -width / 2, -height / 2, width, height
    Backbone.Mediator.publish 'surface:coordinates-shown', {}
