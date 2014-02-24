CocoView = require 'views/kinds/CocoView'
template = require 'templates/account/wizard_settings'
{me} = require('lib/auth')
ThangType = require 'models/ThangType'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'

module.exports = class WizardSettingsView extends CocoView
  id: 'wizard-settings-view'
  template: template
  startsLoading: true

  events:
    'change .color-group-checkbox': (e) ->
      colorGroup = $(e.target).closest('.color-group')
      @updateSliderVisibility(colorGroup)
      @updateColorSettings(colorGroup)

  constructor: ->
    super(arguments...)
    @loadWizard()

  loadWizard: ->
    @wizardThangType = new ThangType()
    @wizardThangType.url = -> '/db/thang_type/wizard'
    @wizardThangType.fetch()
    @wizardThangType.once 'sync', @initCanvas, @

  initCanvas: ->
    @startsLoading = false
    @render()
    @spriteBuilder = new SpriteBuilder(@wizardThangType)
    @initStage()

  getRenderData: ->
    c = super()
    wizardSettings = me.get('wizard')?.colorConfig or {}

    colorGroups = @wizardThangType.get('colorGroups') or {}
    f = (name) -> {
      dasherized: _.string.dasherize(name)
      humanized: _.string.humanize name
      name: name
      exists: wizardSettings[name]
    }
    c.colorGroups = (f(colorName) for colorName in _.keys colorGroups)
    c

  afterRender: ->
    return if @startsLoading
    wizardSettings = me.get('wizard') or {}
    wizardSettings.colorConfig ?= {}

    @$el.find('.selector').each (i, slider) =>
      [groupName, prop] = $(slider).attr('name').split('.')
      value = 100 * (wizardSettings.colorConfig[groupName]?[prop] ? 0.5)
      @initSlider $(slider), value, @onSliderChanged

    @$el.find('.color-group').each (i, colorGroup) =>
      @updateSliderVisibility($(colorGroup))

  updateSliderVisibility: (colorGroup) ->
    enabled = colorGroup.find('.color-group-checkbox').prop('checked')
    colorGroup.find('.sliders').toggle Boolean(enabled)

  updateColorSettings: (colorGroup) ->
    wizardSettings = me.get('wizard') or {}
    wizardSettings.colorConfig ?= {}
    colorName = colorGroup.data('name')
    wizardSettings.colorConfig[colorName] ?= {}
    if colorGroup.find('.color-group-checkbox').prop('checked')
      config = {}
      colorGroup.find('.selector').each (i, slider) ->
        config[$(slider).data('key')] = $(slider).slider('value') / 100
      wizardSettings.colorConfig[colorName] = config
    else
      delete wizardSettings.colorConfig[colorName]

    me.set('wizard', wizardSettings)
    @updateMovieClip()
    @trigger 'change'

  onSliderChanged: (e, result) =>
    @updateColorSettings $(result.handle).closest('.color-group')

  initStage: ->
    @stage = new createjs.Stage(@$el.find('canvas')[0])
    @updateMovieClip()

  updateMovieClip: ->
    return unless @wizardThangType.loaded
    wizardSettings = me.get('wizard') or {}
    wizardSettings.colorConfig ?= {}

    @stage.removeChild(@movieClip) if @movieClip
    options = {colorConfig: wizardSettings.colorConfig}
    @spriteBuilder.setOptions options
    @spriteBuilder.buildColorMaps()
    castAction = @wizardThangType.get('actions')?.cast
    return unless castAction?.animation
    @movieClip = @spriteBuilder.buildMovieClip castAction.animation
    @movieClip.scaleY = @movieClip.scaleX = 1.7 * (castAction.scale or 1)
    reg = castAction.positions?.registration
    if reg
      @movieClip.regX = reg.x
      @movieClip.regY = reg.y
    @stage.addChild @movieClip
    @stage.update()