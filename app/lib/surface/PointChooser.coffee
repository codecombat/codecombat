CocoClass = require 'core/CocoClass'
createjs = require 'lib/createjs-parts'

module.exports = class PointChooser extends CocoClass
  constructor: (@options) ->
    super()
    @buildShape()
    @options.stage.addEventListener 'stagemousedown', @onMouseDown
    @options.camera.dragDisabled = true

  destroy: ->
    @options.stage.removeEventListener 'stagemousedown', @onMouseDown
    super()

  # Called also from WorldSelectModal
  setPoint: (@point) ->
    @updateShape()

  buildShape: ->
    @shape = new createjs.Shape()
    @shape.alpha = 0.9
    @shape.mouseEnabled = false
    @shape.graphics.setStrokeStyle(1, 'round').beginStroke('#000000').beginFill('#fedcba')
    @shape.graphics.drawCircle(0, 0, 4).endFill()

  onMouseDown: (e) =>
    return unless key.shift
    @setPoint @options.camera.screenToWorld {x: e.stageX, y: e.stageY}
    Backbone.Mediator.publish 'surface:choose-point', point: @point

  updateShape: ->
    sup = @options.camera.worldToSurface @point
    @options.surfaceLayer.addChild @shape unless @shape.parent
    @shape.x = sup.x
    @shape.y = sup.y
