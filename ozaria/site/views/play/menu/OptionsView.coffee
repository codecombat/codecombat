require('ozaria/site/styles/play/menu/options-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/play/menu/options-view'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'
User = require 'models/User'
forms = require 'core/forms'
store = require 'core/store'

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
    screenReaderMode: false

  events:
    'click .done-button': 'onDoneClicked'
    'change #option-music': 'updateMusic'

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

  onDoneClicked: ->
    @aceConfig.behaviors = @$el.find('#option-behaviors').prop('checked')
    @aceConfig.liveCompletion = @$el.find('#option-live-completion').prop('checked')
    @aceConfig.screenReaderMode = @$el.find('#option-screen-reader-mode').prop('checked')
    $('body').toggleClass('screen-reader-mode', @aceConfig.screenReaderMode)
    me.set 'aceConfig', @aceConfig
    me.set 'music', @$el.find('#option-music').prop('checked')
    me.patch()
    Backbone.Mediator.publish 'tome:change-config', {}

  updateMusic: ->
    musicEnabled = Boolean @$el.find('#option-music').prop('checked')
    return if me.get('music', true) is musicEnabled
    me.set 'music', musicEnabled
    command = {true: 'audio/unmuteTrack', false: 'audio/muteTrack'}[musicEnabled]
    store.dispatch(command, 'background')
