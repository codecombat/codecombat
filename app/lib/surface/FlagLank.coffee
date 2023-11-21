IndieLank = require 'lib/surface/IndieLank'
{me} = require 'core/auth'

module.exports = class FlagLank extends IndieLank
  subscriptions:
    'surface:mouse-moved': 'onMouseMoved'

  #shortcuts:

  defaultPos: -> x: 20, y: 20, z: 1

  constructor: (thangType, options) ->
    super thangType, options
    @toggleCursor options.isCursor

  makeIndieThang: (thangType, options) ->
    thang = super thangType, options
    thang.width = thang.height = thang.depth = 2
    thang.pos.z = 1
    thang.isSelectable = false
    thang.color = options.color
    thang.team = options.team
    thang

  onMouseMoved: (e) ->
    return unless @options.isCursor
    wop = @options.camera.screenToWorld x: e.x, y: e.y
    @thang.pos.x = wop.x
    @thang.pos.y = wop.y

  toggleCursor: (to) ->
    @options.isCursor = to
    @thang.alpha = if to then 0.33 else 0.67  # 1.0 is for flags that have been placed
    #@thang.action = if to then 'idle' else 'appear'  # TODO: why doesn't this work? Does it not render the action or something?
    @thang.action = 'appear'
    @updateAlpha()
