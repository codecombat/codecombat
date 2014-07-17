View = require 'views/kinds/ModalView'
template = require 'templates/editor/level/modal/world_select'
Surface = require 'lib/surface/Surface'
ThangType = require 'models/ThangType'

module.exports = class WorldSelectModal extends View
  id: 'select-point-modal'
  template: template
  modalWidthPercent: 80
  cache: false

  subscriptions:
    'choose-region': 'selectionMade'
    'choose-point': 'selectionMade'

  events:
    'click #done-button': 'done'

  shortcuts:
    'enter': 'done'

  constructor: (options) ->
    @world = options.world
    @dataType = options.dataType or 'point'
    @default = options.default
    @defaultFromZoom = options.defaultFromZoom
    @selectionMade = _.debounce(@selectionMade, 300)
    @supermodel = options.supermodel
    super()

  getRenderData: (c={}) =>
    c = super(c)
    c.selectingPoint = @dataType is 'point'
    c

  afterInsert: ->
    super()
    window.e = @$el
    @initSurface()

  # surface setup

  initSurface: ->
    canvas = @$el.find('canvas')
    canvas.attr('width', currentView.$el.width()*.8-70)
    canvas.attr('height', currentView.$el.height()*.6)
    @surface = new Surface @world, canvas, {
      wizards: false
      paths: false
      grid: true
      navigateToSelection: false
      choosing: @dataType
      coords: false
      thangTypes: @supermodel.getModels(ThangType)
      showInvisible: true
    }
    window.s = @surface
    @surface.playing = false
    @surface.setWorld @world
    @surface.camera.zoomTo({x: 262, y: -164}, 1.66, 0)
    @showDefaults()

  showDefaults: ->
    # show current point, and zoom to it
    if @dataType is 'point'
      if @default? and _.isFinite(@default.x) and _.isFinite(@default.y)
        @surface.chooser.setPoint(@default)
        @surface.camera.zoomTo(@surface.camera.worldToSurface(@default), 2)

    else if @defaultFromZoom?
      @showZoomRegion()
      surfaceTarget = @surface.camera.worldToSurface(@defaultFromZoom.target)
      @surface.camera.zoomTo(surfaceTarget, @defaultFromZoom.zoom*0.6)

    else if @default? and _.isFinite(@default[0].x) and _.isFinite(@default[0].y) and _.isFinite(@default[1].x) and _.isFinite(@default[1].y)
      @surface.chooser.setRegion(@default)
      @showBoundaryRegion()

  showZoomRegion: ->
    d = @defaultFromZoom
    canvasWidth = 924  # Dimensions for canvas player. Need these somewhere.
    canvasHeight = 589
    dimensions = {x: canvasWidth/d.zoom, y: canvasHeight/d.zoom}
    dimensions = @surface.camera.surfaceToWorld(dimensions)
    width = dimensions.x
    height = dimensions.y
    target = d.target
    region = [
      {x: target.x - width/2, y: target.y - height/2}
      {x: target.x + width/2, y: target.y + height/2}
    ]
    @surface.chooser.setRegion(region)

  showBoundaryRegion: ->
    bounds = @surface.camera.normalizeBounds(@default)
    point = {
      x: bounds.x + bounds.width / 2
      y: bounds.y + bounds.height / 2
    }
    zoom = 0.8 * (@surface.camera.canvasWidth / bounds.width)
    @surface.camera.zoomTo(point, zoom)

  # event handlers

  selectionMade: (e) =>
    e.camera = @surface.camera
    @lastSelection = e

  done: =>
    @callback?(@lastSelection)
    @hide()

  onHidden: ->
    @surface?.destroy()
