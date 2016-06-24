CocoView = require 'views/core/CocoView'
AddThangsView = require './AddThangsView'
thangs_template = require 'templates/editor/level/thangs-tab-view'
Level = require 'models/Level'
ThangType = require 'models/ThangType'
LevelComponent = require 'models/LevelComponent'
CocoCollection = require 'collections/CocoCollection'
{isObjectID} = require 'models/CocoModel'
Surface = require 'lib/surface/Surface'
Thang = require 'lib/world/thang'
LevelThangEditView = require './LevelThangEditView'
ComponentsCollection = require 'collections/ComponentsCollection'
require 'vendor/treema'
GameUIState = require 'models/GameUIState'

# Moving the screen while dragging thangs constants
MOVE_MARGIN = 0.15
MOVE_SPEED = 13

# Let us place these on top of other Thangs
overlappableThangTypeNames = ['Torch', 'Chains', 'Bird', 'Cloud 1', 'Cloud 2', 'Cloud 3', 'Waterfall', 'Obstacle', 'Electrowall', 'Spike Walls']

class ThangTypeSearchCollection extends CocoCollection
  url: '/db/thang.type?project=original,name,version,slug,kind,components,prerenderedSpriteSheetData'
  model: ThangType

module.exports = class ThangsTabView extends CocoView
  id: 'thangs-tab-view'
  className: 'tab-pane active'
  template: thangs_template

  subscriptions:
    'surface:mouse-moved': 'onSurfaceMouseMoved'
    'surface:mouse-over': 'onSurfaceMouseOver'
    'surface:mouse-out': 'onSurfaceMouseOut'
    'editor:edit-level-thang': 'editThang'
    'editor:level-thang-edited': 'onLevelThangEdited'
    'editor:level-thang-done-editing': 'onLevelThangDoneEditing'
    'editor:view-switched': 'onViewSwitched'
    'sprite:dragged': 'onSpriteDragged'
    'sprite:mouse-up': 'onSpriteMouseUp'
    'sprite:double-clicked': 'onSpriteDoubleClicked'
    'surface:stage-mouse-down': 'onStageMouseDown'
    'surface:stage-mouse-up': 'onStageMouseUp'
    'editor:random-terrain-generated': 'onRandomTerrainGenerated'

  events:
    'click #extant-thangs-filter button': 'onFilterExtantThangs'
    'click #delete': 'onDeleteClicked'
    'click #duplicate': 'onDuplicateClicked'
    'click #thangs-container-toggle': 'toggleThangsContainer'
    'click #thangs-palette-toggle': 'toggleThangsPalette'
#    'click .add-thang-palette-icon': 'toggleThangsPalette'
    'click #rotation-menu-item button': 'onClickRotationButton'

  shortcuts:
    'esc': 'selectAddThang'
    'delete, del, backspace': 'deleteSelectedExtantThang'
    'ctrl+z, ⌘+z': 'undo'
    'ctrl+shift+z, ⌘+shift+z': 'redo'
    'alt+c': 'toggleSelectedThangCollision'
    'left': -> @moveSelectedThangBy -1, 0
    'right': -> @moveSelectedThangBy 1, 0
    'up': -> @moveSelectedThangBy 0, 1
    'down': -> @moveSelectedThangBy 0, -1
    'alt+left': -> @rotateSelectedThangTo Math.PI unless key.shift
    'alt+right': -> @rotateSelectedThangTo 0 unless key.shift
    'alt+up': -> @rotateSelectedThangTo -Math.PI / 2
    'alt+down': -> @rotateSelectedThangTo Math.PI / 2
    'alt+shift+left': -> @rotateSelectedThangBy Math.PI / 16
    'alt+shift+right': -> @rotateSelectedThangBy -Math.PI / 16
    'shift+left': -> @resizeSelectedThangBy -1, 0
    'shift+right': -> @resizeSelectedThangBy 1, 0
    'shift+up': -> @resizeSelectedThangBy 0, 1
    'shift+down': -> @resizeSelectedThangBy 0, -1

  constructor: (options) ->
    super options
    @world = options.world
    @gameUIState = new GameUIState()
    @listenTo(@gameUIState, 'sprite:mouse-down', @onSpriteMouseDown)
    @listenTo(@gameUIState, 'surface:stage-mouse-move', @onStageMouseMove)
    @listenTo(@gameUIState, 'change:selected', @onChangeSelected)

    # should load depended-on Components, too
    @thangTypes = @supermodel.loadCollection(new ThangTypeSearchCollection(), 'thangs').model
    # just loading all Components for now: https://github.com/codecombat/codecombat/issues/405
    @componentCollection = @supermodel.loadCollection(new ComponentsCollection(), 'components').load()
    @level = options.level
    @onThangsChanged = _.debounce(@onThangsChanged)

    $(document).bind 'contextmenu', @preventDefaultContextMenu

  getRenderData: (context={}) ->
    context = super(context)
    return context unless @supermodel.finished()
    for thangType in @thangTypes.models
      thangType.notInLevel = true
    thangTypes = (thangType.attributes for thangType in @supermodel.getModels(ThangType))
    thangTypes = _.uniq thangTypes, false, 'original'
    thangTypes = _.reject thangTypes, (tt) -> tt.kind in ['Mark', undefined]
    groupMap = {}
    for thangType in thangTypes
      groupMap[thangType.kind] ?= []
      groupMap[thangType.kind].push thangType

    groups = []
    for groupName in Object.keys(groupMap).sort()
      someThangTypes = groupMap[groupName]
      someThangTypes = _.sortBy someThangTypes, 'name'
      group =
        name: groupName
        thangs: someThangTypes
      groups.push group

    context.thangTypes = thangTypes
    context.groups = groups
    context

  undo: (e) ->
    if not @editThangView then @thangsTreema.undo() else @editThangView.undo()

  redo: (e) ->
    if not @editThangView then @thangsTreema.redo() else @editThangView.redo()

  afterRender: ->
    super()
    return unless @supermodel.finished()
    $('.tab-content').mousedown @selectAddThang
    $('#thangs-list').bind 'mousewheel', @preventBodyScrollingInThangList
    @$el.find('#extant-thangs-filter button:first').button('toggle')
    $(window).on 'resize', @onWindowResize
    @addThangsView = @insertSubView new AddThangsView world: @world
    @buildInterface() # refactor to not have this trigger when this view re-renders?
    if _.keys(@thangsTreema.data).length
      @$el.find('#canvas-overlay').css('display', 'none')

  onFilterExtantThangs: (e) ->
    @$el.find('#extant-thangs-filter button.active').button('toggle')
    button = $(e.target).closest('button')
    button.button('toggle')
    val = button.val()
    @thangsTreema.$el.removeClass(@lastHideClass) if @lastHideClass
    @thangsTreema.$el.addClass(@lastHideClass = "hide-except-#{val}") if val

  preventBodyScrollingInThangList: (e) ->
    @scrollTop += (if e.deltaY < 0 then 1 else -1) * 30
    e.preventDefault()

  buildInterface: (e) ->
    @level = e.level if e

    data = $.extend(true, [], @level.attributes.thangs ? [])
    thangsObject = @groupThangs(data)

    schema = {
      type: 'object'
      format: 'thangs-folder'
      additionalProperties: {
        anyOf: [
          {
            type: 'object'
            format: 'thang'
            required: ['thangType', 'id']
          }
          { $ref: '#' }
        ]
      }
    }

    treemaOptions =
      schema: schema
      data: thangsObject
      skipValidation: true
      supermodel: @supermodel
      callbacks:
        change: @onThangsChanged
        select: @onTreemaThangSelected
        dblclick: @onTreemaThangDoubleClicked
      readOnly: true
      nodeClasses:
        thang: ThangNode
        'thangs-folder': ThangsFolderNode
      world: @world

    @thangsTreema = @$el.find('#thangs-treema').treema treemaOptions
    @thangsTreema.build()
    @thangsTreema.open()
    @openSmallerFolders(@thangsTreema)

    @onThangsChanged()  # Initialize the World with Thangs
    @initSurface()
    thangsHeaderHeight = $('#thangs-header').height()
    oldHeight = $('#thangs-list').height()
    $('#thangs-list').height(oldHeight - thangsHeaderHeight)
    if data?.length
      @$el.find('.generate-terrain-button').hide()

  openSmallerFolders: (folderTreema) ->
    children = _.values folderTreema.childrenTreemas
    for child in children
      continue if child.data.thangType
      if _.keys(child.data).length < 5
        child.open()
        @openSmallerFolders(child)

  initSurface: ->
    webGLCanvas = $('canvas#webgl-surface', @$el)
    normalCanvas = $('canvas#normal-surface', @$el)
    @surface = new Surface(@world, normalCanvas, webGLCanvas, {
      paths: false
      coords: true
      grid: true
      navigateToSelection: false
      thangTypes: @supermodel.getModels(ThangType)
      showInvisible: true
      frameRate: 15
      levelType: @level.get 'type', true
      @gameUIState
      handleEvents: false
    })
    @surface.playing = false
    @surface.setWorld @world
    @surface.lankBoss.suppressSelectionSounds = true
    @centerCamera()

  centerCamera: ->
    [width, height] = @world.size()
    width = Math.max width, 80
    height = Math.max height, 68
    {left, top, right, bottom} = @world.getBounds()
    center = x: left + width / 2, y: bottom + height / 2
    sup = @surface.camera.worldToSurface center
    zoom = 0.94 * 92.4 / width  # Zoom 1.0 lets us see 92.4 meters.
    @surface.camera.zoomTo(sup, zoom, 0)

  destroy: ->
    @selectAddThangType null
    @surface?.destroy()
    $(window).off 'resize', @onWindowResize
    $(document).unbind 'contextmenu', @preventDefaultContextMenu
    @thangsTreema?.destroy()
    super()

  onViewSwitched: (e) ->
    @selectAddThang null, true
    @surface?.lankBoss?.selectLank null, null

  onStageMouseDown: (e) ->
    # initial values for a mouse click lifecycle
    @dragged = 0
    @willUnselectSprite = false
    @gameUIState.set('canDragCamera', true)
    
    if @addThangLank?.thangType.get('kind') is 'Wall'
      @paintingWalls = true
      @gameUIState.set('canDragCamera', false)

    else if @addThangLank
      # We clicked on the background when we had an add Thang selected, so add it
      @addThang @addThangType, @addThangLank.thang.pos
      
    else if e.onBackground
      @gameUIState.set('selected', [])

  onStageMouseMove: (e) ->
    @dragged += 1

  onStageMouseUp: (e) ->
    @paintingWalls = false
    $('#contextmenu').hide()

  onSpriteMouseDown: (e) ->
    nativeEvent = e.originalEvent.nativeEvent
    # update selection
    selected = []
    if nativeEvent.metaKey or nativeEvent.ctrlKey
      selected = _.clone(@gameUIState.get('selected'))
    if e.thang?.isSelectable
      alreadySelected = _.find(selected, (s) -> s.thang is e.thang)
      if alreadySelected
        # move to end (make it the last selected) and maybe unselect it
        @willUnselectSprite = true
        selected = _.without(selected, alreadySelected)
      selected.push({ thang: e.thang, sprite: e.sprite, spellName: e.spellName })
    if _.any(selected) and key.alt
      # Clone selected thang instead of selecting it
      lastSelected = _.last(selected)
      @selectAddThangType lastSelected.thang.spriteName, lastSelected.thang
      selected = []
    @gameUIState.set('selected', selected)
    if _.any(selected)
      @gameUIState.set('canDragCamera', false)

  onSpriteDragged: (e) ->
    selected = @gameUIState.get('selected')
    return unless _.any(selected) and @dragged > 10
    @willUnselectSprite = false
    {stageX, stageY} = e.originalEvent

    # move the one under the mouse
    lastSelected = _.last(selected)
    cap = @surface.camera.screenToCanvas x: stageX, y: stageY
    wop = @surface.camera.canvasToWorld cap
    wop.z = lastSelected.thang.depth / 2
    posBefore = _.clone(lastSelected.thang.pos)
    @adjustThangPos lastSelected.sprite, lastSelected.thang, wop
    posAfter = lastSelected.thang.pos

    # move any others selected, proportionally to how the 'main' sprite moved
    xDiff = posAfter.x - posBefore.x
    yDiff = posAfter.y - posBefore.y
    if xDiff or yDiff
      for singleSelected in selected.slice(0, selected.length - 1)
        newPos = {
          x: singleSelected.thang.pos.x + xDiff
          y: singleSelected.thang.pos.y + yDiff
        }
        @adjustThangPos singleSelected.sprite, singleSelected.thang, newPos

    # move the camera if we're on the edge of the screen
    [w, h] = [@surface.camera.canvasWidth, @surface.camera.canvasHeight]
    sidebarWidths = ((if @$el.find(id).hasClass('hide') then 0 else (@$el.find(id).outerWidth() / @surface.camera.canvasScaleFactorX)) for id in ['#all-thangs', '#add-thangs-view'])
    w -= sidebarWidth for sidebarWidth in sidebarWidths
    cap.x -= sidebarWidths[0]
    @calculateMovement(cap.x / w, cap.y / h, w / h)

  onSpriteMouseUp: (e) ->
    selected = @gameUIState.get('selected')
    if e.originalEvent.nativeEvent.button == 2 and _.any(selected)
      @onSpriteContextMenu e
    clearInterval(@movementInterval) if @movementInterval?
    @movementInterval = null
    
    return unless _.any(selected)
    
    for singleSelected in selected
      pos = singleSelected.thang.pos
  
      thang = _.find(@level.get('thangs') ? [], {id: singleSelected.thang.id})
      path = "#{@pathForThang(thang)}/components/original=#{LevelComponent.PhysicalID}"
      physical = @thangsTreema.get path
      continue if not physical or (physical.config.pos.x is pos.x and physical.config.pos.y is pos.y)
      @thangsTreema.set path + '/config/pos', x: pos.x, y: pos.y, z: pos.z
      
    if @willUnselectSprite
      clickedSprite = _.find(selected, {sprite: e.sprite})
      @gameUIState.set('selected', _.without(selected, clickedSprite))

  onSpriteDoubleClicked: (e) ->
    return if @dragged > 10
    return unless e.thang
    @editThang thangID: e.thang.id

  onRandomTerrainGenerated: (e) ->
    @thangsBatch = []
    @hush = true
    nonRandomThangs = (thang for thang in @flattenThangs(@thangsTreema.data) when not /Random/.test thang.id)
    @thangsTreema.set '', @groupThangs(nonRandomThangs)

    listening = {}
    for thang in e.thangs
      @selectAddThangType thang.id

      # kind of a hack to get the walls to show up correctly when they load.
      # might also fix other thangs who need to show up looking a certain way based on thang type components
      unless @addThangType.isFullyLoaded() or listening[@addThangType.cid]
        listening[@addThangType.cid] = true
        @listenToOnce @addThangType, 'build-complete', @onThangsChanged

      @addThang @addThangType, thang.pos, true
    @hush = false
    @onThangsChanged()
    @selectAddThangType null

  onChangeSelected: (gameUIState, selected) ->
    previousSprite = gameUIState.previousAttributes()?.selected?.sprite
    sprite = selected?.sprite
    thang = selected?.thang

    previousSprite?.setNameLabel?(null) unless previousSprite is sprite
    
    if thang and not (@addThangLank and @addThangType.get('name') in overlappableThangTypeNames)
      # We clicked on a Thang (or its Treema), so select the Thang
      @selectAddThang(null, true)
      @selectedExtantThangClickTime = new Date()
      # Show the label above selected thang, notice that we may get here from thang-edit-view, so it will be selected but no label
      sprite.setNameLabel(sprite.thangType.get('name') + ': ' + thang.id)
      sprite.updateLabels()
      sprite.updateMarks()

  justAdded: -> @lastAddTime and (new Date() - @lastAddTime) < 150

  selectAddThang: (e, forceDeselect=false) =>
    return if e? and $(e.target).closest('#thang-search').length # Ignore if you're trying to search thangs
    return unless (e? and $(e.target).closest('#thangs-tab-view').length) or key.isPressed('esc') or forceDeselect
    if e then target = $(e.target) else target = @$el.find('.add-thangs-palette')  # pretend to click on background if no event
    return true if target.attr('id') is 'webgl-surface'
    target = target.closest('.add-thang-palette-icon')
    wasSelected = target.hasClass 'selected'
    @$el.find('.add-thangs-palette .add-thang-palette-icon.selected').removeClass('selected')
    @selectAddThangType(if wasSelected then null else target.attr 'data-thang-type') unless key.alt or key.meta
    @addThangLank?.playSound? 'selected'
    target.addClass('selected') if @addThangType

  moveAddThangSelection: (direction) ->
    return unless @addThangType
    icons = $('.add-thangs-palette .add-thang-palette-icon')
    selectedIcon = icons.filter('.selected')
    selectedIndex = icons.index selectedIcon
    nextSelectedIndex = (selectedIndex + direction + icons.length) % icons.length
    @selectAddThang {target: icons[nextSelectedIndex]}

  selectAddThangType: (type, @cloneSourceThang) ->
    if _.isString type
      type = _.find @supermodel.getModels(ThangType), (m) -> m.get('name') is type
    pos = @addThangLank?.thang.pos  # Maintain old sprite's pos if we have it
    @surface.lankBoss.removeLank @addThangLank if @addThangLank
    @addThangType = type
    if @addThangType
      @surface.lankBoss.reallyStopMoving = true
      thang = @createAddThang()
      @addThangLank = @surface.lankBoss.addThangToLanks thang, @surface.lankBoss.layerAdapters['Floating']
      @addThangLank.notOfThisWorld = true
      @addThangLank.sprite.alpha = 0.75
      pos ?= x: Math.round(@world.width / 2), y: Math.round(@world.height / 2)
      @adjustThangPos @addThangLank, thang, pos
    else
      @addThangLank = null
      @surface?.lankBoss.reallyStopMoving = false

  createEssentialComponents: (defaultComponents) ->
    physicalConfig = {pos: {x: 10, y: 10, z: 1}}
    if physicalOriginal = _.find(defaultComponents ? [], original: LevelComponent.PhysicalID)
      physicalConfig.pos.z = physicalOriginal.config?.pos?.z ? 1  # Get the z right
    [
      {original: LevelComponent.ExistsID, majorVersion: 0, config: {}}
      {original: LevelComponent.PhysicalID, majorVersion: 0, config: physicalConfig}
    ]

  createAddThang: ->
    allComponents = (lc.attributes for lc in @supermodel.getModels LevelComponent)
    rawComponents = @addThangType.get('components') ? []
    rawComponents = @createEssentialComponents() unless rawComponents.length
    mockThang = {components: rawComponents}
    @level.sortThangComponents [mockThang], allComponents
    components = []
    for raw in mockThang.components
      comp = _.find allComponents, {original: raw.original}
      continue if comp.name in ['Selectable', 'Attackable']  # Don't draw health bars or intercept clicks
      componentClass = @world.loadClassFromCode comp.js, comp.name, 'component'
      components.push [componentClass, raw.config]
    thang = new Thang @world, @addThangType.get('name'), 'Add Thang Phantom'
    thang.addComponents components...
    thang

  adjustThangPos: (sprite, thang, pos) ->
    if key.shift
      # Meter resolution when holding shift, not caring about thang size.
      pos.x = Math.round pos.x
      pos.y = Math.round pos.y
    else
      snap = sprite?.data?.snap or sprite?.thangType?.get('snap') or x: 0.01, y: 0.01  # Centimeter resolution by default
      pos.x = Math.round((pos.x - (thang.width ? 1) / 2) / snap.x) * snap.x + (thang.width ? 1) / 2
      pos.y = Math.round((pos.y - (thang.height ? 1) / 2) / snap.y) * snap.y + (thang.height ? 1) / 2
    pos.z = thang.depth / 2
    thang.pos = pos
    thang.stateChanged = true
    @surface.lankBoss.update true  # Make sure Obstacle layer resets cache

  onSurfaceMouseMoved: (e) ->
    return unless @addThangLank
    wop = @surface.camera.screenToWorld x: e.x, y: e.y
    wop.z = 0.5
    @adjustThangPos @addThangLank, @addThangLank.thang, wop
    if @paintingWalls
      unless _.find @surface.lankBoss.lankArray, ((lank) =>
        lank.thangType.get('kind') is 'Wall' and
        Math.abs(lank.thang.pos.x - @addThangLank.thang.pos.x) < 2 and
        Math.abs(lank.thang.pos.y - @addThangLank.thang.pos.y) < 2 and
        lank isnt @addThangLank
      )
        @addThang @addThangType, @addThangLank.thang.pos
        @lastAddTime = new Date()
        @paintedWalls = true
    null

  onSurfaceMouseOver: (e) ->
    return unless @addThangLank
    @addThangLank.sprite.visible = true

  onSurfaceMouseOut: (e) ->
    return unless @addThangLank
    @addThangLank.sprite.visible = false

  calculateMovement: (pctX, pctY, widthHeightRatio) ->
    MOVE_TOP_MARGIN = 1.0 - MOVE_MARGIN
    if MOVE_TOP_MARGIN > pctX > MOVE_MARGIN and MOVE_TOP_MARGIN > pctY > MOVE_MARGIN
      clearInterval(@movementInterval) if @movementInterval?
      @movementInterval = null
      return @moveLatitude = @moveLongitude = @speed = 0

    # calculating speed to be 0.0 to 1.0 within the movement buffer on the outer edge
    diff = (MOVE_MARGIN * 2) # comments are assuming MOVE_MARGIN is 0.1
    @speed = Math.max(Math.abs(pctX-0.5), Math.abs(pctY-0.5)) * 2 # pct is now 0.8 - 1.0
    @speed -= 1.0 - diff # 0.0 - 0.2
    @speed *= (1.0 / diff) # 0.0 - 1.0
    @speed *= MOVE_SPEED

    @moveLatitude = pctX * 2 - 1
    @moveLongitude = pctY * 2 - 1
    @moveLongitude /= widthHeightRatio if widthHeightRatio > 1.0
    @moveLatitude *= widthHeightRatio if widthHeightRatio < 1.0
    @movementInterval = setInterval(@moveSide, 16) unless @movementInterval?

  moveSide: =>
    return unless @speed
    c = @surface.camera
    p = {x: c.target.x + @moveLatitude * @speed / c.zoom, y: c.target.y + @moveLongitude * @speed / c.zoom}
    c.zoomTo(p, c.zoom, 0)

  deleteSelectedExtantThang: (e) =>
    return if $(e.target).hasClass 'treema-node'
    selected = @gameUIState.get('selected')
    return unless _.any(selected)

    for singleSelected in selected
      thang = @getThangByID(singleSelected.thang.id)
      @thangsTreema.delete(@pathForThang(thang))
      @deleteEmptyTreema(thang)
      Thang.resetThangIDs()  # TODO: find some way to do this when we delete from treema, too

  deleteEmptyTreema: (thang)->
    thangType = @supermodel.getModelByOriginal ThangType, thang.thangType
    children = @thangsTreema.childrenTreemas
    thangKind = children[thangType.get('kind', true)].data
    thangName = thangKind[thangType.get('name', true)]
    if Object.keys(thangName).length == 0
      folderPath = [thangType.get('kind', true), thangType.get('name', true)].join('/')
      @thangsTreema.delete(folderPath)
      if Object.keys(thangKind).length == 0
        folderPath = [thangType.get('kind', true)].join('/')
        @thangsTreema.delete(folderPath)

  groupThangs: (thangs) ->
    # array of thangs -> foldered thangs
    grouped = {}
    for thang, index in thangs
      path = @folderForThang(thang)
      obj = grouped
      for key in path
        obj[key] ?= {}
        obj = obj[key]
      obj[thang.id] = thang
      thang.index = index
    grouped

  folderForThang: (thang) ->
    thangType = @supermodel.getModelByOriginal ThangType, thang.thangType
    console.error 'uhh, we had kind', thangType.get('kind', true), 'for', thangType unless thangType.get('kind', true)
    [thangType.get('kind', true), thangType.get('name', true)]

  pathForThang: (thang) ->
    folder = @folderForThang(thang)
    folder.push thang.id
    folder.join('/')

  flattenThangs: (thangs) ->
    # foldered thangs -> array of thangs
    flattened = []
    for key, value of thangs
      if value.id? and value.thangType
        flattened.push value
      else
        flattened = flattened.concat @flattenThangs(value)
    flattened

  populateFoldersForThang: (thang) ->
    thangFolder = @folderForThang(thang)
    prefix = ''
    for segment in thangFolder
      if prefix then prefix += '/'
      prefix += segment
      if not @thangsTreema.get(prefix) then @thangsTreema.set(prefix, {})

  onThangsChanged: (skipSerialization) =>
    return if @hush

    # keep the thangs in the same order as before, roughly
    thangs = @flattenThangs(@thangsTreema.data)
    thangs = $.extend true, [], thangs
    thangs = _.sortBy thangs, 'index'
    delete thang.index for thang in thangs

    @level.set 'thangs', thangs
    return if @editThangView
    return if skipSerialization
    serializedLevel = @level.serialize @supermodel, null, null, true
    try
      @world.loadFromLevel serializedLevel, false
    catch error
      console.error 'Catastrophic error loading the level:', error
    thang.isSelectable = not thang.isLand for thang in @world.thangs  # let us select walls and such
    @surface?.setWorld @world
    @surface?.lankBoss.cachedObstacles = false
    @selectAddThangType @addThangType, @cloneSourceThang if @addThangType  # make another addThang sprite, since the World just refreshed

    # update selection, since the thangs have been remade
    selected = @gameUIState.get('selected')
    if _.any(selected)
      for singleSelected in selected
        sprite = @surface.lankBoss.lanks[singleSelected.thang.id]
        if sprite
          sprite.updateMarks()
          singleSelected.sprite = sprite
          singleSelected.thang = sprite.thang
    Backbone.Mediator.publish 'editor:thangs-edited', thangs: @world.thangs

  onTreemaThangSelected: (e, selectedTreemas) =>
    selectedThangTreemas = _.filter(selectedTreemas, (t) -> t instanceof ThangNode)
    thangIDs = (node.data.id for node in selectedThangTreemas)
    lanks = (@surface.lankBoss.lanks[thangID] for thangID in thangIDs when thangID) 
    selected = ({ thang: lank.thang, sprite: lank } for lank in lanks when lank)
    @gameUIState.set('selected', selected)

  onTreemaThangDoubleClicked: (e, treema) =>
    nativeEvent = e.originalEvent.nativeEvent
    return if nativeEvent and (nativeEvent.ctrlKey or nativeEvent.metaKey)
    id = treema?.data?.id
    @editThang thangID: id if id

  getThangByID: (id) -> _.find(@level.get('thangs') ? [], {id: id})

  addThang: (thangType, pos, batchInsert=false) ->
    @$el.find('.generate-terrain-button').hide()
    if batchInsert
      if thangType.get('name') is 'Hero Placeholder'
        thangID = 'Hero Placeholder'
        return if not (@level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev']) or @getThangByID(thangID)
      else
        thangID = "Random #{thangType.get('name')} #{@thangsBatch.length}"
    else
      thangID = Thang.nextID(thangType.get('name'), @world) until thangID and not @getThangByID(thangID)
    if @cloneSourceThang
      components = _.cloneDeep @getThangByID(@cloneSourceThang.id).components
    else if @level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev']
      components = []  # Load them all from default ThangType Components
    else
      components = _.cloneDeep thangType.get('components') ? []
    components = @createEssentialComponents(thangType.get('components')) unless components.length
    physical = _.find components, (c) -> c.config?.pos?
    physical.config.pos = x: pos.x, y: pos.y, z: physical.config.pos.z if physical
    thang = thangType: thangType.get('original'), id: thangID, components: components
    if batchInsert
      @thangsBatch.push thang
    @populateFoldersForThang(thang)
    @thangsTreema.set(@pathForThang(thang), thang)

  editThang: (e) ->
    if e.target  # click event
      thangData = $(e.target).data 'thang-data'
    else  # Mediator event
      thangData = @getThangByID(e.thangID)
    return unless thangData
    @editThangView = new LevelThangEditView thangData: thangData, level: @level, world: @world, supermodel: @supermodel, oldPath: @pathForThang(thangData)  # supermodel needed for checkForMissingSystems
    @insertSubView @editThangView
    @$el.find('>').hide()
    @editThangView.$el.show()
    Backbone.Mediator.publish 'editor:view-switched', {}

  onLevelThangDoneEditing: (e) ->
    @removeSubView @editThangView
    @editThangView = null
    @updateEditedThang e.thangData, e.oldPath
    @$el.find('>').show()

  onLevelThangEdited: (e) ->
    @updateEditedThang e.thangData, e.oldPath

  updateEditedThang: (newThang, oldPath) ->
    @hush = true
    @thangsTreema.delete oldPath
    @populateFoldersForThang(newThang)
    @thangsTreema.set(@pathForThang(newThang), newThang)
    @hush = false
    @onThangsChanged()

  preventDefaultContextMenu: (e) ->
    return unless $(e.target).closest('#canvas-wrapper').length
    e.preventDefault()

  onSpriteContextMenu: (e) ->
    {clientX, clientY} = e.originalEvent.nativeEvent
    if @addThangType
      $('#duplicate a').html $.i18n.t 'editor.stop_duplicate'
    else
      $('#duplicate a').html $.i18n.t 'editor.duplicate'
    $('#contextmenu').css { position: 'fixed', left: clientX, top: clientY }
    $('#contextmenu').show()

  #- Context menu callbacks

  onDeleteClicked: (e) ->
    $('#contextmenu').hide()
    @deleteSelectedExtantThang e

  onDuplicateClicked: (e) ->
    $('#contextmenu').hide()
    selected = _.last(@gameUIState.get('selected'))
    @selectAddThangType(selected.thang.spriteName, selected.thang)

  onClickRotationButton: (e) ->
    $('#contextmenu').hide()
    rotation = parseFloat($(e.target).closest('button').data('rotation'))
    @rotateSelectedThangTo rotation * Math.PI

  modifySelectedThangComponentConfig: (thang, componentOriginal, modificationFunction) ->
    return unless thang
    @hush = true
    thangData = @getThangByID thang.id
    thangData = $.extend true, {}, thangData
    component = _.find thangData.components, {original: componentOriginal}
    unless component
      component = original: componentOriginal, config: {}, majorVersion: 0
      thangData.components.push component
    modificationFunction component
    @thangsTreema.set @pathForThang(thangData), thangData
    @hush = false
    @onThangsChanged true
    thang.stateChanged = true
    lank = @surface.lankBoss.lanks[thang.id]
    lank.update true
    lank.marks.debug?.destroy()
    delete lank.marks.debug
    lank.setDebug true

  rotateSelectedThangTo: (radians) ->
    for singleSelected in @gameUIState.get('selected')
      selectedThang = singleSelected.thang
      @modifySelectedThangComponentConfig selectedThang, LevelComponent.PhysicalID, (component) =>
        component.config.rotation = radians
        selectedThang.rotation = component.config.rotation

  rotateSelectedThangBy: (radians) ->
    for singleSelected in @gameUIState.get('selected')
      selectedThang = singleSelected.thang
      @modifySelectedThangComponentConfig selectedThang, LevelComponent.PhysicalID, (component) =>
        component.config.rotation = ((component.config.rotation ? 0) + radians) % (2 * Math.PI)
        selectedThang.rotation = component.config.rotation

  moveSelectedThangBy: (xDir, yDir) ->
    for singleSelected in @gameUIState.get('selected')
      selectedThang = singleSelected.thang
      @modifySelectedThangComponentConfig selectedThang, LevelComponent.PhysicalID, (component) =>
        component.config.pos.x += 0.5 * xDir
        component.config.pos.y += 0.5 * yDir
        selectedThang.pos.x = component.config.pos.x
        selectedThang.pos.y = component.config.pos.y

  resizeSelectedThangBy: (xDir, yDir) ->
    for singleSelected in @gameUIState.get('selected')
      selectedThang = singleSelected.thang
      @modifySelectedThangComponentConfig selectedThang, LevelComponent.PhysicalID, (component) =>
        component.config.width = (component.config.width ? 4) + 0.5 * xDir
        component.config.height = (component.config.height ? 4) + 0.5 * yDir
        selectedThang.width = component.config.width
        selectedThang.height = component.config.height

  toggleSelectedThangCollision: ->
    for singleSelected in @gameUIState.get('selected')
      selectedThang = singleSelected.thang
      @modifySelectedThangComponentConfig selectedThang, LevelComponent.CollidesID, (component) =>
        component.config ?= {}
        component.config.collisionCategory = if component.config.collisionCategory is 'none' then 'ground' else 'none'
        selectedThang.collisionCategory = component.config.collisionCategory

  toggleThangsContainer: (e) ->
    $('#all-thangs').toggleClass('hide')

  toggleThangsPalette: (e) ->
    $('#add-thangs-view').toggleClass('hide')

class ThangsFolderNode extends TreemaNode.nodeMap.object
  valueClass: 'treema-thangs-folder'
  nodeDescription: 'Thang'
  @nameToThangTypeMap: null

  getTrackedActionDescription: (trackedAction) ->
    trackedActionDescription = super(trackedAction)
    if trackedActionDescription is 'Edit ' + @nodeDescription
      path = trackedAction.path.split '/'
      if path[path.length-1] is 'pos'
        trackedActionDescription = 'Move Thang'
    trackedActionDescription

  buildValueForDisplay: (valEl, data) ->
    el = $("<span><strong>#{@keyForParent}</strong> <span class='text-muted'>(#{@countThangs(data)})</span></span>")

    # Kind of like having the portraits on the individual thang rows, rather than the parent folder row
    # but keeping this logic here in case we want to have it the other way.
#    if thangType = @nameToThangType(@keyForParent)
#      el.prepend($("<img class='img-circle' src='#{thangType.getPortraitURL()}' />"))
    valEl.append(el)

  countThangs: (data) ->
    return 0 if data.thangType and data.id?
    num = 0
    for key, value of data
      if value.thangType and value.id?
        num += 1
      else
        num += @countThangs(value)
    num

  nameToThangType: (name) ->
    if not ThangsFolderNode.nameToThangTypeMap
      thangTypes = @settings.supermodel.getModels(ThangType)
      map = {}
      map[thangType.get('name')] = thangType for thangType in thangTypes
      ThangsFolderNode.nameToThangTypeMap = map
    ThangsFolderNode.nameToThangTypeMap[name]

class ThangNode extends TreemaObjectNode
  valueClass: 'treema-thang'
  collection: false
  @thangNameMap: {}
  @thangKindMap: {}
  buildValueForDisplay: (valEl, data) ->
    pos = _.find(data.components, (c) -> c.config?.pos?)?.config.pos  # TODO: hack
    s = data.id
    if pos
      s += " (#{Math.round(pos.x)}, #{Math.round(pos.y)})"
    else
      s += ' (non-physical)'
    @buildValueForDisplaySimply valEl, s

    thangType = @settings.supermodel.getModelByOriginal(ThangType, data.thangType)
    if thangType
      valEl.prepend($("<img class='img-circle' src='#{thangType.getPortraitURL()}' />"))

  onEnterPressed: ->
    Backbone.Mediator.publish 'editor:edit-level-thang', thangID: @getData().id
