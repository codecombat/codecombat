require('app/styles/play/menu/options-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/menu/options-view'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'
User = require 'models/User'
forms = require 'core/forms'

module.exports = class OptionsView extends CocoView
  id: 'options-view'
  className: 'tab-pane'
  template: template
  aceConfig: {}
  defaultConfig:
    language: 'python'
    keyBindings: 'default'
    behaviors: false
    liveCompletion: true

  events:
    'change #option-music': 'updateMusic'
    'change #option-behaviors': 'updateBehaviors'
    'change #option-live-completion': 'updateLiveCompletion'
    'click .profile-photo': 'onEditProfilePhoto'
    'click .editable-icon': 'onEditProfilePhoto'

  constructor: (options) ->
    super options

  getRenderData: (c={}) ->
    c = super(c)
    @aceConfig = _.cloneDeep me.get('aceConfig') ? {}
    @aceConfig = _.defaults @aceConfig, @defaultConfig
    c.aceConfig = @aceConfig
    c.music = me.get('music', true)
    c

  afterRender: ->
    super()
    @volumeSlider = @$el.find('#option-volume').slider(animate: 'fast', min: 0, max: 1, step: 0.05)
    @volumeSlider.slider('value', me.get('volume'))
    @volumeSlider.on('slide', @onVolumeSliderChange)
    @volumeSlider.on('slidechange', @onVolumeSliderChange)

  destroy: ->
    @volumeSlider?.slider?('destroy')
    super()

  onVolumeSliderChange: (e) =>
    volume = @volumeSlider.slider('value')
    me.set 'volume', volume
    @$el.find('#option-volume-value').text (volume * 100).toFixed(0) + '%'
    Backbone.Mediator.publish 'level:set-volume', volume: volume
    @playSound 'menu-button-click'  # Could have another volume-indicating noise

  onHidden: ->
    @aceConfig.keyBindings = 'default'  # We used to give them the option, but we took it away.
    @aceConfig.behaviors = @$el.find('#option-behaviors').prop('checked')
    @aceConfig.liveCompletion = @$el.find('#option-live-completion').prop('checked')
    me.set 'aceConfig', @aceConfig
    me.patch()
    Backbone.Mediator.publish 'tome:change-config', {}

  updateMusic: ->
    me.set 'music', @$el.find('#option-music').prop('checked')

  updateKeyBindings: ->
    @aceConfig.keyBindings = @$el.find('#option-key-bindings').val()

  updateBehaviors: ->
    @aceConfig.behaviors = @$el.find('#option-behaviors').prop('checked')

  updateLiveCompletion: ->
    @aceConfig.liveCompletion = @$el.find('#option-live-completion').prop('checked')
