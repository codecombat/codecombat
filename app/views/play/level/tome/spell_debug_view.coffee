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
    @globals = {Math: Math, _: _, String: String, Number: Number, Array: Array, Object: Object}  # ... add more as documented
    for className, klass of serializedClasses
      @globals[className] = klass
    @onMouseMove = _.throttle @onMouseMove, 25

  afterRender: ->
    super()
    @ace.on "mousemove", @onMouseMove

  setVariableStates: (@variableStates) ->
    @update()

  isIdentifier: (t) ->
    t and (t.type is 'identifier' or t.value is 'this' or @globals[t.value])

  onMouseMove: (e) =>
    return if @destroyed
    pos = e.getDocumentPosition()
    it = new TokenIterator e.editor.session, pos.row, pos.column
    endOfLine = it.getCurrentToken()?.index is it.$rowTokens.length - 1
    while it.getCurrentTokenRow() is pos.row and not @isIdentifier(token = it.getCurrentToken())
      break if endOfLine or not token  # Don't iterate beyond end or beginning of line
      it.stepBackward()
    if @isIdentifier token
      # This could be a property access, like "enemy.target.pos" or "this.spawnedRectangles".
      # We have to realize this and dig into the nesting of the objects.
      start = it.getCurrentTokenColumn()
      [chain, start, end] = [[token.value], start, start + token.value.length]
      while it.getCurrentTokenRow() is pos.row
        it.stepBackward()
        break unless it.getCurrentToken()?.value is "."
        it.stepBackward()
        token = null  # If we're doing a complex access like this.getEnemies().length, then length isn't a valid var.
        break unless @isIdentifier(prev = it.getCurrentToken())
        token = prev
        start = it.getCurrentTokenColumn()
        chain.unshift token.value
    if token and (token.value of @variableStates or token.value is "this" or @globals[token.value])
      @variableChain = chain
      offsetX = e.domEvent.offsetX ? e.clientX - $(e.domEvent.target).offset().left
      offsetY = e.domEvent.offsetY ? e.clientY - $(e.domEvent.target).offset().top
      w = $(document).width()
      offsetX = w - $(e.domEvent.target).offset().left - 300 if e.clientX + 300 > w
      @pos = {left: offsetX + 50, top: offsetY + 20}
      @markerRange = new Range pos.row, start, pos.row, end
    else
      @variableChain = @markerRange = null
    @update()

  onMouseOut: (e) ->
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
    if @variableChain?.length is 2
      clearTimeout @hoveredPropertyTimeout if @hoveredPropertyTimeout
      @hoveredPropertyTimeout = _.delay @notifyPropertyHovered, 500
    else
      @notifyPropertyHovered()
    @updateMarker()

  notifyPropertyHovered: =>
    clearTimeout @hoveredPropertyTimeout if @hoveredPropertyTimeout
    @hoveredPropertyTimeout = null
    oldHoveredProperty = @hoveredProperty
    @hoveredProperty = if @variableChain?.length is 2 then owner: @variableChain[0], property: @variableChain[1] else {}
    unless _.isEqual oldHoveredProperty, @hoveredProperty
      Backbone.Mediator.publish 'tome:spell-debug-property-hovered', @hoveredProperty

  updateMarker: ->
    if @marker
      @ace.getSession().removeMarker @marker
      @marker = null
    if @markerRange
      @marker = @ace.getSession().addMarker @markerRange, "ace_bracket", "text"

  stringifyValue: (value, depth) ->
    return value if not value or _.isString value
    if _.isFunction value
      return if depth is 2 then undefined else "<Function>"
    return "<this #{value.id}>" if value is @thang and depth
    if depth is 2
      if value.constructor?.className is "Thang"
        value = "<#{value.type or value.spriteName} - #{value.id}, #{if value.pos then value.pos.toString() else 'non-physical'}>"
      else
        value = value.toString()
      return value

    isArray = _.isArray value
    isObject = _.isObject value
    return value.toString() unless isArray or isObject
    brackets = if isArray then ["[", "]"] else ["{", "}"]
    size = _.size value
    return brackets.join "" unless size
    values = []
    if isArray
      for v in value
        s = @stringifyValue(v, depth + 1)
        values.push "" + s unless s is undefined
    else
      for key in value.apiProperties ? _.keys value
        s = @stringifyValue(value[key], depth + 1)
        values.push key + ": " + s unless s is undefined
    sep = '\n' + ("  " for i in [0 ... depth]).join('')
    prefix = value.constructor?.className
    prefix ?= "Array" if isArray
    prefix ?= "Object" if isObject
    prefix = if prefix then prefix + " " else ""
    return "#{prefix}#{brackets[0]}#{sep}  #{values.join(sep + '  ')}#{sep}#{brackets[1]}"

  deserializeVariableChain: (chain) ->
    keys = []
    for prop, i in chain
      if prop is "this"
        value = @thang
      else if i is 0
        value = @variableStates[prop]
        if typeof value is "undefined" then value = @globals[prop]
      else
        value = value[prop]
      keys.push prop
      break unless value
      if theClass = serializedClasses[value.CN]
        if value.CN is "Thang"
          thang = @thang.world.thangMap[value.id]
          value = thang or "<Thang #{value.id} (non-existent)>"
        else
          value = theClass.deserializeFromAether(value)
    value = @stringifyValue value, 0
    key: keys.join("."), value: value

  destroy: ->
    @ace?.removeEventListener "mousemove", @onMouseMove
    super()
