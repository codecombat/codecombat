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
  @TRANSFORM_CHILD = 'child'  # Layer transform is managed by its parents
  @TRANSFORM_SURFACE = 'surface'  # Layer moves/scales/zooms with the Surface of the World
  @TRANSFORM_SURFACE_TEXT = 'surface_text'  # Layer moves with the Surface but is size-independent
  @TRANSFORM_SCREEN = 'screen'  # Layer stays fixed to the screen (different from child?)

  subscriptions:
    'camera:zoom-updated': 'onZoomUpdated'

  constructor: (options) ->
    super()
    @initialize()
    options ?= {}
    @name = options.name ? 'Unnamed'
    @layerPriority = options.layerPriority ? 0
    @transformStyle = options.transform ? Layer.TRANSFORM_CHILD
    @camera = options.camera
    console.error @toString(), 'needs a camera.' unless @camera
    @updateLayerOrder = _.throttle @updateLayerOrder, 1000 / 30  # Don't call multiple times in one frame; 30 FPS is probably good enough
    Backbone.Mediator.subscribe(channel, @[func], @) for channel, func of @subscriptions

  destroy: ->
    child.destroy?() for child in @children
    Backbone.Mediator.unsubscribe(channel, @[func], @) for channel, func of @subscriptions
    delete @updateLayerOrder

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
    #console.log @, @toString(), 'sorting children', _.clone @children if @name is 'Default'
    @sortChildren @layerOrderComparator

  layerOrderComparator: (a, b) ->
    # Optimize
    alp = a.layerPriority or 0
    blp = b.layerPriority or 0
    return alp - blp if alp isnt blp
    # TODO: remove this z stuff
    az = a.z or 1000
    bz = b.z or 1000
    if aSprite = a.sprite
      if aThang = aSprite.thang
        aPos = aThang.pos
        if aThang.health < 0
          --az
    if bSprite = b.sprite
      if bThang = bSprite.thang
        bPos = bThang.pos
        if bThang.health < 0
          --bz
    if az is bz
      return 0 unless aPos and bPos
      return (bPos.y - aPos.y) or (bPos.x - aPos.x)
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
    return unless bounds
    super bounds.x, bounds.y, bounds.width, bounds.height, 2
