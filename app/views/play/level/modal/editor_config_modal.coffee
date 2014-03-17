View = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/editor_config'
{me} = require('lib/auth')

module.exports = class EditorConfigModal extends View
  id: 'level-editor-config-modal'
  template: template
  aceConfig: {}

  defaultConfig:
    language: 'javascript'
    keyBindings: 'default'
    invisibles: false
    indentGuides: false
    behaviors: false

  events:
    'change #tome-invisibles': 'updateInvisibles'
    'change #tome-language': 'updateLanguage'
    'change #tome-key-bindings': 'updateKeyBindings'
    'change #tome-indent-guides': 'updateIndentGuides'
    'change #tome-behaviors': 'updateBehaviors'

  constructor: (options) ->
    super(options)

  getRenderData: ->
    @aceConfig = _.cloneDeep me.get('aceConfig') ? {}
    @aceConfig = _.defaults @aceConfig, @defaultConfig
    c = super()
    c.language = @aceConfig.language
    c.keyBindings = @aceConfig.keyBindings
    c.invisibles = @aceConfig.invisibles
    c.indentGuides = @aceConfig.indentGuides
    c.behaviors = @aceConfig.behaviors
    c

  updateLanguage: ->
    @aceConfig.language = @$el.find('#tome-language').val()

  updateInvisibles: ->
    @aceConfig.invisibles = @$el.find('#tome-invisibles').prop('checked')

  updateKeyBindings: ->
    @aceConfig.keyBindings = @$el.find('#tome-key-bindings').val()

  updateIndentGuides: ->
    @aceConfig.indentGuides = @$el.find('#tome-indent-guides').prop('checked')

  updateBehaviors: ->
    @aceConfig.behaviors = @$el.find('#tome-behaviors').prop('checked')

  afterRender: ->
    super()

  onHidden: ->
    oldLanguage = @aceConfig.language
    @aceConfig.language = @$el.find('#tome-language').val()
    @aceConfig.invisibles = @$el.find('#tome-invisibles').prop('checked')
    @aceConfig.keyBindings = @$el.find('#tome-key-bindings').val()
    @aceConfig.indentGuides = @$el.find('#tome-indent-guides').prop('checked')
    @aceConfig.behaviors = @$el.find('#tome-behaviors').prop('checked')
    me.set 'aceConfig', @aceConfig
    Backbone.Mediator.publish 'tome:change-config'
    Backbone.Mediator.publish 'tome:change-language' unless @aceConfig.language is oldLanguage
    me.save()

  destroy: ->
    super()
