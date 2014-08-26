Thang = require 'lib/world/thang'
CocoSprite = require 'lib/surface/CocoSprite'

module.exports = IndieSprite = class IndieSprite extends CocoSprite
  notOfThisWorld: true
  subscriptions:
    'note-group-started': 'onNoteGroupStarted'
    'note-group-ended': 'onNoteGroupEnded'

  constructor: (thangType, options) ->
    options.thang = @makeIndieThang thangType, options
    super thangType, options
    @shadow = @thang

  makeIndieThang: (thangType, options) ->
    @thang = thang = new Thang null, thangType.get('name'), options.thangID
    # Build needed results of what used to be Exists, Physical, Acts, and Selectable Components
    thang.exists = true
    thang.width = thang.height = thang.depth = 4
    thang.pos = options.pos ? @defaultPos()
    thang.pos.z = thang.depth / 2
    thang.shape = 'ellipsoid'
    thang.rotation = 0
    thang.action = 'idle'
    thang.setAction = (action) -> thang.action = action
    thang.getActionName = -> thang.action
    thang.acts = true
    thang.isSelectable = true
    thang.team = options.team
    thang.teamColors = options.teamColors
    thang

  onNoteGroupStarted: => @scriptRunning = true
  onNoteGroupEnded: => @scriptRunning = false
  onMouseEvent: (e, ourEventName) -> super e, ourEventName unless @scriptRunning
  defaultPos: -> x: -20, y: 20, z: @thang.depth / 2
