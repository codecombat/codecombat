View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/debug'

module.exports = class DebugView extends View
  className: 'tome-debug-view'
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

  setVariableStates: (@variableStates) ->
    @update()

  onMouseMove: (e) =>
    pos = e.getDocumentPosition()
    token = e.editor.session.getTokenAt pos.row, pos.column
    if token?.type is 'identifier' and token.value of @variableStates
      @variable = token.value
      @pos = {left: e.domEvent.offsetX + 50, top: e.domEvent.offsetY + 10}
    else
      @variable = null
    @update()

  update: ->
    if @variable
      value = @variableStates[@variable]
      @$el.find("h3").text "#{@variable}: #{value}"
      @$el.show().css(@pos)
    else
      @$el.hide()

  destroy: ->
    super()
    @ace?.removeEventListener "mousemove", @onMouseMove
