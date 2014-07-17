{me} = require('lib/auth')
Thang = require 'lib/world/thang'
Vector = require 'lib/world/vector'
CocoSprite = require 'lib/surface/CocoSprite'
Camera = require './Camera'

module.exports = IndieSprite = class IndieSprite extends CocoSprite
  notOfThisWorld: true
  subscriptions:
    'note-group-started': 'onNoteGroupStarted'
    'note-group-ended': 'onNoteGroupEnded'

  constructor: (thangType, options) ->
    options.thang = @makeIndieThang thangType, options.thangID, options.pos
    super thangType, options
    @shadow = @thang

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
