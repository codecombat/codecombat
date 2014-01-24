View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_debug'
Range = ace.require("ace/range").Range
TokenIterator = ace.require("ace/token_iterator").TokenIterator
serializedClasses =
  Thang: require "lib/world/thang"
  Vector: require "lib/world/vector"
  Rectangle: require "lib/world/rectangle"

module.exports = class DebugView extends View
  className: 'spell-debug-view'
  template: template

  subscriptions:
    'god:new-world-created': 'onNewWorld'

  events: {}

  constructor: (options) ->
    super options
    @ace = options.ace
    @thang = options.thang
    @variableStates = {}

  afterRender: ->
    super()
    @ace.on "mousemove", @onMouseMove
    #@ace.on "click", onClick  # same ACE API as mousemove

  setVariableStates: (@variableStates) ->
    @update()

  onMouseMove: (e) =>
    pos = e.getDocumentPosition()
    it = new TokenIterator e.editor.session, pos.row, pos.column
    isIdentifier = (t) -> t and (t.type is 'identifier' or t.value is 'this')
    while it.getCurrentTokenRow() is pos.row and not isIdentifier(token = it.getCurrentToken())
      it.stepBackward()
      break unless token
    if isIdentifier token
      # This could be a property access, like "enemy.target.pos" or "this.spawnedRectangles".
      # We have to realize this and dig into the nesting of the objects.
      start = it.getCurrentTokenColumn()
      [chain, start, end] = [[token.value], start, start + token.value.length]
      while it.getCurrentTokenRow() is pos.row
        it.stepBackward()
        break unless it.getCurrentToken()?.value is "."
        it.stepBackward()
        token = null  # If we're doing a complex access like this.getEnemies().length, then length isn't a valid var.
        break unless isIdentifier(prev = it.getCurrentToken())
        token = prev
        start = it.getCurrentTokenColumn()
        chain.unshift token.value
    if token and (token.value of @variableStates or token.value is "this")
      @variableChain = chain
      @pos = {left: e.domEvent.offsetX + 50, top: e.domEvent.offsetY + 50}
      @markerRange = new Range pos.row, start, pos.row, end
    else
      @variableChain = @markerRange = null
    @update()

  onMouseOut: (e) =>
    @variableChain = @markerRange = null
    @update()

  onNewWorld: (e) ->
    @thang = @options.thang = e.world.thangMap[@thang.id] if @thang

  update: ->
    if @variableChain
      {key, value} = @deserializeVariableChain @variableChain
      @$el.find("code").text "#{key}: #{value}"
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

  deserializeVariableChain: (chain) ->
    keys = []
    for prop, i in chain
      if prop is "this"
        value = @thang
      else
        value = (if i is 0 then @variableStates else value)[prop]
      keys.push prop
      break unless value
      if theClass = serializedClasses[value.CN]
        if value.CN is "Thang"
          thang = @thang.world.thangMap[value.id]
          value = thang or "<Thang #{value.id} (non-existent)>"
        else
          value = theClass.deserializeFromAether(value)
    if value and not _.isString value
      if value.constructor?.className is "Thang"
        value = "<#{value.spriteName} - #{value.id}, #{if value.pos then value.pos.toString() else 'non-physical'}>"
      else
        value = value.toString()
    key: keys.join("."), value: value

  destroy: ->
    super()
    @ace?.removeEventListener "mousemove", @onMouseMove
