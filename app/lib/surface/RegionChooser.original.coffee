CocoClass = require 'core/CocoClass'
Camera = require './Camera'
createjs = require 'lib/createjs-parts'

module.exports = class RegionChooser extends CocoClass
  constructor: (@options) ->
    super()
    @options.stage.addEventListener 'stagemousedown', @onMouseDown
    @options.stage.addEventListener 'stagemousemove', @onMouseMove
    @options.stage.addEventListener 'stagemouseup', @onMouseUp

  destroy: ->
    @options.stage.removeEventListener 'stagemousedown', @onMouseDown
    @options.stage.removeEventListener 'stagemousemove', @onMouseMove
    @options.stage.removeEventListener 'stagemouseup', @onMouseUp
    super()

  onMouseDown: (e) =>
    return unless key.shift
    @firstPoint = @options.camera.screenToWorld {x: e.stageX, y: e.stageY}
    @options.camera.dragDisabled = true

  onMouseMove: (e) =>
    return unless @firstPoint
    @secondPoint = @options.camera.screenToWorld {x: e.stageX, y: e.stageY}
    @restrictRegion() if @options.restrictRatio or key.alt
    @updateShape()

  onMouseUp: (e) =>
    return unless @firstPoint
    Backbone.Mediator.publish 'surface:choose-region', points: [@firstPoint, @secondPoint]
    @firstPoint = null
    @secondPoint = null
    @options.camera.dragDisabled = false

  restrictRegion: ->
    RATIO = 1.56876  # 924 / 589
    rect = @options.camera.normalizeBounds([@firstPoint, @secondPoint])
    currentRatio = rect.width / rect.height
    if currentRatio > RATIO
      # increase the height
      targetSurfaceHeight = rect.width / RATIO
      targetWorldHeight = targetSurfaceHeight * Camera.MPP * @options.camera.x2y
      targetWorldHeight *= -1 if @secondPoint.y < @firstPoint.y
      @secondPoint.y = @firstPoint.y + targetWorldHeight
    else
      # increase the width
      targetSurfaceWidth = rect.height * RATIO
      targetWorldWidth =  targetSurfaceWidth * Camera.MPP
      targetWorldWidth *= -1 if @secondPoint.x < @firstPoint.x
      @secondPoint.x = @firstPoint.x + targetWorldWidth

  # Called from WorldSelectModal
  setRegion: (worldPoints) ->
    @firstPoint = worldPoints[0]
    @secondPoint = worldPoints[1]
    @updateShape()
    @firstPoint = null
    @secondPoint = null

  updateShape: ->
    rect = @options.camera.normalizeBounds([@firstPoint, @secondPoint])
    @options.surfaceLayer.removeChild @shape if @shape
    @shape = new createjs.Shape()
    @shape.alpha = 0.5
    @shape.mouseEnabled = false
    @shape.graphics.beginFill('#fedcba').drawRect rect.x, rect.y, rect.width, rect.height
    @shape.graphics.endFill()
    @shape.skipScaling = true
    @options.surfaceLayer.addChild(@shape)
