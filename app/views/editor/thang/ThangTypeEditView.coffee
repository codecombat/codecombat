ThangType = require 'models/ThangType'
SpriteParser = require 'lib/sprites/SpriteParser'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
Lank = require 'lib/surface/Lank'
LayerAdapter = require 'lib/surface/LayerAdapter'
Camera = require 'lib/surface/Camera'
DocumentFiles = require 'collections/DocumentFiles'
require 'vendor/treema'

# in the template, but need to require to load them
require 'views/modal/RevertModal'

RootView = require 'views/core/RootView'
ThangComponentsEditView = require 'views/editor/component/ThangComponentsEditView'
ThangTypeVersionsModal = require './ThangTypeVersionsModal'
ThangTypeColorsTabView = require './ThangTypeColorsTabView'
PatchesView = require 'views/editor/PatchesView'
ForkModal = require 'views/editor/ForkModal'
VectorIconSetupModal = require 'views/editor/thang/VectorIconSetupModal'
SaveVersionModal = require 'views/editor/modal/SaveVersionModal'
template = require 'templates/editor/thang/thang-type-edit-view'
storage = require 'core/storage'
ExportThangTypeModal = require './ExportThangTypeModal'

CENTER = {x: 200, y: 400}

commonTasks = [
  'Upload the art.'
  'Set up the vector icon.'
]

displayedThangTypeTasks = [
  'Configure the idle action.'
  'Configure the positions (registration point, etc.).'
  'Set shadow diameter to 0 if needed.'
  'Set scale to 0.3, 0.5, or whatever is appropriate.'
  'Set rotation to isometric if needed.'
  'Set accurate Physical size, shape, and default z.'
  'Set accurate Collides collision information if needed.'
  'Double-check that fixedRotation is accurate, if it collides.'
]

animatedThangTypeTasks = displayedThangTypeTasks.concat [
  'Configure the non-idle actions.'
  'Configure any per-action registration points needed.'
  'Add flipX per action if needed to face to the right.'
  'Make sure any death and attack actions do not loop.'
  'Add defaultSimlish if needed.'
  'Add selection sounds if needed.'
  'Add per-action sound triggers.'
  'Add team color groups.'
]

containerTasks = displayedThangTypeTasks.concat [
  'Select viable terrains if not universal.'
  'Set Exists stateless: true if needed.'
]

purchasableTasks = [
  'Add a tier, or 10 + desired tier if not ready yet.'
  'Add a gem cost.'
  'Write a description.'
  'Click the Populate i18n button.'
]

defaultTasks =
  Unit: commonTasks.concat animatedThangTypeTasks.concat [
    'Start a new name category in names.coffee if needed.'
    'Set to Allied to correct team (ogres, humans, or neutral).'
    'Add AutoTargetsNearest or FightsBack if needed.'
    'Add other Components like Shoots or Casts if needed.'
    'Configure other Components, like Moves, Attackable, Attacks, etc.'
    'Override the HasAPI type if it will not be correctly inferred.'
    'Add to Existence System power table.'
  ]
  Hero: commonTasks.concat animatedThangTypeTasks.concat purchasableTasks.concat [
    'Set the hero class.'
    'Add Extended Hero Name.'
    'Upload Hero Doll Images.'
    'Start a new name category in names.coffee.'
    'Set up hero stats in Equips, Attackable, Moves.'
    'Set Collects collectRange to 2, Sees visualRange to 60.'
    'Add any custom hero abilities.'
    'Add to ThangType model hard-coded hero ids/classes list.'
    'Add to LevelHUDView hard-coded hero short names list.'
    'Add to InventoryView hard-coded hero gender list.'
    'Add to PlayHeroesModal hard-coded hero positioning logic.'
    'Add as unlock to a level and add unlockLevelName here.'
  ]
  Floor: commonTasks.concat containerTasks.concat [
    'Add 10 x 8.5 snapping.'
    'Set fixed rotation.'
    'Make sure everything is scaled to tile perfectly.'
    'Adjust SingularSprite floor scale list if necessary.'
  ]
  Wall: commonTasks.concat containerTasks.concat [
    'Add 4x4 snapping.'
    'Set fixed rotation.'
    'Set up and tune complicated wall-face actions.'
    'Make sure everything is scaled to tile perfectly.'
  ]
  Doodad: commonTasks.concat containerTasks.concat [
    'Add to GenerateTerrainModal logic if needed.'
  ]
  Misc: commonTasks.concat [
    'Add any misc tasks for this misc ThangType.'
  ]
  Mark: commonTasks.concat [
    'Check the animation framerate.'
    'Double-check that bottom of mark is just touching registration point.'
  ]
  Item: commonTasks.concat purchasableTasks.concat [
    'Set the hero class if class-specific.'
    'Upload Paper Doll Images.'
    'Configure item stats and abilities.'
  ]
  Missile: commonTasks.concat animatedThangTypeTasks.concat [
    'Make sure there is a launch sound trigger.'
    'Make sure there is a hit sound trigger.'
    'Make sure there is a die animation.'
    'Add Arrow, Shell, Beam, or other missile Component.'
    'Choose Missile.leadsShots and Missile.shootsAtGround.'
    'Choose Moves.maxSpeed and other config.'
    'Choose Expires.lifespan config if needed.'
    'Set spriteType: singular if needed for proper rendering.'
    'Add HasAPI if the missile should show up in findEnemyMissiles.'
  ]

module.exports = class ThangTypeEditView extends RootView
  id: 'thang-type-edit-view'
  className: 'editor'
  template: template
  resolution: 4
  scale: 3
  mockThang:
    health: 10.0
    maxHealth: 10.0
    hudProperties: ['health']
    acts: true

  events:
    'click #clear-button': 'clearRawData'
    'click #upload-button': -> @$el.find('input#real-upload-button').click()
    'click #set-vector-icon': 'onClickSetVectorIcon'
    'change #real-upload-button': 'animationFileChosen'
    'change #animations-select': 'showAnimation'
    'click #marker-button': 'toggleDots'
    'click #stop-button': 'stopAnimation'
    'click #play-button': 'playAnimation'
    'click #history-button': 'showVersionHistory'
    'click li:not(.disabled) > #fork-start-button': 'startForking'
    'click #save-button': 'openSaveModal'
    'click #patches-tab': -> @patchesView.load()
    'click .play-with-level-button': 'onPlayLevel'
    'click .play-with-level-parent': 'onPlayLevelSelect'
    'keyup .play-with-level-input': 'onPlayLevelKeyUp'
    'click li:not(.disabled) > #pop-level-i18n-button': 'onPopulateLevelI18N'
    'mousedown #canvas': 'onCanvasMouseDown'
    'mouseup #canvas': 'onCanvasMouseUp'
    'mousemove #canvas': 'onCanvasMouseMove'
    'click #export-sprite-sheet-btn': 'onClickExportSpriteSheetButton'

  onClickSetVectorIcon: ->
    modal = new VectorIconSetupModal({}, @thangType)
    @openModalView modal
    modal.once 'done', => @treema.set('/', @getThangData())

  subscriptions:
    'editor:thang-type-color-groups-changed': 'onColorGroupsChanged'

  # init / render

  constructor: (options, @thangTypeID) ->
    super options
    @mockThang = $.extend(true, {}, @mockThang)
    @thangType = new ThangType(_id: @thangTypeID)
    @thangType = @supermodel.loadModel(@thangType).model
    @thangType.saveBackups = true
    @listenToOnce @thangType, 'sync', ->
      @files = @supermodel.loadCollection(new DocumentFiles(@thangType), 'files').model
      @updateFileSize()
#    @refreshAnimation = _.debounce @refreshAnimation, 500

  showLoading: ($el) ->
    $el ?= @$el.find('.outer-content')
    super($el)

  getRenderData: (context={}) ->
    context = super(context)
    context.thangType = @thangType
    context.animations = @getAnimationNames()
    context.authorized = not me.get('anonymous')
    context.recentlyPlayedLevels = storage.load('recently-played-levels') ? ['items']
    context.fileSizeString = @fileSizeString
    context

  getAnimationNames: ->
    _.sortBy _.keys(@thangType.get('actions') or {}), (a) ->
      {move: 1, cast: 2, attack: 3, idle: 4, portrait: 6}[a] or 5

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @initStage()
    @buildTreema()
    @initSliders()
    @initComponents()
    @insertSubView(new ThangTypeColorsTabView(@thangType))
    @patchesView = @insertSubView(new PatchesView(@thangType), @$el.find('.patches-view'))
    @showReadOnly() if me.get('anonymous')
    @updatePortrait()

  initComponents: =>
    options =
      components: @thangType.get('components') ? []
      supermodel: @supermodel

    @thangComponentEditView = new ThangComponentsEditView options
    @listenTo @thangComponentEditView, 'components-changed', @onComponentsChanged
    @insertSubView @thangComponentEditView

  onComponentsChanged: (components) =>
    @thangType.set 'components', components

  onColorGroupsChanged: (e) ->
    @temporarilyIgnoringChanges = true
    @treema.set 'colorGroups', e.colorGroups
    @temporarilyIgnoringChanges = false

  makeDot: (color) ->
    circle = new createjs.Shape()
    circle.graphics.beginFill(color).beginStroke('black').drawCircle(0, 0, 5)
    circle.scaleY = 0.2
    circle.scaleX = 0.5
    circle

  initStage: ->
    canvas = @$el.find('#canvas')
    @stage = new createjs.Stage(canvas[0])
    @layerAdapter = new LayerAdapter({name:'Default', webGL: true})
    @topLayer = new createjs.Container()

    @layerAdapter.container.x = @topLayer.x = CENTER.x
    @layerAdapter.container.y = @topLayer.y = CENTER.y
    @stage.addChild(@layerAdapter.container, @topLayer)
    @listenTo @layerAdapter, 'new-spritesheet', @onNewSpriteSheet
    @camera?.destroy()
    @camera = new Camera canvas

    @torsoDot = @makeDot('blue')
    @mouthDot = @makeDot('yellow')
    @aboveHeadDot = @makeDot('green')
    @groundDot = @makeDot('red')
    @topLayer.addChild(@groundDot, @torsoDot, @mouthDot, @aboveHeadDot)
    @updateGrid()
    _.defer @refreshAnimation
    @toggleDots(false)

    createjs.Ticker.setFPS(30)
    createjs.Ticker.addEventListener('tick', @stage)

  toggleDots: (newShowDots) ->
    @showDots = if typeof(newShowDots) is 'boolean' then newShowDots else not @showDots
    @updateDots()

  updateDots: ->
    @topLayer.removeChild(@torsoDot, @mouthDot, @aboveHeadDot, @groundDot)
    return unless @currentLank
    return unless @showDots
    torso = @currentLank.getOffset 'torso'
    mouth = @currentLank.getOffset 'mouth'
    aboveHead = @currentLank.getOffset 'aboveHead'
    @torsoDot.x = torso.x
    @torsoDot.y = torso.y
    @mouthDot.x = mouth.x
    @mouthDot.y = mouth.y
    @aboveHeadDot.x = aboveHead.x
    @aboveHeadDot.y = aboveHead.y
    @topLayer.addChild(@groundDot, @torsoDot, @mouthDot, @aboveHeadDot)

  stopAnimation: ->
    @currentLank?.queueAction('idle')

  playAnimation: ->
    @currentLank?.queueAction(@$el.find('#animations-select').val())

  updateGrid: ->
    grid = new createjs.Container()
    line = new createjs.Shape()
    width = 1000
    line.graphics.beginFill('#666666').drawRect(-width/2, -0.5, width, 0.5)

    line.x = CENTER.x
    line.y = CENTER.y
    y = line.y
    step = 10 * @scale
    y -= step while y > 0
    while y < 500
      y += step
      newLine = line.clone()
      newLine.y = y
      grid.addChild(newLine)

    x = line.x
    x -= step while x > 0
    while x < 400
      x += step
      newLine = line.clone()
      newLine.x = x
      newLine.rotation = 90
      grid.addChild(newLine)

    @stage.removeChild(@grid) if @grid
    @stage.addChildAt(grid, 0)
    @grid = grid

  updateSelectBox: ->
    names = @getAnimationNames()
    select = @$el.find('#animations-select')
    return if select.find('option').length is names.length
    select.empty()
    select.append($('<option></option>').text(name)) for name in names

  # upload

  animationFileChosen: (e) ->
    @file = e.target.files[0]
    return unless @file
    return unless _.string.endsWith @file.type, 'javascript'
#    @$el.find('#upload-button').prop('disabled', true)
    @reader = new FileReader()
    @reader.onload = @onFileLoad
    @reader.readAsText(@file)

  onFileLoad: (e) =>
    result = @reader.result
    parser = new SpriteParser(@thangType)
    parser.parse(result)
    @treema.set('raw', @thangType.get('raw'))
    @updateSelectBox()
    @refreshAnimation()
    @updateFileSize()

  updateFileSize: ->
    file = JSON.stringify(@thangType.attributes)
    compressed = LZString.compress(file)
    size = (file.length / 1024).toFixed(1) + "KB"
    compressedSize = (compressed.length / 1024).toFixed(1) + "KB"
    gzipCompressedSize = compressedSize * 1.65  # just based on comparing ogre barracks
    @fileSizeString = "Size: #{size} (~#{compressedSize} gzipped)"
    @$el.find('#thang-type-file-size').text @fileSizeString

  # animation select

  refreshAnimation: =>
    @thangType.resetSpriteSheetCache()
    return @showRasterImage() if @thangType.get('raster')
    options = @getLankOptions()
    console.log 'refresh animation....'
    @showAnimation()
    @updatePortrait()

  showRasterImage: ->
    lank = new Lank(@thangType, @getLankOptions())
    @showLank(lank)
    @updateScale()

  onNewSpriteSheet: ->
    $('#spritesheets').empty()
    for image in @layerAdapter.spriteSheet._images
      $('#spritesheets').append(image)
    @layerAdapter.container.x = CENTER.x
    @layerAdapter.container.y = CENTER.y
    @updateScale()

  showAnimation: (animationName) ->
    animationName = @$el.find('#animations-select').val() unless _.isString animationName
    return unless animationName
    @mockThang.action = animationName
    @showAction(animationName)
    @updateRotation()
    @updateScale() # must happen after update rotation, because updateRotation calls the sprite update() method.

  showMovieClip: (animationName) ->
    vectorParser = new SpriteBuilder(@thangType)
    movieClip = vectorParser.buildMovieClip(animationName)
    return unless movieClip
    reg = @thangType.get('positions')?.registration
    if reg
      movieClip.regX = -reg.x
      movieClip.regY = -reg.y
    scale = @thangType.get('scale')
    if scale
      movieClip.scaleX = movieClip.scaleY = scale
    @showSprite(movieClip)

  getLankOptions: -> {resolutionFactor: @resolution, thang: @mockThang, preloadSounds: false}

  showAction: (actionName) ->
    options = @getLankOptions()
    lank = new Lank(@thangType, options)
    @showLank(lank)
    lank.queueAction(actionName)

  updatePortrait: ->
    options = @getLankOptions()
    portrait = @thangType.getPortraitImage(options)
    return unless portrait
    portrait?.attr('id', 'portrait').addClass('img-thumbnail')
    portrait.addClass 'img-thumbnail'
    $('#portrait').replaceWith(portrait)

  showLank: (lank) ->
    @clearDisplayObject()
    @clearLank()
    @layerAdapter.resetSpriteSheet()
    @layerAdapter.addLank(lank)
    @currentLank = lank
    @currentLankOffset = null

  showSprite: (sprite) ->
    @clearDisplayObject()
    @clearLank()
    @topLayer.addChild(sprite)
    @currentObject = sprite
    @updateDots()

  clearDisplayObject: ->
    @topLayer.removeChild(@currentObject) if @currentObject?

  clearLank: ->
    @layerAdapter.removeLank(@currentLank) if @currentLank
    @currentLank?.destroy()

  # sliders

  initSliders: ->
    @rotationSlider = @initSlider $('#rotation-slider', @$el), 50, @updateRotation
    @scaleSlider = @initSlider $('#scale-slider', @$el), 29, @updateScale
    @resolutionSlider = @initSlider $('#resolution-slider', @$el), 39, @updateResolution
    @healthSlider = @initSlider $('#health-slider', @$el), 100, @updateHealth

  updateRotation: =>
    value = parseInt(180 * (@rotationSlider.slider('value') - 50) / 50)
    @$el.find('.rotation-label').text " #{value}° "
    if @currentLank
      @currentLank.rotation = value
      @currentLank.update(true)

  updateScale: =>
    scaleValue = (@scaleSlider.slider('value') + 1) / 10
    @layerAdapter.container.scaleX = @layerAdapter.container.scaleY = @topLayer.scaleX = @topLayer.scaleY = scaleValue
    fixed = scaleValue.toFixed(1)
    @scale = scaleValue
    @$el.find('.scale-label').text " #{fixed}x "
    @updateGrid()

  updateResolution: =>
    value = (@resolutionSlider.slider('value') + 1) / 10
    fixed = value.toFixed(1)
    @$el.find('.resolution-label').text " #{fixed}x "
    @resolution = value
    @refreshAnimation()

  updateHealth: =>
    value = parseInt((@healthSlider.slider('value')) / 10)
    @$el.find('.health-label').text " #{value}hp "
    @mockThang.health = value
    @currentLank?.update()

  # save

  saveNewThangType: (e) ->
    newThangType = if e.major then @thangType.cloneNewMajorVersion() else @thangType.cloneNewMinorVersion()
    newThangType.set('commitMessage', e.commitMessage)
    newThangType.updateI18NCoverage() if newThangType.get('i18nCoverage')

    res = newThangType.save(null, {type: 'POST'})  # Override PUT so we can trigger postNewVersion logic
    return unless res
    modal = $('#save-version-modal')
    @enableModalInProgress(modal)

    res.error =>
      @disableModalInProgress(modal)

    res.success =>
      url = "/editor/thang/#{newThangType.get('slug') or newThangType.id}"
      portraitSource = null
      if @thangType.get('raster')
        #image = @currentLank.sprite.image  # Doesn't work?
        image = @currentLank.sprite.spriteSheet._images[0]
        portraitSource = imageToPortrait image
        # bit of a hacky way to get that portrait
      success = =>
        @thangType.clearBackup()
        document.location.href = url
      newThangType.uploadGenericPortrait success, portraitSource

  clearRawData: ->
    @thangType.resetRawData()
    @thangType.set 'actions', undefined
    @clearDisplayObject()
    @treema.set('/', @getThangData())

  getThangData: ->
    data = $.extend(true, {}, @thangType.attributes)
    data = _.pick data, (value, key) => not (key in ['components'])

  buildTreema: ->
    data = @getThangData()
    schema = _.cloneDeep ThangType.schema
    schema.properties = _.pick schema.properties, (value, key) => not (key in ['components'])
    options =
      data: data
      schema: schema
      files: @files
      filePath: "db/thang.type/#{@thangType.get('original')}"
      readOnly: me.get('anonymous')
      callbacks:
        change: @pushChangesToPreview
        select: @onSelectNode
    el = @$el.find('#thang-type-treema')
    @treema = @$el.find('#thang-type-treema').treema(options)
    @treema.build()
    @lastKind = data.kind

  pushChangesToPreview: =>
    return if @temporarilyIgnoringChanges
    keysProcessed = {}
    for key of @thangType.attributes
      keysProcessed[key] = true
      continue if key is 'components'
      @thangType.set(key, @treema.data[key])
    for key, value of @treema.data when not keysProcessed[key]
      @thangType.set(key, value)

    @updateSelectBox()
    @refreshAnimation()
    @updateDots()
    @updatePortrait()
    if (kind = @treema.data.kind) isnt @lastKind
      @lastKind = kind
      Backbone.Mediator.publish 'editor:thang-type-kind-changed', kind: kind
      if kind in ['Doodad', 'Floor', 'Wall'] and not @treema.data.terrains
        @treema.set '/terrains', ['Grass', 'Dungeon', 'Indoor', 'Desert', 'Mountain', 'Glacier', 'Volcano']  # So editors know to set them.
      if not @treema.data.tasks
        @treema.set '/tasks', (name: t for t in defaultTasks[kind])

  onSelectNode: (e, selected) =>
    selected = selected[0]
    @topLayer.removeChild(@boundsBox) if @boundsBox
    return @stopShowingSelectedNode() if not selected
    path = selected.getPath()
    parts = path.split('/')
    return @stopShowingSelectedNode() unless parts.length >= 4 and _.string.startsWith path, '/raw/'
    key = parts[3]
    type = parts[2]
    vectorParser = new SpriteBuilder(@thangType)
    obj = vectorParser.buildMovieClip(key) if type is 'animations'
    obj = vectorParser.buildContainerFromStore(key) if type is 'containers'
    obj = vectorParser.buildShapeFromStore(key) if type is 'shapes'

    bounds = obj?.bounds or obj?.nominalBounds
    if bounds
      @boundsBox = new createjs.Shape()
      @boundsBox.graphics.beginFill('#aaaaaa').beginStroke('black').drawRect(bounds.x, bounds.y, bounds.width, bounds.height)
      @topLayer.addChild(@boundsBox)
      obj.regX = @boundsBox.regX = bounds.x + bounds.width / 2
      obj.regY = @boundsBox.regY = bounds.y + bounds.height / 2

    @showSprite(obj) if obj
    @showingSelectedNode = true
    @currentLank?.destroy()
    @currentLank = null
    @updateScale()
    @grid.alpha = 0.0

  stopShowingSelectedNode: ->
    return unless @showingSelectedNode
    @grid.alpha = 1.0
    @showAnimation()
    @showingSelectedNode = false

  showVersionHistory: (e) ->
    @openModalView new ThangTypeVersionsModal thangType: @thangType, @thangTypeID

  onPopulateLevelI18N: ->
    @thangType.populateI18N()
    _.delay((-> document.location.reload()), 500)

  openSaveModal: ->
    modal = new SaveVersionModal model: @thangType
    @openModalView modal
    @listenToOnce modal, 'save-new-version', @saveNewThangType
    @listenToOnce modal, 'hidden', -> @stopListening(modal)

  startForking: (e) ->
    @openModalView new ForkModal model: @thangType, editorPath: 'thang'

  onPlayLevelSelect: (e) ->
    if @childWindow and not @childWindow.closed
      # We already have a child window open, so we don't need to ask for a level; we'll use its existing level.
      e.stopImmediatePropagation()
      @onPlayLevel e
    _.defer -> $('.play-with-level-input').focus()

  onPlayLevelKeyUp: (e) ->
    return unless e.keyCode is 13  # return
    input = @$el.find('.play-with-level-input')
    input.parents('.dropdown').find('.play-with-level-parent').dropdown('toggle')
    level = _.string.slugify input.val()
    return unless level
    @onPlayLevel null, level
    recentlyPlayedLevels = storage.load('recently-played-levels') ? []
    recentlyPlayedLevels.push level
    storage.save 'recently-played-levels', recentlyPlayedLevels

  onPlayLevel: (e, level=null) ->
    level ?= $(e.target).data('level')
    level = _.string.slugify level
    if @childWindow and not @childWindow.closed
      # Reset the LevelView's world, but leave the rest of the state alone
      @childWindow.Backbone.Mediator.publish 'level:reload-thang-type', thangType: @thangType
    else
      # Create a new Window with a blank LevelView
      scratchLevelID = level + '?dev=true'
      if me.get('name') is 'Nick'
        @childWindow = window.open("/play/level/#{scratchLevelID}", 'child_window', 'width=2560,height=1080,left=0,top=-1600,location=1,menubar=1,scrollbars=1,status=0,titlebar=1,toolbar=1', true)
      else
        @childWindow = window.open("/play/level/#{scratchLevelID}", 'child_window', 'width=1024,height=560,left=10,top=10,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0', true)
    @childWindow.focus()

  # Canvas mouse drag handlers

  onCanvasMouseMove: (e) ->
    return unless p1 = @canvasDragStart
    p2 = x: e.offsetX, y: e.offsetY
    offset = x: p2.x - p1.x, y: p2.y - p1.y
    @currentLank.sprite.x = @currentLankOffset.x + offset.x / @scale
    @currentLank.sprite.y = @currentLankOffset.y + offset.y / @scale
    @canvasDragOffset = offset

  onCanvasMouseDown: (e) ->
    return unless @currentLank
    @canvasDragStart = x: e.offsetX, y: e.offsetY
    @currentLankOffset ?= x: @currentLank.sprite.x, y: @currentLank.sprite.y

  onCanvasMouseUp: (e) ->
    @canvasDragStart = null
    return unless @canvasDragOffset
    return unless node = @treema.getLastSelectedTreema()
    offset = node.get '/'
    offset.x += Math.round @canvasDragOffset.x
    offset.y += Math.round @canvasDragOffset.y
    @canvasDragOffset = null
    node.set '/', offset

  onClickExportSpriteSheetButton: ->
    modal = new ExportThangTypeModal({}, @thangType)
    @openModalView(modal)

  destroy: ->
    @camera?.destroy()
    super()

imageToPortrait = (img) ->
  canvas = document.createElement('canvas')
  canvas.width = 100
  canvas.height = 100
  ctx = canvas.getContext('2d')
  scaleX = 100 / img.width
  scaleY = 100 / img.height
  ctx.scale scaleX, scaleY
  ctx.drawImage img, 0, 0
  canvas.toDataURL('image/png')
