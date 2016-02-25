CocoView = require 'views/core/CocoView'
template = require 'templates/editor/thang/colors_tab'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
{hexToHSL} = require 'core/utils'
require 'vendor/treema'

module.exports = class ThangTypeColorsTabView extends CocoView
  id: 'editor-thang-colors-tab-view'
  template: template
  className: 'tab-pane'

  offset: 0

  constructor: (@thangType, options) ->
    super options
    @supermodel.loadModel @thangType
    @colorConfig = {hue: 0, saturation: 0.5, lightness: 0.5}
    @spriteBuilder = new SpriteBuilder(@thangType) if @thangType.get('raw')
    f = =>
      @offset++
      @updateMovieClip()
    @interval = setInterval f, 1000

  destroy: ->
    @colorGroups?.destroy()
    clearInterval @interval
    super()

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @createShapeButtons()
    @initStage()
    @initSliders()
    @tryToBuild()

  # sliders

  initSliders: ->
    @hueSlider = @initSlider $('#hue-slider', @$el), 0, @makeSliderCallback 'hue'
    @saturationSlider = @initSlider $('#saturation-slider', @$el), 50, @makeSliderCallback 'saturation'
    @lightnessSlider = @initSlider $('#lightness-slider', @$el), 50, @makeSliderCallback 'lightness'

  makeSliderCallback: (property) ->
    (e, result) =>
      @colorConfig[property] = result.value / 100
      @updateMovieClip()

  # movie clip

  initStage: ->
    canvas = @$el.find('#tinting-display')
    @stage = new createjs.Stage(canvas[0])
    createjs.Ticker.setFPS 20
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
    options = {colorConfig: {}}
    options.colorConfig[@currentColorGroupTreema.keyForParent] = @colorConfig
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
    options.colorConfig[@currentColorGroupTreema.keyForParent] = @colorConfig
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
