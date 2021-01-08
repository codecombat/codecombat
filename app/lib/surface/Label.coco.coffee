CocoClass = require 'core/CocoClass'
createjs = require 'lib/createjs-parts'

module.exports = class Label extends CocoClass
  @STYLE_DIALOGUE = 'dialogue'  # A speech bubble from a script
  @STYLE_SAY = 'say'  # A piece of text generated from the world
  @STYLE_NAME = 'name'  # A name like Scott set up for the Wizard
  # We might want to combine 'say' and 'name'; they're very similar
  # Nick designed 'say' based off of Scott's 'name' back when they were using two systems
  @STYLE_VAR = 'variable'

  @BITMAP_SPACE = 20 # Size extenstion for speech bubbles for box pointers

  subscriptions: {}

  constructor: (options) ->
    super()
    options ?= {}
    @sprite = options.sprite
    @camera = options.camera
    @layer = options.layer
    @style = options.style ? (@sprite?.thang?.labelStyle || Label.STYLE_SAY)
    @labelOptions = options.labelOptions ? {}
    @returnBounds = @labelOptions.returnBounds
    console.error @toString(), 'needs a sprite.' unless @sprite
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @setText options.text if options.text

  destroy: ->
    @setText null
    super()

  toString: -> "<Label for #{@sprite?.thang?.id ? 'None'}: #{@text?.substring(0, 10) ? ''}>"

  setText: (text) ->
    # Returns whether an update was actually performed
    return false if text is @text
    @text = text
    @build()
    true

  build: ->
    if @layer and not @layer.destroyed
      @layer.removeChild @background if @background
      @layer.removeChild @label if @label
    @label = null
    @background = null
    return unless @text  # null or '' should both be skipped
    o = @buildLabelOptions()
    @layer.addChild @label = @buildLabel o
    @layer.addChild @background = @buildBackground o
    @layer.updateLayerOrder()

  update: ->
    return unless @text and @sprite.sprite
    offset = @sprite.getOffset? (if @style in ['dialogue', 'say'] then 'mouth' else 'aboveHead')
    offset ?= { x: 0, y: 0 }  # temp (if not Lank)
    offset.y += 10 if @style is 'variable'
    rotation = @sprite.getRotation()
    offset.x *= -1 if rotation >= 135 or rotation <= -135
    @label.x = @background.x = @sprite.sprite.x + offset.x
    @label.y = @background.y = @sprite.sprite.y + offset.y
    if @returnBounds and @background.bitmapCache and @sprite?.options?.camera
      cache = @background.bitmapCache
      camera = @sprite.options.camera
      width = (@background.bitmapCache.width - Label.BITMAP_SPACE) * @background.scaleX
      height = (@background.bitmapCache.height - Label.BITMAP_SPACE) * @background.scaleY
      x = @background.x - @background.regX * @background.scaleX
      y = @background.y - @background.regY * @background.scaleY
      posLB = camera.surfaceToWorld({x: x, y: y + height})
      posRT = camera.surfaceToWorld({x: x + width, y: y})
      @sprite.thang?.labelBounds = {x1: posLB.x, x2: posRT.x, y1: posLB.y, y2: posRT.y}
    null

  show: ->
    return unless @label
    @layer.addChild @label
    @layer.addChild @background
    @layer.updateLayerOrder()

  hide: ->
    return unless @label
    @layer.removeChild @background
    @layer.removeChild @label

  buildLabelOptions: ->
    o = {}
    st = {dialogue: 'D', say: 'S', name: 'N', variable: 'V'}[@style]
    o.marginX = {D: 5, S: 6, N: 3, V: 0}[st]
    o.marginY = {D: 6, S: 4, N: 3, V: 0}[st]
    o.fontWeight = {D: 'bold', S: 'bold', N: 'bold', V: 'bold'}[st]
    o.shadow = {D: false, S: true, N: true, V: true}[st]
    o.shadowColor = {D: '#FFF', S: '#000', N: '#000', V: "#000"}[st]
    o.fontSize = {D: 25, S: 12, N: 24, V: 18}[st]
    o.lineSpacing = 2
    o.fontFamily = {D: 'Arial', S: 'Arial', N: 'Arial', B: 'Arial', V: 'Arial'}[st]
    o.textAlign = "left" # it's disabled for customizing on purpose, we don't need it now and need to rework "bubble" forming for that
    o.fontColor = {D: '#000', S: '#FFF', N: '#6c6', V: '#6c6'}[st]
    if @style is 'name' and @sprite?.thang?.team is 'humans'
      o.fontColor = '#c66'
    else if @style is 'name' and @sprite?.thang?.team is 'ogres'
      o.fontColor = '#66c'
    else if @style is 'variable'
      o.fontColor = '#fff'

    o.backgroundFillColor = {D: 'white', S: 'rgba(0,0,0,0.4)', N: 'rgba(0,0,0,0.7)', V: 'rgba(0,0,0,0.7)'}[st]
    o.backgroundStrokeColor = {D: 'black', S: 'rgba(0,0,0,0.6)', N: 'rgba(0,0,0,0)', V: 'rgba(0,0,0,0)'}[st]
    o.backgroundStrokeStyle = {D: 2, S: 1, N: 1, V: 1}[st]
    o.backgroundBorderRadius = {D: 10, S: 3, N: 3, V: 3}[st]
    o.layerPriority = {D: 10, S: 5, N: 5, V: 5}[st]
    o.maxWidth = {D: 300, S: 300, N: 180, V: 100}[st]
    o.maxWidth = Math.max @camera.canvasWidth / 2 - 100, o.maxWidth
    o.maxLength = {D: 100, S: 100, N: 30, V: 30}[st]
    o = _.merge(o, @labelOptions)
    o.fontDescriptor = "#{o.fontWeight} #{o.fontSize}px #{o.fontFamily}"
    multiline = @addNewLinesToText _.string.prune(@text, o.maxLength), o.fontDescriptor, o.maxWidth
    o.text = multiline.text
    o.textWidth = multiline.textWidth
    o

  buildLabel: (o) ->
    label = new createjs.Text o.text, o.fontDescriptor, o.fontColor
    label.lineHeight = o.fontSize + o.lineSpacing
    label.x = o.marginX
    label.y = o.marginY
    label.textAlign = o.textAlign
    label.shadow = new createjs.Shadow o.shadowColor, 1, 1, 0 if o.shadow
    label.layerPriority = o.layerPriority
    label.name = "Sprite Label - #{@style}"
    bounds = label.getBounds()
    label.cache(bounds.x, bounds.y, bounds.width, bounds.height)
    o.textHeight = label.getMeasuredHeight()
    o.label = label
    label

  buildBackground: (o) ->
    w = o.textWidth + 2 * o.marginX
    h = o.textHeight + 2 * o.marginY + 1  # Is this +1 needed?

    background = new createjs.Shape()
    background.name = "Sprite Label Background - #{@style}"
    g = background.graphics
    g.beginFill o.backgroundFillColor
    g.beginStroke o.backgroundStrokeColor
    g.setStrokeStyle o.backgroundStrokeStyle

    radius = o.backgroundBorderRadius  # Rounded rectangle border radius
    pointerHeight = 10  # Height of pointer triangle
    pointerWidth = 8  # Actual width of pointer triangle
    pointerWidth += radius  # Convenience value including pointer width and border radius
  
    if @style is 'dialogue' and not o.withoutPointer
      # Figure out the position of the pointer for the bubble
      sup = x: @sprite.sprite.x, y: @sprite.sprite.y  # a little more accurate to aim for mouth--how?
      cap = @camera.surfaceToCanvas sup
      o.hPos = if cap.x / @camera.canvasWidth > 0.53 then 'right' else 'left'
      o.vPos = if cap.y / @camera.canvasHeight > 0.53 then 'bottom' else 'top'
      pointerPos = "#{o.vPos}-#{o.hPos}"
      # TODO: we should redo this when the Thang moves enough, not just when we change its text
      #return if pointerPos is @lastBubblePos and blurb is @lastBlurb

      # Draw a rounded rectangle with the pointer coming out of it
      g.moveTo(radius, 0)
      if pointerPos is 'top-left'
        g.lineTo(radius / 2, -pointerHeight)
        g.lineTo(pointerWidth, 0)
      else if pointerPos is 'top-right'
        g.lineTo(w - pointerWidth, 0)
        g.lineTo(w - radius / 2, -pointerHeight)

      # Draw top and right edges
      g.lineTo(w - radius, 0)
      g.quadraticCurveTo(w, 0, w, radius)
      g.lineTo(w, h - radius)
      g.quadraticCurveTo(w, h, w - radius, h)

      if pointerPos is 'bottom-right'
        g.lineTo(w - radius / 2, h + pointerHeight)
        g.lineTo(w - pointerWidth, h)
      else if pointerPos is 'bottom-left'
        g.lineTo(pointerWidth, h)
        g.lineTo(radius / 2, h + pointerHeight)

      # Draw bottom and left edges
      g.lineTo(radius, h)
      g.quadraticCurveTo(0, h, 0, h - radius)
      g.lineTo(0, radius)
      g.quadraticCurveTo(0, 0, radius, 0)
    else
      # Just draw a rounded rectangle
      o.hpos ?= "middle"
      o.vPos ?= "middle"
      pointerHeight = 0
      g.drawRoundRect(o.label.x - o.marginX, o.label.y - o.marginY, w, h, o.backgroundBorderRadius)
    
    background.regX = w / 2
    background.regY = h + 2  # Just above health bar, say
    
    # Center the container where the mouth of the speaker will be
    if o.hPos is "left"
      background.regX = 3
    else if o.hPos is "right"
      background.regX = o.textWidth + 3
    if o.vPos is "bottom"
      background.regY = h + pointerHeight
    else if o.vPos is "top"
      background.regY = -pointerHeight

    o.label.regX = background.regX - o.marginX
    o.label.regY = background.regY - o.marginY
    space = Label.BITMAP_SPACE
    offset = -1 * space / 2
    background.cache(offset, offset, w + space, h + space)

    g.endStroke()
    g.endFill()
    background.layerPriority = o.layerPriority - 1
    background

  addNewLinesToText: (originalText, fontDescriptor, maxWidth=400) ->
    rows = []
    row = []
    words = _.string.words originalText
    textWidth = 0
    for word in words
      row.push(word)
      text = new createjs.Text(_.string.join(' ', row...), fontDescriptor, '#000')
      width = text.getMeasuredWidth()
      if width > maxWidth
        if row.length is 1 # one long word, truncate it
          row[0] = _.string.truncate(row[0], 40)
          text.text = row[0]
          textWidth = Math.max(text.getMeasuredWidth(), textWidth)
          rows.push(row)
          row = []
        else
          row.pop()
          rows.push(row)
          row = [word]
      else
        textWidth = Math.max(textWidth, width)
    rows.push(row) if row.length
    for row, i in rows
      rows[i] = _.string.join(' ', row...)
    text: _.string.join("\n", rows...), textWidth: textWidth
