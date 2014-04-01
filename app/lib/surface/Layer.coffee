###
* Stage
** surfaceLayer
*** Land texture
*** Ground-based selection/target marks, range radii
*** Walls/obstacles
*** Paths and target pieces (and ghosts?)
*** Normal Thangs, bots, wizards (z-indexing based on World-determined sprite.thang.pos.z/y, mainly, instead of sprite-map-determined sprite.z, which we rename to... something)
*** Above-thang marks (blood, highlight) and health bars
*** Camera border
** surfaceTextLayer (speech, names)
** screenLayer
*** Letterbox
**** Letterbox top and bottom
*** FPS display, maybe grid axis labels, coordinate hover

** Grid lines--somewhere--we will figure it out, do not really need it at first
###

module.exports = class Layer extends createjs.Container
  @TRANSFORM_CHILD = "child"  # Layer transform is managed by its parents
  @TRANSFORM_SURFACE = "surface"  # Layer moves/scales/zooms with the Surface of the World
  @TRANSFORM_SURFACE_TEXT = "surface_text"  # Layer moves with the Surface but is size-independent
  @TRANSFORM_SCREEN = "screen"  # Layer stays fixed to the screen (different from child?)

  subscriptions:
    'camera:zoom-updated': 'onZoomUpdated'

  constructor: (options) ->
    super()
    @initialize()
    options ?= {}
    @name = options.name ? "Unnamed"
    @layerPriority = options.layerPriority ? 0
    @transformStyle = options.transform ? Layer.TRANSFORM_CHILD
    @camera = options.camera
    console.error @toString(), "needs a camera." unless @camera
    @updateLayerOrder = _.throttle @updateLayerOrder, 1  # don't call multiple times in one frame
    Backbone.Mediator.subscribe(channel, @[func], @) for channel, func of @subscriptions

  destroy: ->
    child.destroy?() for child in @children
    Backbone.Mediator.unsubscribe(channel, @[func], @) for channel, func of @subscriptions

  toString: -> "<Layer #{@layerPriority}: #{@name}>"

  addChild: (children...) ->
    super children...
    if @transformStyle is Layer.TRANSFORM_SURFACE_TEXT
      for child in children
        child.scaleX /= @scaleX
        child.scaleY /= @scaleY

  removeChild: (children...) ->
    super children...
    if @transformStyle is Layer.TRANSFORM_SURFACE_TEXT
      for child in children
        child.scaleX *= @scaleX
        child.scaleY *= @scaleY

  updateLayerOrder: =>
    #console.log @, @toString(), "sorting children", _.clone @children if @name is 'Default'
    @sortChildren (a, b) ->
      alp = a.layerPriority ? 0
      blp = b.layerPriority ? 0
      return alp - blp if alp isnt blp
      # TODO: remove this z stuff
      az = if a.z then a.z else 1000
      bz = if b.z then b.z else 1000
      aThang = a.sprite?.thang
      bThang = b.sprite?.thang
      az -= 1 if aThang?.health < 0
      bz -= 1 if bThang?.health < 0
      if az == bz
        return 0 unless aThang?.pos and bThang?.pos
        return (bThang.pos.y - aThang.pos.y) or (bThang.pos.x - aThang.pos.x)
      return az - bz

  onZoomUpdated: (e) ->
    return unless e.camera is @camera
    if @transformStyle in [Layer.TRANSFORM_SURFACE, Layer.TRANSFORM_SURFACE_TEXT]
      change = @scaleX / e.zoom
      @scaleX = @scaleY = e.zoom
      @regX = e.surfaceViewport.x
      @regY = e.surfaceViewport.y
      if @transformStyle is Layer.TRANSFORM_SURFACE_TEXT
        for child in @children
          child.scaleX *= change
          child.scaleY *= change

  cache: ->
    return unless @children.length
    bounds = @getBounds()
    super bounds.x, bounds.y, bounds.width, bounds.height, 2
