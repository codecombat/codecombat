CocoClass = require 'core/CocoClass'
createjs = require 'lib/createjs-parts'

module.exports = class CoordinateGrid extends CocoClass
  subscriptions:
    'level:toggle-grid': 'onToggleGrid'

  shortcuts:
    'ctrl+g, ⌘+g': 'onToggleGrid'

  constructor: (options, worldSize) ->
    super()
    options ?= {}
    @camera = options.camera
    @layer = options.layer
    @textLayer = options.textLayer
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    console.error @toString(), 'needs a textLayer.' unless @textLayer
    @build worldSize

  destroy: ->
    super()

  toString: -> '<CoordinateGrid>'

  build: (worldSize) ->
    worldWidth = worldSize[0] or 80
    worldHeight = worldSize[1] or 68
    @gridContainer = new createjs.Container()
    @gridShape = new createjs.Shape()
    @gridContainer.addChild @gridShape
    @gridContainer.mouseEnabled = false
    @gridShape.alpha = 0.125
    @gridShape.graphics.setStrokeStyle 1
    @gridShape.graphics.beginStroke 'blue'
    gridSize = Math.round(worldWidth / 20)
    wopStart = x: 0, y: 0
    wopEnd = x: worldWidth, y: worldHeight
    supStart = @camera.worldToSurface wopStart
    supEnd = @camera.worldToSurface wopEnd
    wop = x: wopStart.x, y: wopStart.y
    @labels = []
    linesDrawn = 0
    while wop.x <= wopEnd.x
      sup = @camera.worldToSurface wop
      @gridShape.graphics.mt(sup.x, supStart.y).lt(sup.x, supEnd.y)
      if ++linesDrawn % 2
        t = new createjs.Text(wop.x.toFixed(0), '16px Arial', 'blue')
        t.textAlign = 'center'
        t.textBaseline = 'bottom'
        t.x = sup.x
        t.y = supStart.y
        t.alpha = 0.75
        @labels.push t
      wop.x += gridSize
      if wopEnd.x < wop.x <= wopEnd.x - gridSize / 2
        wop.x = wopEnd.x
    linesDrawn = 0
    while wop.y <= wopEnd.y
      sup = @camera.worldToSurface wop
      @gridShape.graphics.mt(supStart.x, sup.y).lt(supEnd.x, sup.y)
      if ++linesDrawn % 2
        t = new createjs.Text(wop.y.toFixed(0), '16px Arial', 'blue')
        t.textAlign = 'left'
        t.textBaseline = 'middle'
        t.x = 0
        t.y = sup.y
        t.alpha = 0.75
        @labels.push t
      wop.y += gridSize
      if wopEnd.y < wop.y <= wopEnd.y - gridSize / 2
        wop.y = wopEnd.y
    @gridShape.graphics.endStroke()
    bounds = x: supStart.x, y: supEnd.y, width: supEnd.x - supStart.x, height: supStart.y - supEnd.y
    return unless bounds?.width and bounds.height
    @gridContainer.cache bounds.x, bounds.y, bounds.width, bounds.height

  showGrid: ->
    return if @gridShowing()
    @layer.addChild @gridContainer
    @textLayer.addChild label for label in @labels

  hideGrid: ->
    return unless @gridShowing()
    @layer.removeChild @gridContainer
    @textLayer.removeChild label for label in @labels

  gridShowing: ->
    @gridContainer?.parent?

  onToggleGrid: (e) ->
    e?.preventDefault?()
    if @gridShowing() then @hideGrid() else @showGrid()

