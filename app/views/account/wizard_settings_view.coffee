CocoView = require 'views/kinds/CocoView'
template = require 'templates/account/wizard_settings'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
SpriteBuilder = require 'lib/sprites/SpriteBuilder'
{hslToHex, hexToHSL} = require 'lib/utils'

module.exports = class WizardSettingsView extends CocoView
  id: 'wizard-settings-view'
  template: template
  startsLoading: true

  events:
    'change .color-group-checkbox': (e) ->
      colorGroup = $(e.target).closest('.color-group')
      @updateColorSettings(colorGroup)
      @updateSwatchVisibility(colorGroup)

  constructor: ->
    super(arguments...)
    @loadWizard()

  loadWizard: ->
    @wizardThangType = new ThangType()
    @wizardThangType.url = -> '/db/thang.type/wizard'
    @wizardThangType.fetch()
    @listenToOnce(@wizardThangType, 'sync', @initCanvas)

  initCanvas: ->
    @startsLoading = false
    @render()
    @spriteBuilder = new SpriteBuilder(@wizardThangType)
    @initStage()

  getRenderData: ->
    c = super()
    wizardSettings = me.get('wizard')?.colorConfig or {}

    colorGroups = @wizardThangType.get('colorGroups') or {}
    f = (name) ->
      hslObj = wizardSettings[name]
      hsl = if hslObj then [hslObj.hue, hslObj.saturation, hslObj.lightness] else [0, 0.5, 0.5]
      return {
        dasherized: _.string.dasherize(name)
        humanized: _.string.humanize name
        name: name
        exists: wizardSettings[name]
        rgb: hslToHex(hsl)
      }
    c.colorGroups = (f(colorName) for colorName in _.keys colorGroups)
    c

  afterRender: ->
    return if @startsLoading
    wizardSettings = me.get('wizard') or {}
    wizardSettings.colorConfig ?= {}

    @$el.find('.minicolors').each (e, minicolor) =>
      $(minicolor).minicolors({
        change: => @updateColorSettings($(minicolor).closest('.color-group'))
        changeDelay: 200
      })

    @$el.find('.color-group').each (i, colorGroup) =>
      @updateSwatchVisibility($(colorGroup))

  updateSwatchVisibility: (colorGroup) ->
    enabled = colorGroup.find('.color-group-checkbox').prop('checked')
    colorGroup.find('.minicolors-swatch').toggle Boolean(enabled)

  updateColorSettings: (colorGroup) =>
    wizardSettings = $.extend(true, {}, me.get('wizard')) or {}
    wizardSettings.colorConfig ?= {}
    colorName = colorGroup.data('name')
    wizardSettings.colorConfig[colorName] ?= {}
    if colorGroup.find('.color-group-checkbox').prop('checked')
      input = colorGroup.find('.minicolors-input')
      hex = input.val()
      hsl = hexToHSL(hex)
      config = {hue: hsl[0], saturation: hsl[1], lightness: hsl[2]}
      wizardSettings.colorConfig[colorName] = config
    else
      delete wizardSettings.colorConfig[colorName]

    me.set('wizard', wizardSettings)
    @updateMovieClip()
    @trigger 'change'

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
