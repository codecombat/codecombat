CocoClass = require 'core/CocoClass'
Camera = require './Camera'
ThangType = require 'models/ThangType'
markThangTypes = {}
createjs = require 'lib/createjs-parts'

module.exports = class Mark extends CocoClass
  subscriptions: {}
  alpha: 1

  constructor: (options) ->
    super()
    options ?= {}
    @name = options.name
    @lank = options.lank
    @camera = options.camera
    @layer = options.layer
    @thangType = options.thangType
    @listenTo @layer, 'new-spritesheet', @onLayerMadeSpriteSheet
    console.error @toString(), 'needs a name.' unless @name
    console.error @toString(), 'needs a camera.' unless @camera
    console.error @toString(), 'needs a layer.' unless @layer
    @build()

  destroy: ->
    createjs.Tween.removeTweens @sprite if @sprite
    @sprite?.parent?.removeChild @sprite
    if @markLank
      @layer.removeLank(@markLank)
      @markLank.destroy()
    @lank = null
    super()

  toString: -> "<Mark #{@name}: Sprite #{@lank?.thang?.id ? 'None'}>"

  onLayerMadeSpriteSheet: ->
    return unless @sprite
    return @update() if @markLank
    # rebuild sprite for new sprite sheet
    @layer.removeChild @sprite
    @sprite = null
    @build()
    @layer.addChild @sprite
    @layer.updateLayerOrder()
#    @updatePosition()
    @update()

  toggle: (to) ->
    to = !!to
    return @ if to is @on
    return @toggleTo = to unless @sprite
    @on = to
    delete @toggleTo
    if @on
      if @markLank
        @layer.addLank(@markLank)
      else
        @layer.addChild @sprite
        @layer.updateLayerOrder()
    else
      if @markLank
        @layer.removeLank(@markLank)
      else
        @layer.removeChild @sprite
      if @highlightTween
        @highlightDelay = @highlightTween = null
        createjs.Tween.removeTweens @sprite
        @sprite.visible = true
    @

  setLayer: (layer) ->
    return if layer is @layer
    wasOn = @on
    @toggle false
    @layer = layer
    @toggle true if wasOn

  setLank: (lank) ->
    return if lank is @lank
    @lank = lank
    @build()
    @

  build: ->
    unless @sprite
      if @name is 'bounds' then @buildBounds()
      else if @name is 'shadow' then @buildShadow()
      else if @name is 'debug' then @buildDebug()
      else if @name.match(/.+(Range|Distance|Radius)$/) then @buildRadius(@name)
      else if @thangType then @buildSprite()
      else console.error 'Don\'t know how to build mark for', @name
      @sprite?.mouseEnabled = false
    @

  buildBounds: ->
    @sprite = new createjs.Container()
    @sprite.mouseChildren = false
    style = @lank.thang.drawsBoundsStyle
    @drawsBoundsIndex = @lank.thang.drawsBoundsIndex
    return if style is 'corner-text' and @lank.thang.world.age is 0

    # Confusingly make some semi-random colors that'll be consistent based on the drawsBoundsIndex
    colors = (128 + Math.floor(('0.'+Math.sin(3 * @drawsBoundsIndex + i).toString().substr(6)) * 128) for i in [1 ... 4])
    color = "rgba(#{colors[0]}, #{colors[1]}, #{colors[2]}, 0.5)"
    [w, h] = [@lank.thang.width * Camera.PPM, @lank.thang.height * Camera.PPM * @camera.y2x]

    if style in ['border-text', 'corner-text']
      @drawsBoundsBorderShape = shape = new createjs.Shape()
      shape.graphics.setStrokeStyle 5
      shape.graphics.beginStroke color
      if style is 'border-text'
        shape.graphics.beginFill color.replace('0.5', '0.25')
      else
        shape.graphics.beginFill color
      if @lank.thang.shape in ['ellipsoid', 'disc']
        shape.drawEllipse 0, 0, w, h
      else
        shape.graphics.drawRect -w / 2, -h / 2, w, h
      shape.graphics.endStroke()
      shape.graphics.endFill()
      @sprite.addChild shape

    if style is 'border-text'
      text = new createjs.Text '' + @drawsBoundsIndex, '20px Arial', color.replace('0.5', '1')
      text.regX = text.getMeasuredWidth() / 2
      text.regY = text.getMeasuredHeight() / 2
      text.shadow = new createjs.Shadow('#000000', 1, 1, 0)
      @sprite.addChild text
    else if style is 'corner-text'
      return if @lank.thang.world.age is 0
      letter = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[@drawsBoundsIndex % 26]
      text = new createjs.Text letter, '14px Arial', '#333333'   # color.replace('0.5', '1')
      text.x = -w / 2 + 2
      text.y = -h / 2 + 2
      @sprite.addChild text
    else
      console.warn @lank.thang.id, 'didn\'t know how to draw bounds style:', style

    if w > 0 and h > 0 and style is 'border-text'
      @sprite.cache -w / 2, -h / 2, w, h, 2
    @lastWidth = @lank.thang.width
    @lastHeight = @lank.thang.height

  buildShadow: ->
    shapeName = if @lank.thang.shape in ['ellipsoid', 'disc'] then 'ellipse' else 'rect'
    key = "#{shapeName}-shadow"
    SHADOW_SIZE = 10
    unless key in @layer.spriteSheet.animations
      shape = new createjs.Shape()
      shape.graphics.beginFill "rgba(0,0,0)"
      bounds = [-SHADOW_SIZE/2, - SHADOW_SIZE/2, SHADOW_SIZE, SHADOW_SIZE]
      if shapeName is 'ellipse'
        shape.graphics.drawEllipse bounds...
      else
        shape.graphics.drawRect bounds...
      shape.graphics.endFill()
      @layer.addCustomGraphic(key, shape, bounds)
    alpha = @lank.thang?.alpha ? 1
    width = (@lank.thang?.width ? 0) + 0.5
    height = (@lank.thang?.height ? 0) + 0.5
    longest = Math.max width, height
    actualLongest = @lank.thangType.get('shadow') ? longest
    width = width * actualLongest / longest
    height = height * actualLongest / longest
    width *= Camera.PPM
    height *= Camera.PPM * @camera.y2x  # TODO: doesn't work with rotation
    @sprite = new createjs.Sprite(@layer.spriteSheet)
    @sprite.gotoAndStop(key)
    @sprite.mouseEnabled = false
    @sprite.alpha = alpha
    @baseScaleX = @sprite.scaleX = width / (@layer.resolutionFactor * SHADOW_SIZE)
    @baseScaleY = @sprite.scaleY = height / (@layer.resolutionFactor * SHADOW_SIZE)

  buildRadius: (range) ->
    alpha = 0.15
    colors =
      voiceRange: "rgba(0,145,0,#{alpha})"
      visualRange: "rgba(0,0,145,#{alpha})"
      attackRange: "rgba(145,0,0,#{alpha})"

    # Fallback colors which work on both dungeon and grass tiles
    extraColors = [
      "rgba(145,0,145,#{alpha})"
      "rgba(0,145,145,#{alpha})"
      "rgba(145,105,0,#{alpha})"
      "rgba(225,125,0,#{alpha})"
    ]

    # Find the index of this range, to find the next-smallest radius
    rangeNames = @lank.ranges.map((range, index) ->
      range['name']
    )
    i = rangeNames.indexOf(range)

    @sprite = new createjs.Shape()

    fillColor = colors[range] ? extraColors[i]
    @sprite.graphics.beginFill fillColor

    # Draw the outer circle
    @sprite.graphics.drawCircle 0, 0, @lank.thang[range] * Camera.PPM

    # Cut out the hollow part if necessary
    if i+1 < @lank.ranges.length
      @sprite.graphics.arc 0, 0, @lank.ranges[i+1]['radius'], Math.PI*2, 0, true

    @sprite.graphics.endFill()

    strokeColor = fillColor.replace '' + alpha, '0.75'
    @sprite.graphics.setStrokeStyle 2
    @sprite.graphics.beginStroke strokeColor
    @sprite.graphics.arc 0, 0, @lank.thang[range] * Camera.PPM, Math.PI*2, 0, true
    @sprite.graphics.endStroke()

    # Add perspective
    @sprite.scaleY *= @camera.y2x

  buildDebug: ->
    shapeName = if @lank.thang.shape in ['ellipsoid', 'disc'] then 'ellipse' else 'rect'
    key = "#{shapeName}-debug-#{@lank.thang.collisionCategory}"
    DEBUG_SIZE = 10
    unless key in @layer.spriteSheet.animations
      shape = new createjs.Shape()
      debugColor = {
        none: 'rgba(224,255,239,0.25)'
        ground: 'rgba(239,171,205,0.5)'
        air: 'rgba(131,205,255,0.5)'
        ground_and_air: 'rgba(2391,140,239,0.5)'
        obstacles: 'rgba(88,88,88,0.5)'
        dead: 'rgba(89,171,100,0.25)'
      }[@lank.thang.collisionCategory] or 'rgba(171,205,239,0.5)'
      shape.graphics.beginFill debugColor
      bounds = [-DEBUG_SIZE / 2, -DEBUG_SIZE / 2, DEBUG_SIZE, DEBUG_SIZE]
      if shapeName is 'ellipse'
        shape.graphics.drawEllipse bounds...
      else
        shape.graphics.drawRect bounds...
      shape.graphics.endFill()
      @layer.addCustomGraphic(key, shape, bounds)

    @sprite = new createjs.Sprite(@layer.spriteSheet)
    @sprite.gotoAndStop(key)
    PX = 3
    w = Math.max(PX, @lank.thang.width  * Camera.PPM) * (@camera.y2x + (1 - @camera.y2x) * Math.abs Math.cos @lank.thang.rotation)
    h = Math.max(PX, @lank.thang.height * Camera.PPM) * (@camera.y2x + (1 - @camera.y2x) * Math.abs Math.sin @lank.thang.rotation)
    @sprite.scaleX = w / (@layer.resolutionFactor * DEBUG_SIZE)
    @sprite.scaleY = h / (@layer.resolutionFactor * DEBUG_SIZE)
    @sprite.rotation = -@lank.thang.rotation * 180 / Math.PI

  buildSprite: ->
    if _.isString @thangType
      thangType = markThangTypes[@thangType]
      return @loadThangType() if not thangType
      @thangType = thangType

    return @listenToOnce(@thangType, 'sync', @onLoadedThangType) if not @thangType.loaded
    Lank = require './Lank'
    # don't bother with making these render async for now, but maybe later for fun and more complexity of code
    markLank = new Lank @thangType
    markLank.queueAction 'idle'
    @sprite = markLank.sprite
    @markLank = markLank
    @listenTo @markLank, 'new-sprite', (@sprite) ->

  loadThangType: ->
    name = @thangType
    @thangType = new ThangType()
    @thangType.url = -> "/db/thang.type/#{name}"
    @listenToOnce(@thangType, 'sync', @onLoadedThangType)
    @thangType.fetch()
    markThangTypes[name] = @thangType

  onLoadedThangType: ->
    @build()
    @update() if @markLank
    @toggle(@toggleTo) if @toggleTo?
    Backbone.Mediator.publish 'sprite:loaded', {sprite: @}

  update: (pos=null) ->
    return false unless @on and @sprite
    return false if @lank? and not @lank.thangType.isFullyLoaded()
    @sprite.visible = not @hidden
    @updatePosition pos
    @updateRotation()
    @updateScale()
    if @name is 'highlight' and @highlightDelay and not @highlightTween
      @sprite.visible = false
      @highlightTween = createjs.Tween.get(@sprite).to({}, @highlightDelay).call =>
        return if @destroyed
        @sprite.visible = true
        @highlightDelay = @highlightTween = null
    @updateAlpha @alpha if @name in ['shadow', 'bounds']
    true

  updatePosition: (pos) ->
    if @lank?.thang and @name in ['shadow', 'debug', 'target', 'selection', 'repair']
      pos = @camera.worldToSurface x: @lank.thang.pos.x, y: @lank.thang.pos.y
    else
      pos ?= @lank?.sprite
    return unless pos
    @sprite.x = pos.x
    @sprite.y = pos.y
    if @statusEffect or @name is 'highlight'
      offset = @lank.getOffset 'aboveHead'
      @sprite.x += offset.x
      @sprite.y += offset.y
      @sprite.y -= 3 if @statusEffect

  updateAlpha: (@alpha) ->
    return if not @sprite or @name is 'debug'
    if @name is 'shadow'
      worldZ = @lank.thang.pos.z - @lank.thang.depth / 2 + @lank.getBobOffset()
      @sprite.alpha = @alpha * 0.451 / Math.sqrt(worldZ / 2 + 1)
    else if @name is 'bounds'
      @drawsBoundsBorderShape?.alpha = Math.floor @lank.thang.alpha  # Stop drawing bounds as soon as alpha is reduced at all
    else
      @sprite.alpha = @alpha

  updateRotation: ->
    if @name is 'debug' or (@name is 'shadow' and @lank.thang?.shape in ['rectangle', 'box'])
      @sprite.rotation = -@lank.thang.rotation * 180 / Math.PI

  updateScale: ->
    if @name is 'bounds' and ((@lank.thang.width isnt @lastWidth or @lank.thang.height isnt @lastHeight) or (@lank.thang.drawsBoundsIndex isnt @drawsBoundsIndex))
      oldMark = @sprite
      @buildBounds()
      oldMark.parent.addChild @sprite
      oldMark.parent.swapChildren oldMark, @sprite
      oldMark.parent.removeChild oldMark

    if @markLank?
      @markLank.scaleFactor = 1.2
      @markLank.updateScale()

    if @name is 'shadow' and thang = @lank.thang
      @sprite.scaleX = @baseScaleX * (thang.scaleFactor ? thang.scaleFactorX ? 1)
      @sprite.scaleY = @baseScaleY * (thang.scaleFactor ? thang.scaleFactorY ? 1)

    return unless @name in ['selection', 'target', 'repair', 'highlight']

    # scale these marks to 10m (100px). Adjust based on lank size.
    factor = 0.3 # default size: 3m width, most commonly for target when pointing to a location

    if @lank?.sprite
      width = @lank.sprite.getBounds()?.width or 0
      width /= @lank.options.resolutionFactor
      # all targets should be set to have a width of 100px, and then be scaled accordingly
      factor = width / 100 # normalize
      factor *= 1.1 # add margin
      factor = Math.max(factor, 0.3) # lower bound
    @sprite.scaleX *= factor
    @sprite.scaleY *= factor

    if @name in ['selection', 'target', 'repair']
      @sprite.scaleY *= @camera.y2x  # code applies perspective

  stop: -> @markLank?.stop()
  play: -> @markLank?.play()
  hide: -> @hidden = true
  show: -> @hidden = false
