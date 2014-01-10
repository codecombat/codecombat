View = require 'views/kinds/ModalView'
template = require 'templates/modal/wizard_settings'
WizardSprite = require 'lib/surface/WizardSprite'
ThangType = require 'models/ThangType'

module.exports = class WizardSettingsView extends View
  id: "wizard-settings-modal"
  template: template
  closesOnClickOutside: false

  events:
    'change #wizard-settings-name': 'onNameChange'
    'click #random-name': 'onRandomNameClick'
    'click #wizard-settings-done': 'saveSettings'

  render: ->
    me.set('name', @randomName())  if not me.get('name')
    super()

  onRandomNameClick: =>
    $('#wizard-settings-name').val(@randomName())
    @saveSettings()

  randomName: ->
    return NameGenerator.getName(7, 9)

  afterRender: ->
    super()
    @colorSlider = $( "#wizard-settings-color-1", @$el).slider({ animate: "fast" })
    @colorSlider.slider('value', me.get('wizardColor1')*100)
    @colorSlider.on('slide',@onSliderChange)
    @colorSlider.on('slidechange',@onSliderChange)
    @stage = new createjs.Stage($('canvas', @$el)[0])
    @saveChanges = _.debounce(@saveChanges, 1000)

    wizOriginal = "52a00d55cf1818f2be00000b"
    url = "/db/thang_type/#{wizOriginal}/version"
    @wizardType = new ThangType()
    @wizardType.url = -> url
    @wizardType.fetch()
    @wizardType.once 'sync', @initCanvas

  initCanvas: =>
    spriteOptions = thangID: "Config Wizard", resolutionFactor: 3
    @wizardSprite = new WizardSprite @wizardType, spriteOptions
    @wizardSprite.setColorHue(me.get('wizardColor1'))
    @wizardDisplayObject = @wizardSprite.displayObject
    @wizardDisplayObject.x = 10
    @wizardDisplayObject.y = 15
    @wizardDisplayObject.scaleX = @wizardDisplayObject.scaleY = 3.0
    @stage.addChild(@wizardDisplayObject)
    @updateSpriteColor()
    @stage.update()

  onSliderChange: =>
    @updateSpriteColor()
    @saveSettings()

  getColorHue: ->
    @colorSlider.slider('value') / 100

  updateSpriteColor: ->
    colorHue = @getColorHue()
    @wizardSprite.setColorHue(colorHue)
    @stage.update()

  onNameChange: =>
    @saveSettings()

  saveSettings: ->
    me.set('name', $('#wizard-settings-name').val())
    me.set('wizardColor1', @getColorHue())
    @saveChanges()

  saveChanges: ->
    me.save()

  destroy: ->
    super()
    @wizardSprite?.destroy()
