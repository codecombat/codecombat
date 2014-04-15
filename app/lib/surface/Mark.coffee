CocoClass = require 'lib/CocoClass'
Camera = require './Camera'
ThangType = require 'models/ThangType'
markThangTypes = {}

module.exports = class Mark extends CocoClass
  subscriptions: {}

  constructor: (options) ->
    super()
    options ?= {}
    @name = options.name
    @sprite = options.sprite
    @camera = options.camera
    @layer = options.layer
    @thangType = options.thangType
    console.error @toString(), "needs a name." unless @name
    console.error @toString(), "needs a camera." unless @camera
    console.error @toString(), "needs a layer." unless @layer
    @build()

  destroy: ->
    @mark?.parent?.removeChild @mark
    @markSprite?.destroy()
    @sprite = null
    super()

  toString: -> "<Mark #{@name}: Sprite #{@sprite?.thang?.id ? 'None'}>"

  toggle: (to) ->
    return @ if to is @on
    return @toggleTo = to unless @mark
    @on = to
    delete @toggleTo
    if @on
      @layer.addChild @mark
      @layer.updateLayerOrder()
    else
      @layer.removeChild @mark
      if @highlightTween
        @highlightDelay = @highlightTween = null
        createjs.Tween.removeTweens @mark
        @mark.visible = true
    @

  setSprite: (sprite) ->
    return if sprite is @sprite
    @sprite = sprite
    @build()
    @

  build: ->
    unless @mark
      if @name is 'bounds' then @buildBounds()
      else if @name is 'shadow' then @buildShadow()
      else if @name is 'debug' then @buildDebug()
      else if @name.match(/.+(Range|Distance|Radius)$/) then @buildRadius(@name)
      else if @thangType then @buildSprite()
      else console.error "Don't know how to build mark for", @name
      @mark?.mouseEnabled = false
    @

  buildBounds: ->
    @mark = new createjs.Container()
    @mark.mouseChildren = false

    # Confusingly make some semi-random colors that'll be consistent based on the drawsBoundsIndex
    index = @sprite.thang.drawsBoundsIndex
    colors = (128 + Math.floor(('0.'+Math.sin(3 * index + i).toString().substr(6)) * 128) for i in [1 ... 4])
    color = "rgba(#{colors[0]}, #{colors[1]}, #{colors[2]}, 0.5)"

    shape = new createjs.Shape()
    shape.graphics.setStrokeStyle 5
    shape.graphics.beginStroke color
    shape.graphics.beginFill color.replace('0.5', '0.25')
    [w, h] = [@sprite.thang.width * Camera.PPM, @sprite.thang.height * Camera.PPM * @camera.y2x]
    if @sprite.thang.shape in ["ellipsoid", "disc"]
      shape.drawEllipse 0, 0, w, h
    else
      shape.graphics.drawRect -w / 2, -h / 2, w, h
    shape.graphics.endStroke()
    shape.graphics.endFill()

    text = new createjs.Text "" + index, "40px Arial", color.replace('0.5', '1')
    text.regX = text.getMeasuredWidth() / 2
    text.regY = text.getMeasuredHeight() / 2
    text.shadow = new createjs.Shadow("#000000", 1, 1, 0)

    @mark.addChild shape, text
    if w > 0 and h > 0
      @mark.cache -w / 2, -h / 2, w, h, 2
    @lastWidth = @sprite.thang.width
    @lastHeight = @sprite.thang.height

  buildShadow: ->
    alpha = @sprite.thang?.alpha ? 1
    width = (@sprite.thang?.width ? 0) + 0.5
    height = (@sprite.thang?.height ? 0) + 0.5
    longest = Math.max width, height
    actualLongest = @sprite.thangType.get('shadow') ? longest
    width = width * actualLongest / longest
    height = height * actualLongest / longest
    width *= Camera.PPM
    height *= Camera.PPM * @camera.y2x  # TODO: doesn't work with rotation
    @mark = new createjs.Shape()
    @mark.mouseEnabled = false
    @mark.graphics.beginFill "rgba(0, 0, 0, #{alpha})"
    if @sprite.thang.shape in ['ellipsoid', 'disc']
      @mark.graphics.drawEllipse 0, 0, width, height
    else
      @mark.graphics.drawRect 0, 0, width, height
    @mark.graphics.endFill()
    @mark.regX = width / 2
    @mark.regY = height / 2
    @mark.layerIndex = 10
    #@mark.cache 0, 0, diameter, diameter  # not actually faster than simple ellipse draw

  buildRadius: (range) ->
    alpha = 0.15
    colors =
      voiceRange: "rgba(0, 145, 0, #{alpha})"
      visualRange: "rgba(0, 0, 145, #{alpha})"
      attackRange: "rgba(145, 0, 0, #{alpha})"

    # Fallback colors which work on both dungeon and grass tiles
    extraColors = [
      "rgba(145, 0, 145, #{alpha})"
      "rgba(0, 145, 145, #{alpha})"
      "rgba(145, 105, 0, #{alpha})"
      "rgba(225, 125, 0, #{alpha})"
    ]

    # Find the index of this range, to find the next-smallest radius
    rangeNames = @sprite.ranges.map((range, index) ->
      range['name']
    )
    i = rangeNames.indexOf(range)

    @mark = new createjs.Shape()

    fillColor = colors[range] ? extraColors[i]
    @mark.graphics.beginFill fillColor

    # Draw the outer circle
    @mark.graphics.drawCircle 0, 0, @sprite.thang[range] * Camera.PPM

    # Cut out the hollow part if necessary
    if i+1 < @sprite.ranges.length
      @mark.graphics.arc 0, 0, @sprite.ranges[i+1]['radius'], Math.PI*2, 0, true

    @mark.graphics.endFill()

    strokeColor = fillColor.replace '' + alpha, '0.75'
    @mark.graphics.setStrokeStyle 2
    @mark.graphics.beginStroke strokeColor
    @mark.graphics.arc 0, 0, @sprite.thang[range] * Camera.PPM, Math.PI*2, 0, true
    @mark.graphics.endStroke()

    # Add perspective
    @mark.scaleY *= @camera.y2x

  buildDebug: ->
    @mark = new createjs.Shape()
    PX = 3
    [w, h] = [Math.max(PX, @sprite.thang.width * Camera.PPM), Math.max(PX, @sprite.thang.height * Camera.PPM) * @camera.y2x]
    @mark.alpha = 0.5
    @mark.graphics.beginFill '#abcdef'
    if @sprite.thang.shape in ["ellipsoid", "disc"]
      [w, h] = [Math.max(PX, w, h), Math.max(PX, w, h)]
      @mark.graphics.drawCircle 0, 0, w / 2
    else
      @mark.graphics.drawRect -w / 2, -h / 2, w, h
    @mark.graphics.endFill()

  buildSprite: ->
    if _.isString @thangType
      thangType = markThangTypes[@thangType]
      return @loadThangType() if not thangType
      @thangType = thangType

    return @listenToOnce(@thangType, 'sync', @onLoadedThangType) if not @thangType.loaded
    CocoSprite = require './CocoSprite'
    markSprite = new CocoSprite @thangType, @thangType.spriteOptions
    markSprite.queueAction 'idle'
    @mark = markSprite.displayObject
    @markSprite = markSprite

  loadThangType: ->
    name = @thangType
    @thangType = new ThangType()
    @thangType.url = -> "/db/thang.type/#{name}"
    @listenToOnce(@thangType, 'sync', @onLoadedThangType)
    @thangType.fetch()
    markThangTypes[name] = @thangType
    window.mtt = markThangTypes

  onLoadedThangType: ->
    @build()
    @toggle(@toggleTo) if @toggleTo?
    Backbone.Mediator.publish 'sprite:loaded'

  update: (pos=null) ->
    return false unless @on and @mark
    @mark.visible = not @hidden
    @updatePosition pos
    @updateRotation()
    @updateScale()
    @mark.advance?()
    if @name is 'highlight' and @highlightDelay and not @highlightTween
      @mark.visible = false
      @highlightTween = createjs.Tween.get(@mark).to({}, @highlightDelay).call =>
        @mark.visible = true
        @highlightDelay = @highlightTween = null
    true

  updatePosition: (pos) ->
    if @name in ['shadow', 'debug']
      pos = @camera.worldToSurface x: @sprite.thang.pos.x, y: @sprite.thang.pos.y
      if @name is 'shadow'
        worldZ = @sprite.thang.pos.z - @sprite.thang.depth / 2 + @sprite.getBobOffset()
        @mark.alpha = 0.451 / Math.sqrt(worldZ / 2 + 1)
    else
      pos ?= @sprite?.displayObject
    @mark.x = pos.x
    @mark.y = pos.y
    if @statusEffect or @name is 'highlight'
      offset = @sprite.getOffset 'aboveHead'
      @mark.x += offset.x
      @mark.y += offset.y
      @mark.y -= 3 if @statusEffect

  updateRotation: ->
    if @name is 'debug' or (@name is 'shadow' and @sprite.thang?.shape in ["rectangle", "box"])
      @mark.rotation = @sprite.thang.rotation * 180 / Math.PI

  updateScale: ->
    if @name is 'bounds' and (@sprite.thang.width isnt @lastWidth or @sprite.thang.height isnt @lastHeight)
      oldMark = @mark
      @buildBounds()
      oldMark.parent.addChild @mark
      oldMark.parent.swapChildren oldMark, @mark
      oldMark.parent.removeChild oldMark
    return unless @name in ["selection", "target", "repair", "highlight"]
    scale = 0.5
    if @sprite
      size = @sprite.getAverageDimension()
      size += 60 if @name is 'selection'
      size += 60 if @name is 'repair'
      scale = size / {selection: 128, target: 128, repair: 320, highlight: 160}[@name]
      if @sprite?.thang.spriteName.search(/(dungeon|indoor).wall/i) isnt -1
        scale *= 2
    @mark.scaleX = @mark.scaleY = Math.min 1, scale
    if @name in ['selection', 'target', 'repair']
      @mark.scaleY *= @camera.y2x  # code applies perspective

  stop: -> @markSprite?.stop()
  play: -> @markSprite?.play()
  hide: -> @hidden = true
  show: -> @hidden = false
