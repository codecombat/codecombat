View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_debug'
Range = ace.require("ace/range").Range

module.exports = class DebugView extends View
  className: 'spell-debug-view'
  template: template
  subscriptions: {}
  events: {}

  constructor: (options) ->
    super options
    @ace = options.ace
    @variableStates = {}

  afterRender: ->
    super()
    @ace.on "mousemove", @onMouseMove
    #@ace.on "click", onClick  # same ACE API as mousemove

  setVariableStates: (@variableStates) ->
    @update()

  onMouseMove: (e) =>
    pos = e.getDocumentPosition()
    column = pos.column
    until column < 0
      if token = e.editor.session.getTokenAt pos.row, column
        break if token.type is 'identifier'
        column = token.start - 1
      else
        --column
    if token?.type is 'identifier' and token.value of @variableStates
      @variable = token.value
      @pos = {left: e.domEvent.offsetX + 50, top: e.domEvent.offsetY + 50}
      @markerRange = new Range pos.row, token.start, pos.row, token.start + token.value.length
    else
      @variable = @markerRange = null
    @update()

  onMouseOut: (e) =>
    @variable = @markerRange = null
    @update()

  update: ->
    if @variable
      value = @variableStates[@variable]
      @$el.find("code").text "#{@variable}: #{value}"
      @$el.show().css(@pos)
    else
      @$el.hide()
    @updateMarker()

  updateMarker: ->
    if @marker
      @ace.getSession().removeMarker @marker
      @marker = null
    if @markerRange
      @marker = @ace.getSession().addMarker @markerRange, "ace_bracket", "text"

  destroy: ->
    super()
    @ace?.removeEventListener "mousemove", @onMouseMove
