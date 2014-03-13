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
    console.error "CoordinateDisplay needs camera." unless @camera
    @build()
    @show = _.debounce @show, 125
    Backbone.Mediator.subscribe(channel, @[func], @) for channel, func of @subscriptions

  destroy: ->
    Backbone.Mediator.unsubscribe(channel, @[func], @) for channel, func of @subscriptions
    @show = null
    @destroyed = true

  build: ->
    @mouseEnabled = @mouseChildren = false
    @addChild @label = new createjs.Text("", "20px Arial", "#003300")
    @label.name = 'position text'
    @label.shadow = new createjs.Shadow("#FFFFFF", 1, 1, 0)

  onMouseOver: (e) -> @mouseInBounds = true
  onMouseOut: (e) -> @mouseInBounds = false

  onMouseMove: (e) ->
    if @mouseInBounds and key.shift
      $('#surface').addClass('flag-cursor') unless $('#surface').hasClass('flag-cursor')
    else if @mouseInBounds
      $('#surface').removeClass('flag-cursor') if $('#surface').hasClass('flag-cursor')
    wop = @camera.canvasToWorld x: e.x, y: e.y
    wop.x = Math.round(wop.x)
    wop.y = Math.round(wop.y)
    return if wop.x is @lastPos?.x and wop.y is @lastPos?.y
    @lastPos = wop
    @hide()
    @show()  # debounced

  onMouseDown: (e) ->
    return unless key.shift
    wop = @camera.canvasToWorld x: e.x, y: e.y
    wop.x = Math.round wop.x
    wop.y = Math.round wop.y
    Backbone.Mediator.publish 'surface:coordinate-selected', wop

  onZoomUpdated: (e) ->
    @hide()
    @show()

  hide: ->
    return unless @label.parent
    @removeChild @label
    @uncache()

  show: =>
    return unless @mouseInBounds and @lastPos and not @destroyed
    @label.text = "(#{@lastPos.x}, #{@lastPos.y})"
    [width, height] = [@label.getMeasuredWidth(), @label.getMeasuredHeight()]
    @label.regX = width / 2
    @label.regY = height / 2
    sup = @camera.worldToSurface @lastPos
    @x = sup.x
    @y = sup.y - 7
    @addChild @label
    @cache -width / 2, -height / 2, width, height
    Backbone.Mediator.publish 'surface:coordinates-shown', {}
