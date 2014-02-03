ProblemAlertView = require './problem_alert_view'
Range = ace.require("ace/range").Range

module.exports = class Problem
  annotation: null
  alertView: null
  markerRange: null
  constructor: (@aether, @aetherProblem, @ace, withAlert=false, withRange=false) ->
    @buildAnnotation()
    @buildAlertView() if withAlert
    @buildMarkerRange() if withRange

  destroy: ->
    @alertView?.$el.remove()
    @alertView?.destroy()
    @removeMarkerRange()

  buildAnnotation: ->
    return unless @aetherProblem.ranges
    text = @aetherProblem.message.replace /^Line \d+: /, ''
    start = @aetherProblem.ranges[0][0]
    @annotation =
      row: start.row,
      column: start.col,
      raw: text,
      text: text,
      type: @aetherProblem.level ? "error"

  buildAlertView: ->
    @alertView = new ProblemAlertView problem: @
    @alertView.render()
    $(@ace.container).append @alertView.el

  buildMarkerRange: ->
    return unless @aetherProblem.ranges
    [start, end] = @aetherProblem.ranges[0]
    clazz = "problem-marker-#{@aetherProblem.level}"
    @markerRange = new Range start.row, start.col, end.row, end.col
    @markerRange.start = @ace.getSession().getDocument().createAnchor @markerRange.start
    @markerRange.end = @ace.getSession().getDocument().createAnchor @markerRange.end
    @markerRange.id = @ace.getSession().addMarker @markerRange, clazz, "text"

  removeMarkerRange: ->
    return unless @markerRange
    @ace.getSession().removeMarker @markerRange.id
    @markerRange.start.detach()
    @markerRange.end.detach()
