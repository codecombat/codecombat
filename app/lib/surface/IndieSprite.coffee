{me} = require('lib/auth')
Thang = require 'lib/world/thang'
Vector = require 'lib/world/vector'
CocoSprite = require 'lib/surface/CocoSprite'
Camera = require './Camera'

module.exports = IndieSprite = class IndieSprite extends CocoSprite
  notOfThisWorld: true
  subscriptions:
    'level-sprite-move': 'onMove'
    'note-group-started': 'onNoteGroupStarted'
    'note-group-ended': 'onNoteGroupEnded'

  constructor: (thangType, options) ->
    options.thang = @makeIndieThang thangType, options.thangID, options.pos
    super thangType, options

  makeIndieThang: (thangType, thangID, pos) ->
    @thang = thang = new Thang null, thangType.get('name'), thangID
    # Build needed results of what used to be Exists, Physical, Acts, and Selectable Components
    thang.exists = true
    thang.width = thang.height = thang.depth = 4
    thang.pos = pos ? @defaultPos()
    thang.pos.z = thang.depth / 2
    thang.shape = 'ellipsoid'
    thang.rotation = 0
    thang.action = 'idle'
    thang.setAction = (action) -> thang.action = action
    thang.getActionName = -> thang.action
    thang.acts = true
    thang.isSelectable = true
    thang

  onNoteGroupStarted: => @scriptRunning = true
  onNoteGroupEnded: => @scriptRunning = false
  onMouseEvent: (e, ourEventName) -> super e, ourEventName unless @scriptRunning
  defaultPos: -> x: -20, y: 20, z: @thang.depth / 2

  onMove: (e) ->
    return unless e.spriteID is @thang.id
    pos = e.pos
    if _.isArray pos
      pos = new Vector pos...
    else if _.isString pos
      return console.warn "Couldn't find target sprite", pos, "from", @options.sprites unless pos of @options.sprites
      target = @options.sprites[pos].thang
      heading = Vector.subtract(target.pos, @thang.pos).normalize()
      distance = @thang.pos.distance target.pos
      offset = Math.max(target.width, target.height, 2) / 2 + 3
      pos = Vector.add(@thang.pos, heading.multiply(distance - offset))
    Backbone.Mediator.publish 'level-sprite-clear-dialogue', {}
    @onClearDialogue()
    args = [pos]
    args.push(e.duration) if e.duration?
    @move(args...)

  move: (pos, duration=2000, endAnimation='idle') =>
    if not duration
      createjs.Tween.removeTweens(@thang.pos) if @lastTween
      @lastTween = null
      z = @thang.pos.z
      @thang.pos = pos
      @thang.pos.z = z
      @imageObject.gotoAndPlay(endAnimation)
      return

    @thang.action = 'move'
    @thang.actionActivated = true
    @pointToward(pos)

    ease = createjs.Ease.getPowInOut(2.2)
    if @lastTween
      ease = createjs.Ease.getPowOut(1.2)
      createjs.Tween.removeTweens(@thang.pos)

    endFunc = =>
      @lastTween = null
      @imageObject.gotoAndPlay(endAnimation)
      @thang.action = 'idle'
      window.myself = @

    @lastTween = createjs.Tween
      .get(@thang.pos)
      .to({x:pos.x, y:pos.y}, duration, ease)
      .call(endFunc)

  pointToward: (pos) ->
    @thang.rotation = Math.atan2(pos.y - @thang.pos.y, pos.x - @thang.pos.x)
    if (@thang.rotation * 180 / Math.PI) % 90 is 0
      @thang.rotation += 0.01
