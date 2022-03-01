require('ozaria/site/styles/play/menu/options-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/play/menu/options-view'
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
    'click .done-button': 'onDoneClicked'

  constructor: (options) ->
    super options

  getRenderData: (c={}) ->
    c = super(c)
    @aceConfig = _.cloneDeep me.get('aceConfig') ? {}
    @aceConfig = _.defaults @aceConfig, @defaultConfig
    c.aceConfig = @aceConfig
    c

  onDoneClicked: ->
    @aceConfig.behaviors = @$el.find('#option-behaviors').prop('checked')
    @aceConfig.liveCompletion = @$el.find('#option-live-completion').prop('checked')
    me.set 'aceConfig', @aceConfig
    me.patch()
    Backbone.Mediator.publish 'tome:change-config', {}
