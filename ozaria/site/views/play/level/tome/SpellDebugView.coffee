CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/tome/spell_debug'
ace = require('lib/aceContainer')
Range = ace.require('ace/range').Range
TokenIterator = ace.require('ace/token_iterator').TokenIterator
serializedClasses =
  Thang: require 'lib/world/thang'
  Vector: require 'lib/world/vector'
  Rectangle: require 'lib/world/rectangle'
  Ellipse: require 'lib/world/ellipse'
  LineSegment: require 'lib/world/line_segment'

module.exports = class SpellDebugView extends CocoView
  className: 'spell-debug-view'
  template: template

  subscriptions:
    'god:new-world-created': 'onNewWorld'
    'god:debug-value-return': 'handleDebugValue'
    'god:debug-world-load-progress-changed': 'handleWorldLoadProgressChanged'
    'tome:cast-spells': 'onTomeCast'
    'surface:frame-changed': 'onFrameChanged'
    'tome:spell-has-changed-significantly-calculation': 'onSpellChangedCalculation'

  events: {}

  constructor: (options) ->
    super options
    @ace = options.ace
    @thang = options.thang
    @spell = options.spell
    @progress = 0
    @variableStates = {}
    @globals = {Math: Math, _: _, String: String, Number: Number, Array: Array, Object: Object}  # ... add more as documented
    for className, serializedClass of serializedClasses
      @globals[className] = serializedClass

    @onMouseMove = _.throttle @onMouseMove, 25
    @cache = {}
    @lastFrameRequested = -1
    @workerIsSimulating = false
    @spellHasChanged = false
    @currentFrame = 0
    @frameRate = 10 #only time it won't be set is at very beginning
    @debouncedTooltipUpdate = _.debounce @updateTooltipProgress, 100

  pad2: (num) ->
    if not num? or num is 0 then '00' else ((if num < 10 then '0' else '') + num)

  calculateCurrentTimeString: =>
    time = @currentFrame / @frameRate
    mins = Math.floor(time / 60)
    secs = (time - mins * 60).toFixed(1)
    "#{mins}:#{@pad2 secs}"

  setTooltipKeyAndValue: (key, value) =>
    @hideProgressBarAndShowText()
    message = "Time: #{@calculateCurrentTimeString()}\n#{key}: #{value}"
    @$el.find('code').text message
    @$el.show().css(@pos)

  setTooltipText: (text) =>
    #perhaps changing styling here in the future
    @hideProgressBarAndShowText()
    @$el.find('code').text text
    @$el.show().css(@pos)

  setTooltipProgress: (progress) =>
    @showProgressBarAndHideText()
    @$el.find('.progress-bar').css('width', progress + '%').attr 'aria-valuenow', progress
    @$el.show().css(@pos)

  showProgressBarAndHideText: ->
    @$el.find('pre').css('display', 'none')
    @$el.find('.progress').css('display', 'block')

  hideProgressBarAndShowText: ->
    @$el.find('pre').css('display', 'block')
    @$el.find('.progress').css('display', 'none')

  onTomeCast: ->
    @invalidateCache()

  invalidateCache: -> @cache = {}

  retrieveValueFromCache: (thangID, spellID, variableChain, frame) ->
    joinedVariableChain = variableChain.join()
    value = @cache[frame]?[thangID]?[spellID]?[joinedVariableChain]
    return value ? undefined

  updateCache: (thangID, spellID, variableChain, frame, value) ->
    currentObject = @cache
    keys = [frame, thangID, spellID, variableChain.join()]
    for keyIndex in [0...(keys.length - 1)]
      key = keys[keyIndex]
      unless key of currentObject
        currentObject[key] = {}
      currentObject = currentObject[key]
    currentObject[keys[keys.length - 1]] = value

  handleDebugValue: (e) ->
    {key, value} = e
    @workerIsSimulating = false
    @updateCache(@thang.id, @spell.name, key.split('.'), @lastFrameRequested, value)
    if @variableChain and not key is @variableChain.join('.') then return
    @setTooltipKeyAndValue(key, value)

  handleWorldLoadProgressChanged: (e) ->
    @progress = e.progress

  afterRender: ->
    super()
    @ace.on 'mousemove', @onMouseMove

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
      # This could be a property access, like 'enemy.target.pos' or 'this.spawnedRectangles'.
      # We have to realize this and dig into the nesting of the objects.
      start = it.getCurrentTokenColumn()
      [chain, start, end] = [[token.value], start, start + token.value.length]
      while it.getCurrentTokenRow() is pos.row
        it.stepBackward()
        break unless it.getCurrentToken()?.value is '.'
        it.stepBackward()
        token = null  # If we're doing a complex access like this.getEnemies().length, then length isn't a valid var.
        break unless @isIdentifier(prev = it.getCurrentToken())
        token = prev
        start = it.getCurrentTokenColumn()
        chain.unshift token.value
    #Highlight all tokens, so true overrides all other conditions TODO: Refactor this later
    if token and (true or token.value of @variableStates or token.value is 'this' or @globals[token.value])
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

  updateTooltipProgress: =>
    if @variableChain and @progress < 1
      @setTooltipProgress(@progress * 100)
      _.delay @updateTooltipProgress, 100

  onNewWorld: (e) ->
    @thang = @options.thang = e.world.thangMap[@thang.id] if @thang
    @frameRate = e.world.frameRate

  onFrameChanged: (data) ->
    @currentFrame = Math.round(data.frame)
    @frameRate = data.world.frameRate

  onSpellChangedCalculation: (data) ->
    @spellHasChanged = data.hasChangedSignificantly

  update: ->
    if @variableChain
      if @spellHasChanged
        @setTooltipText('You\'ve changed this spell! \nPlease recast to use the hover debugger.')
      else if @variableChain.length is 2 and @variableChain[0] is 'this'
        @setTooltipKeyAndValue(@variableChain.join('.'), @stringifyValue(@thang[@variableChain[1]], 0))
      else if @variableChain.length is 1 and Aether.globals[@variableChain[0]]
        @setTooltipKeyAndValue(@variableChain.join('.'), @stringifyValue(Aether.globals[@variableChain[0]], 0))
      else if @workerIsSimulating and @progress < 1
        @debouncedTooltipUpdate()
      else if @currentFrame is @lastFrameRequested and (cacheValue = @retrieveValueFromCache(@thang.id, @spell.name, @variableChain, @currentFrame))
        @setTooltipKeyAndValue(@variableChain.join('.'), cacheValue)
      else
        Backbone.Mediator.publish 'tome:spell-debug-value-request',
          thangID: @thang.id
          spellID: @spell.name
          variableChain: @variableChain
          frame: @currentFrame
        if @currentFrame isnt @lastFrameRequested then @workerIsSimulating = true
        @lastFrameRequested = @currentFrame
        @progress = 0
        @debouncedTooltipUpdate()
    else
      @$el.hide()
    if @variableChain?.length is 2
      clearTimeout @hoveredPropertyTimeout if @hoveredPropertyTimeout
      @hoveredPropertyTimeout = _.delay @notifyPropertyHovered, 500
    else
      @notifyPropertyHovered()
    @updateMarker()

  stringifyValue: (value, depth) ->
    return value if not value or _.isString value
    if _.isFunction value
      return if depth is 2 then undefined else '<Function>'
    return "<this #{value.id}>" if value is @thang and depth
    if depth is 2
      if value.constructor?.className is 'Thang'
        value = "<#{value.type or value.spriteName} - #{value.id}, #{if value.pos then value.pos.toString() else 'non-physical'}>"
      else
        value = value.toString()
      return value

    isArray = _.isArray value
    isObject = _.isObject value
    return value.toString() unless isArray or isObject
    brackets = if isArray then ['[', ']'] else ['{', '}']
    size = _.size value
    return brackets.join '' unless size
    values = []
    if isArray
      for v in value
        s = @stringifyValue(v, depth + 1)
        values.push '' + s unless s is undefined
    else
      for key in value.apiProperties ? _.keys value
        s = @stringifyValue(value[key], depth + 1)
        values.push key + ': ' + s unless s is undefined
    sep = '\n' + ('  ' for i in [0 ... depth]).join('')
    prefix = value.constructor?.className
    prefix ?= 'Array' if isArray
    prefix ?= 'Object' if isObject
    prefix = if prefix then prefix + ' ' else ''
    return "#{prefix}#{brackets[0]}#{sep}  #{values.join(sep + '  ')}#{sep}#{brackets[1]}"
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
      @marker = @ace.getSession().addMarker @markerRange, 'ace_bracket', 'text'


  destroy: ->
    @ace?.removeEventListener 'mousemove', @onMouseMove
    super()
