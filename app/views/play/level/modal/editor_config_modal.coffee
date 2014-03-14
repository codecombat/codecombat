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

  events:
    'click textarea': 'onClickLink'
    'change #invisibles': 'updateInvisiblesSelection'
    'change #keyBindings': 'updateKeyBindingsSelection'
    'change #indentGuides': 'updateIndentGuides'

  constructor: (options) ->
    super(options)

  getRenderData: ->
    @aceConfig = _.cloneDeep me.get('aceConfig') || {}
    @aceConfig = _.defaults @aceConfig, @defaultConfig
    c = super()
    c.keyBindings = @aceConfig.keyBindings
    c.invisibles = @aceConfig.invisibles
    c.indentGuides = @aceConfig.indentGuides
    c

  updateInvisiblesSelection: ->
    @aceConfig.invisibles = @$el.find('#invisibles').prop('checked')

  updateKeyBindingsSelection: ->
    @aceConfig.keyBindings = @$el.find('#keyBindings').val()

  updateIndentGuides: ->
    @aceConfig.indentGuides = @$el.find('#indentGuides').prop('checked')

  afterRender: ->
    super()

  onHidden: ->
    @aceConfig.invisibles = @$el.find('#invisibles').prop('checked')
    @aceConfig.keyBindings = @$el.find('#keyBindings').val()
    @aceConfig.indentGuides = @$el.find('#indentGuides').prop('checked')
    me.set 'aceConfig', @aceConfig
    Backbone.Mediator.publish 'change:editor-config'
    me.save()

  destroy: ->
    super()
