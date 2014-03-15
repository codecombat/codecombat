View = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/editor_config'
{me} = require('lib/auth')

module.exports = class EditorConfigModal extends View
  id: 'level-editor-config-modal'
  template: template
  aceConfig: {}

  defaultConfig:
    keyBindings: 'default'
    invisibles: false
    indentGuides: false
    behaviors: false

  events:
    'change #tome-invisibles': 'updateInvisiblesSelection'
    'change #tome-key-bindings': 'updateKeyBindingsSelection'
    'change #tome-indent-guides': 'updateIndentGuides'
    'change #tome-behaviors': 'updateBehaviors'

  constructor: (options) ->
    super(options)

  getRenderData: ->
    @aceConfig = _.cloneDeep me.get('aceConfig') ? {}
    @aceConfig = _.defaults @aceConfig, @defaultConfig
    c = super()
    c.keyBindings = @aceConfig.keyBindings
    c.invisibles = @aceConfig.invisibles
    c.indentGuides = @aceConfig.indentGuides
    c.behaviors = @aceConfig.behaviors
    c

  updateInvisiblesSelection: ->
    @aceConfig.invisibles = @$el.find('#tome-invisibles').prop('checked')

  updateKeyBindingsSelection: ->
    @aceConfig.keyBindings = @$el.find('#tome-key-bindings').val()

  updateIndentGuides: ->
    @aceConfig.indentGuides = @$el.find('#tome-indent-guides').prop('checked')

  updateBehaviors: ->
    @aceConfig.behaviors = @$el.find('#tome-behaviors').prop('checked')

  afterRender: ->
    super()

  onHidden: ->
    @aceConfig.invisibles = @$el.find('#tome-invisibles').prop('checked')
    @aceConfig.keyBindings = @$el.find('#tome-key-bindings').val()
    @aceConfig.indentGuides = @$el.find('#tome-indent-guides').prop('checked')
    @aceConfig.behaviors = @$el.find('#tome-behaviors').prop('checked')
    me.set 'aceConfig', @aceConfig
    Backbone.Mediator.publish 'change:editor-config'
    me.save()

  destroy: ->
    super()
