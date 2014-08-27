ThangType = require 'models/ThangType'
SpriteParser = require 'lib/sprites/SpriteParser'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
CocoSprite = require 'lib/surface/CocoSprite'
Camera = require 'lib/surface/Camera'
DocumentFiles = require 'collections/DocumentFiles'

RootView = require 'views/kinds/RootView'
ThangComponentsEditView = require 'views/editor/component/ThangComponentsEditView'
ThangTypeVersionsModal = require './ThangTypeVersionsModal'
ThangTypeColorsTabView = require './ThangTypeColorsTabView'
PatchesView = require 'views/editor/PatchesView'
ForkModal = require 'views/editor/ForkModal'
SaveVersionModal = require 'views/modal/SaveVersionModal'
template = require 'templates/editor/thang/thang-type-edit-view'
storage = require 'lib/storage'

CENTER = {x: 200, y: 300}

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

  events:
    'click #clear-button': 'clearRawData'
    'click #upload-button': -> @$el.find('input#real-upload-button').click()
    'change #real-upload-button': 'animationFileChosen'
    'change #animations-select': 'showAnimation'
    'click #marker-button': 'toggleDots'
    'click #end-button': 'endAnimation'
    'click #history-button': 'showVersionHistory'
    'click #fork-start-button': 'startForking'
    'click #save-button': 'openSaveModal'
    'click #patches-tab': -> @patchesView.load()
    'click .play-with-level-button': 'onPlayLevel'
    'click .play-with-level-parent': 'onPlayLevelSelect'
    'keyup .play-with-level-input': 'onPlayLevelKeyUp'

  subscriptions:
    'save-new-version': 'saveNewThangType'

  # init / render

  constructor: (options, @thangTypeID) ->
    super options
    @mockThang = $.extend(true, {}, @mockThang)
    @thangType = new ThangType(_id: @thangTypeID)
    @thangType = @supermodel.loadModel(@thangType, 'thang').model
    @thangType.saveBackups = true
    @listenToOnce @thangType, 'sync', ->
      @files = @supermodel.loadCollection(new DocumentFiles(@thangType), 'files').model
    @refreshAnimation = _.debounce @refreshAnimation, 500

  getRenderData: (context={}) ->
    context = super(context)
    context.thangType = @thangType
    context.animations = @getAnimationNames()
    context.authorized = not me.get('anonymous')
    context.recentlyPlayedLevels = storage.load('recently-played-levels') ? ['items']
    context

  getAnimationNames: ->
    raw = _.keys(@thangType.get('raw').animations)
    raw = ("raw:#{name}" for name in raw)
    main = _.keys(@thangType.get('actions') or {})
    main.concat(raw)

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

  initComponents: =>
    options =
      components: @thangType.get('components') ? []
      supermodel: @supermodel

    @thangComponentEditView = new ThangComponentsEditView options
    @listenTo @thangComponentEditView, 'components-changed', @onComponentsChanged
    @insertSubView @thangComponentEditView

  onComponentsChanged: (components) =>
    @thangType.set 'components', components

  makeDot: (color) ->
    circle = new createjs.Shape()
    circle.graphics.beginFill(color).beginStroke('black').drawCircle(0, 0, 5)
    circle.x = CENTER.x
    circle.y = CENTER.y
    circle.scaleY = 0.5
    circle

  initStage: ->
    canvas = @$el.find('#canvas')
    @stage = new createjs.Stage(canvas[0])
    @camera?.destroy()
    @camera = new Camera canvas

    @torsoDot = @makeDot('blue')
    @mouthDot = @makeDot('yellow')
    @aboveHeadDot = @makeDot('green')
    @groundDot = @makeDot('red')
    @stage.addChild(@groundDot, @torsoDot, @mouthDot, @aboveHeadDot)
    @updateGrid()
    @refreshAnimation()

    createjs.Ticker.setFPS(30)
    createjs.Ticker.addEventListener('tick', @stage)

  toggleDots: ->
    @showDots = not @showDots
    @updateDots()

  updateDots: ->
    @stage.removeChild(@torsoDot, @mouthDot, @aboveHeadDot, @groundDot)
    return unless @currentSprite
    return unless @showDots
    torso = @currentSprite.getOffset 'torso'
    mouth = @currentSprite.getOffset 'mouth'
    aboveHead = @currentSprite.getOffset 'aboveHead'
    @torsoDot.x = CENTER.x + torso.x * @scale
    @torsoDot.y = CENTER.y + torso.y * @scale
    @mouthDot.x = CENTER.x + mouth.x * @scale
    @mouthDot.y = CENTER.y + mouth.y * @scale
    @aboveHeadDot.x = CENTER.x + aboveHead.x * @scale
    @aboveHeadDot.y = CENTER.y + aboveHead.y * @scale
    @stage.addChild(@groundDot, @torsoDot, @mouthDot, @aboveHeadDot)

  endAnimation: ->
    @currentSprite?.queueAction('idle')

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

  # animation select

  refreshAnimation: ->
    return @showRasterImage() if @thangType.get('raster')
    options = @getSpriteOptions()
    @thangType.resetSpriteSheetCache()
    spriteSheet = @thangType.buildSpriteSheet(options)
    $('#spritesheets').empty()
    return unless spriteSheet
    for image in spriteSheet._images
      $('#spritesheets').append(image)
    @showAnimation()
    @updatePortrait()

  showRasterImage: ->
    sprite = new CocoSprite(@thangType, @getSpriteOptions())
    @currentSprite?.destroy()
    @currentSprite = sprite
    @showImageObject(sprite.imageObject)
    @updateScale()

  showAnimation: (animationName) ->
    animationName = @$el.find('#animations-select').val() unless _.isString animationName
    return unless animationName
    if animationName.startsWith('raw:')
      animationName = animationName[4...]
      @showMovieClip(animationName)
    else
      @showSprite(animationName)
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
    @showImageObject(movieClip)

  getSpriteOptions: -> {resolutionFactor: @resolution, thang: @mockThang}

  showSprite: (actionName) ->
    options = @getSpriteOptions()
    sprite = new CocoSprite(@thangType, options)
    sprite.queueAction(actionName)
    @currentSprite?.destroy()
    @currentSprite = sprite
    @showImageObject(sprite.imageObject)

  updatePortrait: ->
    options = @getSpriteOptions()
    portrait = @thangType.getPortraitImage(options)
    return unless portrait
    portrait?.attr('id', 'portrait').addClass('img-thumbnail')
    portrait.addClass 'img-thumbnail'
    $('#portrait').replaceWith(portrait)

  showImageObject: (imageObject) ->
    @clearDisplayObject()
    imageObject.x = CENTER.x
    imageObject.y = CENTER.y
    @stage.addChildAt(imageObject, 1)
    @currentObject = imageObject
    @updateDots()

  clearDisplayObject: ->
    @stage.removeChild(@currentObject) if @currentObject?

  # sliders

  initSliders: ->
    @rotationSlider = @initSlider $('#rotation-slider', @$el), 50, @updateRotation
    @scaleSlider = @initSlider $('#scale-slider', @$el), 29, @updateScale
    @resolutionSlider = @initSlider $('#resolution-slider', @$el), 39, @updateResolution
    @healthSlider = @initSlider $('#health-slider', @$el), 100, @updateHealth

  updateRotation: =>
    value = parseInt(180 * (@rotationSlider.slider('value') - 50) / 50)
    @$el.find('.rotation-label').text " #{value}° "
    if @currentSprite
      @currentSprite.rotation = value
      @currentSprite.update(true)

  updateScale: =>
    resValue = (@resolutionSlider.slider('value') + 1) / 10
    scaleValue = (@scaleSlider.slider('value') + 1) / 10
    fixed = scaleValue.toFixed(1)
    @scale = scaleValue
    @$el.find('.scale-label').text " #{fixed}x "
    if @currentSprite
      @currentSprite.scaleFactorX = @currentSprite.scaleFactorY = scaleValue
      @currentSprite.updateScale()
    else if @currentObject?
      @currentObject.scaleX = @currentObject.scaleY = scaleValue / resValue
    @updateGrid()
    @updateDots()

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
    @currentSprite?.update()

  # save

  saveNewThangType: (e) ->
    newThangType = if e.major then @thangType.cloneNewMajorVersion() else @thangType.cloneNewMinorVersion()
    newThangType.set('commitMessage', e.commitMessage)

    res = newThangType.save()
    return unless res
    modal = $('#save-version-modal')
    @enableModalInProgress(modal)

    res.error =>
      @disableModalInProgress(modal)

    res.success =>
      url = "/editor/thang/#{newThangType.get('slug') or newThangType.id}"
      portraitSource = null
      if @thangType.get('raster')
        image = @currentSprite.imageObject.image
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

  pushChangesToPreview: =>
    # TODO: This doesn't delete old Treema keys you deleted
    for key, value of @treema.data
      @thangType.set(key, value)
    @updateSelectBox()
    @refreshAnimation()
    @updateDots()
    @updatePortrait()

  onSelectNode: (e, selected) =>
    selected = selected[0]
    return @stopShowingSelectedNode() if not selected
    path = selected.getPath()
    parts = path.split('/')
    return @stopShowingSelectedNode() unless parts.length >= 4 and path.startsWith '/raw/'
    key = parts[3]
    type = parts[2]
    vectorParser = new SpriteBuilder(@thangType)
    obj = vectorParser.buildMovieClip(key) if type is 'animations'
    obj = vectorParser.buildContainerFromStore(key) if type is 'containers'
    obj = vectorParser.buildShapeFromStore(key) if type is 'shapes'
    if obj?.bounds
      obj.regX = obj.bounds.x + obj.bounds.width / 2
      obj.regY = obj.bounds.y + obj.bounds.height / 2
    else if obj?.frameBounds?[0]
      bounds = obj.frameBounds[0]
      obj.regX = bounds.x + bounds.width / 2
      obj.regY = bounds.y + bounds.height / 2
    @showImageObject(obj) if obj
    obj.y = 200 if obj # truly center the container
    @showingSelectedNode = true
    @currentSprite?.destroy()
    @currentSprite = null
    @updateScale()
    @grid.alpha = 0.0

  stopShowingSelectedNode: ->
    return unless @showingSelectedNode
    @grid.alpha = 1.0
    @showAnimation()
    @showingSelectedNode = false

  showVersionHistory: (e) ->
    @openModalView new ThangTypeVersionsModal thangType: @thangType, @thangTypeID

  openSaveModal: ->
    @openModalView new SaveVersionModal model: @thangType

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
      @childWindow.Backbone.Mediator.publish 'level-reload-thang-type', thangType: @thangType
    else
      # Create a new Window with a blank LevelView
      scratchLevelID = level + '?dev=true'
      if me.get('name') is 'Nick'
        @childWindow = window.open("/play/level/#{scratchLevelID}", 'child_window', 'width=2560,height=1080,left=0,top=-1600,location=1,menubar=1,scrollbars=1,status=0,titlebar=1,toolbar=1', true)
      else
        @childWindow = window.open("/play/level/#{scratchLevelID}", 'child_window', 'width=1024,height=560,left=10,top=10,location=0,menubar=0,scrollbars=0,status=0,titlebar=0,toolbar=0', true)
    @childWindow.focus()

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
