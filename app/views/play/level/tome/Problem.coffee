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
    @removeMarkerRanges()
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
    textClazz = "problem-marker-#{@aetherProblem.level}"
    @textMarkerRange = new Range start.row, start.col, end.row, end.col
    @textMarkerRange.start = @ace.getSession().getDocument().createAnchor @textMarkerRange.start
    @textMarkerRange.end = @ace.getSession().getDocument().createAnchor @textMarkerRange.end
    @textMarkerRange.id = @ace.getSession().addMarker @textMarkerRange, textClazz, 'text'
    lineClazz = "problem-line"
    @lineMarkerRange = new Range start.row, start.col, end.row, end.col
    @lineMarkerRange.start = @ace.getSession().getDocument().createAnchor @lineMarkerRange.start
    @lineMarkerRange.end = @ace.getSession().getDocument().createAnchor @lineMarkerRange.end
    @lineMarkerRange.id = @ace.getSession().addMarker @lineMarkerRange, lineClazz, 'fullLine'

  removeMarkerRanges: ->
    if @textMarkerRange
      @ace.getSession().removeMarker @textMarkerRange.id
      @textMarkerRange.start.detach()
      @textMarkerRange.end.detach()
    if @lineMarkerRange
      @ace.getSession().removeMarker @lineMarkerRange.id
      @lineMarkerRange.start.detach()
      @lineMarkerRange.end.detach()
