Range = ace.require('ace/range').Range

module.exports = class Problem
  annotation: null
  markerRange: null
  constructor: (@aether, @aetherProblem, @ace, isCast=false, @levelID) ->
    @buildAnnotation()
    @buildMarkerRange() if isCast
    # TODO: get ACE screen line, too, for positioning, since any multiline "lines" will mess up positioning
    Backbone.Mediator.publish("problem:problem-created", line: @annotation.row, text: @annotation.text) if application.isIPadApp

  destroy: ->
    @removeMarkerRange()
    @userCodeProblem.off() if @userCodeProblem

  buildAnnotation: ->
    return unless @aetherProblem.range
    text = @aetherProblem.message.replace /^Line \d+: /, ''
    start = @aetherProblem.range[0]
    @annotation =
      row: start.row,
      column: start.col,
      raw: text,
      text: text,
      type: @aetherProblem.level ? 'error'

  buildMarkerRange: ->
    return unless @aetherProblem.range
    [start, end] = @aetherProblem.range
    clazz = "problem-marker-#{@aetherProblem.level}"
    @markerRange = new Range start.row, start.col, end.row, end.col
    @markerRange.start = @ace.getSession().getDocument().createAnchor @markerRange.start
    @markerRange.end = @ace.getSession().getDocument().createAnchor @markerRange.end
    @markerRange.id = @ace.getSession().addMarker @markerRange, clazz, 'fullLine'

  removeMarkerRange: ->
    return unless @markerRange
    @ace.getSession().removeMarker @markerRange.id
    @markerRange.start.detach()
    @markerRange.end.detach()
