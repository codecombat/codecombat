ProblemAlertView = require './ProblemAlertView'
Range = ace.require('ace/range').Range
UserCodeProblem = require 'models/UserCodeProblem'

module.exports = class Problem
  annotation: null
  alertView: null
  markerRange: null
  constructor: (@aether, @aetherProblem, @ace, withAlert=false, isCast=false, @levelID) ->
    @buildAnnotation()
    @buildAlertView() if withAlert
    @buildMarkerRange() if isCast
    @saveUserCodeProblem() if isCast

  destroy: ->
    unless @alertView?.destroyed
      @alertView?.$el?.remove()
      @alertView?.destroy()
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

  buildAlertView: ->
    @alertView = new ProblemAlertView problem: @
    @alertView.render()
    $(@ace.container).append @alertView.el

  buildMarkerRange: ->
    return unless @aetherProblem.range
    [start, end] = @aetherProblem.range
    clazz = "problem-marker-#{@aetherProblem.level}"
    @markerRange = new Range start.row, start.col, end.row, end.col
    @markerRange.start = @ace.getSession().getDocument().createAnchor @markerRange.start
    @markerRange.end = @ace.getSession().getDocument().createAnchor @markerRange.end
    @markerRange.id = @ace.getSession().addMarker @markerRange, clazz, 'text'

  removeMarkerRange: ->
    return unless @markerRange
    @ace.getSession().removeMarker @markerRange.id
    @markerRange.start.detach()
    @markerRange.end.detach()

  saveUserCodeProblem: () ->
    @userCodeProblem = new UserCodeProblem()
    @userCodeProblem.set 'code', @aether.raw
    if @aetherProblem.range
      rawLines = @aether.raw.split '\n'
      errorLines = rawLines.slice @aetherProblem.range[0].row, @aetherProblem.range[1].row + 1
      @userCodeProblem.set 'codeSnippet', errorLines.join '\n'
    @userCodeProblem.set 'errHint', @aetherProblem.hint if @aetherProblem.hint
    @userCodeProblem.set 'errId', @aetherProblem.id if @aetherProblem.id
    @userCodeProblem.set 'errLevel', @aetherProblem.level if @aetherProblem.level
    @userCodeProblem.set 'errMessage', @aetherProblem.message if @aetherProblem.message
    @userCodeProblem.set 'errRange', @aetherProblem.range if @aetherProblem.range
    @userCodeProblem.set 'errType', @aetherProblem.type if @aetherProblem.type
    @userCodeProblem.set 'language', @aether.language.id if @aether.language?.id
    @userCodeProblem.set 'levelID', @levelID if @levelID
    @userCodeProblem.save()
    null