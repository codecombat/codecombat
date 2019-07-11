require('app/styles/editor/thang/colors_tab.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/editor/thang/colors_tab'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
{hexToHSL, hslToHex} = require 'core/utils'
require 'lib/setupTreema'
createjs = require 'lib/createjs-parts'
initSlider = require 'lib/initSlider'
tintApi = require('../../../../ozaria/site/api/tint')
tintSchema = require 'app/schemas/models/tint.schema.js'
ColorCalculator = require('./hslCalculator.vue').default

COLOR_GROUP_TAB = 'COLORGROUPTAB'
TINT_TAB = 'TINTTAB'

module.exports = class ThangTypeColorsTabView extends CocoView
  id: 'editor-thang-colors-tab-view'
  template: template
  className: 'tab-pane'

  offset: 0

  events:
    'click #color-group-btn': 'onColorGroupTab'
    'click #tint-assignment-btnTint': 'onTintAssignmentTab'

  constructor: (@thangType, options) ->
    super options
    @tab = COLOR_GROUP_TAB
    @supermodel.loadModel @thangType
    @currentColorConfig = { hue: 0, saturation: 0.5, lightness: 0.5 }
    # tint slug and index pairs.
    @tintedColorChoices = { }
    @spriteBuilder = new SpriteBuilder(@thangType) if @thangType.get('raw')
    f = =>
      @offset++
      @updateMovieClip()
    @interval = setInterval f, 1000

  destroy: ->
    @colorGroups?.destroy()
    @tintAssignments?.destroy()
    @colorCalculator?.$destroy()
    clearInterval @interval
    super()

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @createShapeButtons()
    @createColorGroupTintButtons()
    @initStage()
    @initSliders()
    @tryToBuild()

    if @tab == COLOR_GROUP_TAB
      $("#color-tint-treema").hide()
      $("#color-groups-treema").show()
      $("#shape-buttons").show()
      $("#saved-color-tabs").hide()
    else if @tab == TINT_TAB
      $("#color-tint-treema").show()
      $("#color-groups-treema").hide()
      $("#shape-buttons").hide()
      $("#saved-color-tabs").show()

    # Attach a stateless color calculator widget
    @colorCalculator = new ColorCalculator({ el: '#color-calculator' })

  # sliders

  initSliders: ->
    @hueSlider = initSlider $('#hue-slider', @$el), 0, @makeSliderCallback 'hue'
    @saturationSlider = initSlider $('#saturation-slider', @$el), 50, @makeSliderCallback 'saturation'
    @lightnessSlider = initSlider $('#lightness-slider', @$el), 50, @makeSliderCallback 'lightness'

  makeSliderCallback: (property) ->
    (e, result) =>
      @currentColorConfig[property] = result.value / 100
      console.log(@currentColorConfig)
      @updateMovieClip()

  getColorConfig: ->
    colorConfig = {}
    if @tab == COLOR_GROUP_TAB
      colorConfig[@currentColorGroupTreema.keyForParent] = @currentColorConfig
      return colorConfig

    if not @tintAssignments
      return colorConfig
    
    tintMap = {}
    for tint in @tintAssignments.data
      tintMap[tint.name] = tint

    for k, v of @tintedColorChoices
      colorConfig = _.merge(colorConfig, tintMap[k].allowedTints[v])
    colorConfig

  onColorGroupTab: ->
    @tintAssignments?.destroy()
    @tab = COLOR_GROUP_TAB
    @render()

  onTintAssignmentTab: ->
    @tab = TINT_TAB
    @render()

    tintApi.getAllTints()
      .then((tintData)=>
        tintData = tintData.filter((o) => o.slug)

        treemaOptions =
          data: tintData
          schema:
            type: 'array'
            items: tintSchema
          readOnly: true unless me.isAdmin()
          callbacks:
            change: () => @createColorGroupTintButtons()

        @tintAssignments = @$el.find('#color-tint-treema').treema treemaOptions
        @tintAssignments.build()
        @tintAssignments.open()
        @createColorGroupTintButtons()
      )

  # movie clip

  initStage: ->
    canvas = @$el.find('#tinting-display')
    @stage = new createjs.Stage(canvas[0])
    createjs.Ticker.framerate = 20
    createjs.Ticker.addEventListener('tick', @stage)
    @updateMovieClip()

  updateMovieClip: ->
    return unless @currentColorGroupTreema and @thangType.get('raw')
    actionDict = @thangType.getActions()
    animations = (a.animation for key, a of actionDict when a.animation)
    index = @offset % animations.length
    animation = animations[index]
    return @updateContainer() unless animation
    @stage.removeChild(@movieClip) if @movieClip
    options = { colorConfig: @getColorConfig() }
    @spriteBuilder.setOptions options
    @spriteBuilder.buildColorMaps()
    @movieClip = @spriteBuilder.buildMovieClip animation
    bounds = @movieClip.frameBounds?[0] ? @movieClip.nominalBounds
    larger = Math.min(400 / bounds.width, 400 / bounds.height)
    @movieClip.scaleX = larger
    @movieClip.scaleY = larger
    @movieClip.regX = bounds.x
    @movieClip.regY = bounds.y
    @stage.addChild @movieClip

  updateContainer: ->
    return unless @thangType.get('raw')
    actionDict = @thangType.getActions()
    idle = actionDict.idle
    @stage.removeChild(@container) if @container
    return unless idle?.container
    options = {colorConfig: {}}
    options.colorConfig[@currentColorGroupTreema.keyForParent] = @currentColorConfig
    @spriteBuilder.setOptions options
    @spriteBuilder.buildColorMaps()
    @container = @spriteBuilder.buildContainerFromStore idle.container
    larger = Math.min(400 / @container.bounds.width, 400 / @container.bounds.height)
    @container.scaleX = larger
    @container.scaleY = larger
    @container.regX = @container.bounds.x
    @container.regY = @container.bounds.y
    @stage.addChild @container

  createShapeButtons: ->
    buttons = $('<div></div>').prop('id', 'shape-buttons')
    inputSelectionDiv = $('<div></div>')
    inputSelectionDiv.css('margin-bottom', '15px')

    input = $('<input id="color-select" placeholder="#ffdd01"/>')
    input.css('width', '65px')
    inputSelectionDiv.append(input)

    inputBtn = $('<button>Select hex color</button>')
    inputBtn.click(() =>
      input = document.getElementById("color-select").value
      @buttons.children('button').each(() ->
        if $(this).val().toLowerCase() == input.toLowerCase().trim()
          $(this).toggleClass('selected')
      )
      @updateColorGroup()
    )

    inputSelectionDiv.append(inputBtn)
    buttons.append(inputSelectionDiv)

    shapes = (shape for key, shape of @thangType.get('raw')?.shapes or {})
    colors = (s.fc for s in shapes when s.fc?)
    colors = _.uniq(colors)
    colors.sort (a, b) ->
      aHSL = hexToHSL(a)
      bHSL = hexToHSL(b)
      if aHSL[0] > bHSL[0] then -1 else 1

    for color in colors
      button = $('<button></button>').addClass('btn')
      button.css('background', color)
      button.val color
      buttons.append(button)
    buttons.click (e) =>
      $(e.target).toggleClass('selected')
      @updateColorGroup()
    @$el.find('#shape-buttons').replaceWith(buttons)
    @buttons = buttons

  # Attaches hard coded color tabs for manipulating defined color groups on the ThangType
  createColorGroupTintButtons: ->
    return if @destroyed
    return unless @tintAssignments
    buttons = $('<div></div>').prop('id', 'saved-color-tabs')
    buttons.append($("<h1>Saved Color Presets</h1>"))

    colors = @tintAssignments.data
    for tint, i in colors
      tintName = tint.name
      @addColorTintGroup(buttons, tintName, tint.allowedTints or [], i)

    @$el.find('#saved-color-tabs').replaceWith(buttons)

  addColorTintGroup: (buttons, tintName, tints, index) ->
    buttons.append($("<h3>#{tintName}</h3>"))
    saveButton = $("<button>#{tintName}</button>")
    buttons.append($('<button />', {
      text: "Save '#{tintName}' Tints",
      class: 'save-btn',
      # Bind the variable `index` to the function in coffeescript.
      click: ((index) => () =>
        tintApi.putTint({data: @tintAssignments.data[index]})
          .catch((e) ->
            console.error(e)
          )
        )(index)
    }))

    for tint, index in tints
      tint = Object.values(tint)
      continue unless tint.length
      button = $('<button></button>').addClass('btn')
      # Add one of the tint group colors.
      button.css('background', hslToHex([tint[0].hue, tint[0].saturation, tint[0].lightness]))
      # How you capture a variable in a closure in coffeescript
      ((index) =>
        button.click (e) =>
          @tintedColorChoices[tintName] = index
          @updateMovieClip()
      )(index)
      buttons.append(button)

  tryToBuild: ->
    return unless @thangType.loaded
    data = @thangType.get('colorGroups')
    data ?= {}
    schema = @thangType.schema().properties?.colorGroups
    treemaOptions =
      data: data
      schema: schema
      readOnly: true unless me.isAdmin() or @thangType.hasWriteAccess(me)
      callbacks:
        change: @onColorGroupsChanged
        select: @onColorGroupSelected
      nodeClasses:
        'thang-color-group': ColorGroupNode
    @colorGroups = @$el.find('#color-groups-treema').treema treemaOptions
    @colorGroups.build()
    @colorGroups.open()
    keys = Object.keys @colorGroups.childrenTreemas
    @colorGroups.childrenTreemas[keys[0]]?.$el.click() if keys[0]

  onColorGroupsChanged: =>
    @thangType.set('colorGroups', @colorGroups.data)
    Backbone.Mediator.publish 'editor:thang-type-color-groups-changed', colorGroups: @colorGroups.data

  onColorGroupSelected: (e, selected) =>
    @$el.find('#color-group-settings').toggle selected.length > 0
    treema = @colorGroups.getLastSelectedTreema()
    return unless treema
    @currentColorGroupTreema = treema

    shapes = {}
    shapes[shape] = true for shape in treema.data

    colors = {}
    for key, shape of @thangType.get('raw')?.shapes or {}
      continue unless shape.fc?
      colors[shape.fc] = true if shapes[key]

    @buttons.find('button').removeClass('selected')
    @buttons.find('button').each (i, button) ->
      $(button).addClass('selected') if colors[$(button).val()]

    @updateMovieClip()

  updateColorGroup: ->
    colors = {}
    @buttons.find('button').each (i, button) ->
      return unless $(button).hasClass('selected')
      colors[$(button).val()] = true

    shapes = []
    for key, shape of @thangType.get('raw')?.shapes or {}
      continue unless shape.fc?
      shapes.push(key) if colors[shape.fc]

    @currentColorGroupTreema.set('/', shapes)
    @updateMovieClip()

class ColorGroupNode extends TreemaNode.nodeMap.array
  collection: false
  canAddChild: -> false
