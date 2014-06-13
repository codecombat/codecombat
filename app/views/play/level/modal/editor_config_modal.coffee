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
    @session = options.session

  getRenderData: ->
    @aceConfig = _.cloneDeep me.get('aceConfig') ? {}
    @aceConfig = _.defaults @aceConfig, @defaultConfig
    c = super()
    c.languages = [
      {id: 'javascript', name: 'JavaScript'}
      {id: 'coffeescript', name: 'CoffeeScript'}
      {id: 'python', name: 'Python (Experimental)'}
      {id: 'clojure', name: 'Clojure (Experimental)'}
      {id: 'lua', name: 'Lua (Experimental)'}
      {id: 'io', name: 'Io (Experimental)'}
    ]
    c.sessionLanguage = @session.get('codeLanguage') ? @aceConfig.language
    c.language = @aceConfig.language
    c.keyBindings = @aceConfig.keyBindings
    c.invisibles = @aceConfig.invisibles
    c.indentGuides = @aceConfig.indentGuides
    c.behaviors = @aceConfig.behaviors
    c

  updateSessionLanguage: ->
    @session.set 'codeLanguage', @$el.find('#tome-session-language').val()

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
    oldLanguage = @session.get('codeLanguage') ? @aceConfig.language
    newLanguage = @$el.find('#tome-session-language').val()
    @session.set 'codeLanguage', newLanguage
    @aceConfig.language = @$el.find('#tome-language').val()
    @aceConfig.invisibles = @$el.find('#tome-invisibles').prop('checked')
    @aceConfig.keyBindings = @$el.find('#tome-key-bindings').val()
    @aceConfig.indentGuides = @$el.find('#tome-indent-guides').prop('checked')
    @aceConfig.behaviors = @$el.find('#tome-behaviors').prop('checked')
    me.set 'aceConfig', @aceConfig
    Backbone.Mediator.publish 'tome:change-config'
    Backbone.Mediator.publish 'tome:change-language', language: newLanguage unless newLanguage is oldLanguage
    @session.save() unless newLanguage is oldLanguage
    me.patch()

  destroy: ->
    super()
