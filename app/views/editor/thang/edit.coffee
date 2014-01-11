View = require 'views/kinds/RootView'
template = require 'templates/editor/thang/edit'
ThangType = require 'models/ThangType'
SpriteParser = require 'lib/sprites/SpriteParser'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
CocoSprite = require 'lib/surface/CocoSprite'
Camera = require 'lib/surface/Camera'
ThangComponentEditView = require 'views/editor/components/main'
DocumentFiles = require 'collections/DocumentFiles'

ColorsTabView = require './colors_tab_view'

CENTER = {x:200, y:300}

module.exports = class ThangTypeEditView extends View
  id: "editor-thang-type-edit-view"
  template: template
  startsLoading: true
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

  subscriptions:
    'save-new-version': 'saveNewThangType'

  # init / render

  constructor: (options, @thangTypeID) ->
    super options
    @mockThang = _.cloneDeep(@mockThang)
    @thangType = new ThangType(_id: @thangTypeID)
    @thangType.fetch()
    @thangType.once('sync', @onThangTypeSync)
    @refreshAnimation = _.debounce @refreshAnimation, 500

  onThangTypeSync: =>
    @startsLoading = false
    @files = new DocumentFiles(@thangType)
    @files.fetch()
    @render()

  getRenderData: (context={}) =>
    context = super(context)
    context.thangType = @thangType
    context.animations = @getAnimationNames()
    context

  getAnimationNames: ->
    raw = _.keys(@thangType.get('raw').animations)
    raw = ("raw:#{name}" for name in raw)
    main = _.keys(@thangType.get('actions') or {})
    main.concat(raw)

  afterRender: ->
    super()
    return unless @thangType.loaded
    @initStage()
    @buildTreema()
    @initSliders()
    @initComponents()
    @insertSubView(new ColorsTabView(@thangType))

  initComponents: =>
    options =
      components: @thangType.get('components') ? []
      supermodel: @supermodel
      callback: @onComponentsChanged
    @thangComponentEditView = new ThangComponentEditView options
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
    canvasWidth = parseInt(canvas.attr('width'), 10)
    canvasHeight = parseInt(canvas.attr('height'), 10)
    @camera = new Camera canvasWidth, canvasHeight

    @torsoDot = @makeDot('blue')
    @mouthDot = @makeDot('yellow')
    @aboveHeadDot = @makeDot('green')
    @groundDot = @makeDot('red')
    @stage.addChild(@groundDot, @torsoDot, @mouthDot, @aboveHeadDot)
    @updateGrid()
    @refreshAnimation()

    createjs.Ticker.setFPS(30)
    createjs.Ticker.addEventListener("tick", @stage)

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
    return unless @file.type is 'text/javascript'
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
    options = @getSpriteOptions()
    @thangType.resetSpriteSheetCache()
    spriteSheet = @thangType.buildSpriteSheet(options)
    $('#canvases').empty()
    return unless spriteSheet
    for image in spriteSheet._images
      $('#canvases').append(image)
    @showAnimation()
    @updatePortrait()

  showAnimation: (animationName) ->
    animationName = @$el.find('#animations-select').val() unless _.isString animationName
    return unless animationName
    if animationName.startsWith('raw:')
      animationName = animationName[4...]
      @showMovieClip(animationName)
    else
      @showSprite(animationName)
    @updateScale()
    @updateRotation()

  showMovieClip: (animationName) ->
    vectorParser = new SpriteBuilder(@thangType)
    movieClip = vectorParser.buildMovieClip(animationName)
    reg = @thangType.get('positions')?.registration
    if reg
      movieClip.regX = -reg.x
      movieClip.regY = -reg.y
    @showDisplayObject(movieClip)

  getSpriteOptions: -> { resolutionFactor: @resolution, thang: @mockThang}

  showSprite: (actionName) ->
    options = @getSpriteOptions()
    sprite = new CocoSprite(@thangType, options)
    sprite.queueAction(actionName)
    @currentSprite?.destroy()
    @currentSprite = sprite
    @showDisplayObject(sprite.displayObject)

  updatePortrait: ->
    options = @getSpriteOptions()
    portrait = @thangType.getPortraitImage(options)
    return unless portrait
    portrait?.attr('id', 'portrait').addClass('img-polaroid')
    portrait.addClass 'img-polaroid'
    $('#portrait').replaceWith(portrait)

  showDisplayObject: (displayObject) ->
    @clearDisplayObject()
    displayObject.x = CENTER.x
    displayObject.y = CENTER.y
    @stage.addChildAt(displayObject, 1)
    @currentObject = displayObject
    @updateDots()

  clearDisplayObject: ->
    @stage.removeChild(@currentObject) if @currentObject?

  # sliders

  initSliders: ->
    @rotationSlider = @initSlider $("#rotation-slider", @$el), 50, @updateRotation
    @scaleSlider = @initSlider $('#scale-slider', @$el), 29, @updateScale
    @resolutionSlider = @initSlider $('#resolution-slider', @$el), 39, @updateResolution
    @healthSlider = @initSlider $('#health-slider', @$el), 100, @updateHealth

  updateRotation: =>
    value = parseInt(180 * (@rotationSlider.slider('value') - 50) / 50)
    @$el.find('.rotation-label').text " #{value}° "
    if @currentSprite
      @currentSprite.rotation = value
      @currentSprite.update()

  updateScale: =>
    value = (@scaleSlider.slider('value') + 1) / 10
    fixed = value.toFixed(1)
    @scale = value
    @$el.find('.scale-label').text " #{fixed}x "
    @currentObject.scaleX = @currentObject.scaleY = value if @currentObject?
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
      newThangType.uploadGenericPortrait ->
        document.location.href = url

  clearRawData: ->
    @thangType.resetRawData()
    @clearDisplayObject()

  buildTreema: ->
    data = _.cloneDeep(@thangType.attributes)
    schema = _.cloneDeep ThangType.schema.attributes
    schema.properties = _.pick schema.properties, (value, key) => not (key in ['components'])
    data = _.pick data, (value, key) => not (key in ['components'])
    options =
      data: data
      schema: schema
      files: @files
      filePath: "db/thang.type/#{@thangType.get('original')}"
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
    @showDisplayObject(obj) if obj
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
