CocoView = require 'views/kinds/CocoView'
template = require 'templates/editor/thang/colors_tab'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
{hexToHSL} = require 'lib/utils' 

module.exports = class ColorsTabView extends CocoView
  id: 'editor-thang-colors-tab-view'
  template: template
  className: 'tab-pane'
  
  offset: 0
  
  constructor: (@thangType, options) ->
    @thangType.once 'sync', @tryToBuild, @
    @thangType.schema().once 'sync', @tryToBuild, @
    @colorConfig = { hue: 0, saturation: 0, lightness: 0 }
    @spriteBuilder = new SpriteBuilder(@thangType)
    f = => 
      @offset++
      @updateMovieClip()
    @interval = setInterval f, 1000
    super options

  afterRender: ->
    super()
    @createShapeButtons()
    @initStage()
    @initSliders()
    @tryToBuild()
    
  # sliders

  initSliders: ->
    @hueSlider = @initSlider $("#hue-slider", @$el), 0, @updateHue
    @saturationSlider = @initSlider $("#saturation-slider", @$el), 50, @updateSaturation
    @lightnessSlider = @initSlider $("#lightness-slider", @$el), 50, @updateLightness
    
  updateHue: =>
    @colorConfig.hue = @hueSlider.slider('value') / 100
    @updateMovieClip()
    
  updateSaturation: =>
    @colorConfig.saturation = (@saturationSlider.slider('value') / 50) - 1
    @updateMovieClip()

  updateLightness: =>
    @colorConfig.lightness = (@lightnessSlider.slider('value') / 50) - 1
    @updateMovieClip()
    
  # movie clip
  
  initStage: ->
    canvas = @$el.find('#tinting-display')
    @stage = new createjs.Stage(canvas[0])
    createjs.Ticker.setFPS 20
    createjs.Ticker.addEventListener("tick", @stage)
    @updateMovieClip()

  updateMovieClip: ->
    return unless @currentColorGroupTreema
    actionDict = @thangType.getActions()
    animations = (a.animation for key, a of actionDict when a.animation)
    index = @offset % animations.length
    animation = animations[index]
    return unless animation
    @stage.removeChild(@movieClip) if @movieClip
    options = {colorConfig: {}}
    options.colorConfig[@currentColorGroupTreema.keyForParent] = @colorConfig
    @spriteBuilder.setOptions options
    @spriteBuilder.buildColorMaps()
    @movieClip = @spriteBuilder.buildMovieClip animation
    larger = Math.min(400 / @movieClip.nominalBounds.width, 400 / @movieClip.nominalBounds.height)
    @movieClip.scaleX = larger
    @movieClip.scaleY = larger
    @movieClip.regX = @movieClip.nominalBounds.x
    @movieClip.regY = @movieClip.nominalBounds.y
    @stage.addChild @movieClip

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
    return unless @thangType.loaded and @thangType.schema().loaded
    data = @thangType.get('colorGroups')
    data ?= {}
    schema = @thangType.schema().attributes.properties?.colorGroups
    treemaOptions =
      data: data
      schema: schema
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

  onColorGroupSelected: (e, selected) =>
    @$el.find('#color-group-settings').toggleClass('hide', not selected.length)
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
      window.button = button
      colors[$(button).val()] = true
    
    shapes = []
    for key, shape of @thangType.get('raw')?.shapes or {}
      continue unless shape.fc?
      shapes.push(key) if colors[shape.fc]

    @currentColorGroupTreema.set('/', shapes)

class ColorGroupNode extends TreemaNode.nodeMap.array
  collection: false
  canAddChild: -> false
