require('app/styles/editor/level/system/level-system-edit-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/system/level-system-edit-view'
LevelSystem = require 'models/LevelSystem'
SystemVersionsModal = require 'views/editor/level/systems/SystemVersionsModal'
PatchesView = require 'views/editor/PatchesView'
SaveVersionModal = require 'views/editor/modal/SaveVersionModal'
require 'lib/setupTreema'
ace = require('lib/aceContainer')

module.exports = class LevelSystemEditView extends CocoView
  id: 'level-system-edit-view'
  template: template
  editableSettings: ['name', 'description', 'codeLanguage', 'dependencies', 'propertyDocumentation', 'i18n']

  events:
    'click #done-editing-system-button': 'endEditing'
    'click .nav a': (e) -> $(e.target).tab('show')
    'click #system-patches-tab': -> @patchesView.load()
    'click #system-code-tab': 'buildCodeEditor'
    'click #system-config-schema-tab': 'buildConfigSchemaTreema'
    'click #system-settings-tab': 'buildSettingsTreema'
    'click #system-history-button': 'showVersionHistory'
    'click #patch-system-button': 'startPatchingSystem'
    'click #system-watch-button': 'toggleWatchSystem'

  constructor: (options) ->
    super options
    @levelSystem = @supermodel.getModelByOriginalAndMajorVersion LevelSystem, options.original, options.majorVersion or 0
    console.log 'Couldn\'t get levelSystem for', options, 'from', @supermodel.models unless @levelSystem

  afterRender: ->
    super()
    @buildSettingsTreema()
    @buildConfigSchemaTreema()
    @buildCodeEditor()
    @patchesView = @insertSubView(new PatchesView(@levelSystem), @$el.find('.patches-view'))
    @updatePatchButton()

  buildSettingsTreema: ->
    data = _.pick @levelSystem.attributes, (value, key) => key in @editableSettings
    schema = _.cloneDeep LevelSystem.schema
    schema.properties = _.pick schema.properties, (value, key) => key in @editableSettings
    schema.required = _.intersection schema.required, @editableSettings
    schema.default = _.pick schema.default, (value, key) => key in @editableSettings

    treemaOptions =
      supermodel: @supermodel
      schema: schema
      data: data
      callbacks: {change: @onSystemSettingsEdited}
    treemaOptions.readOnly = me.get('anonymous')
    @systemSettingsTreema = @$el.find('#edit-system-treema').treema treemaOptions
    @systemSettingsTreema.build()
    @systemSettingsTreema.open()

  onSystemSettingsEdited: =>
    # Make sure it validates first?
    for key, value of @systemSettingsTreema.data
      @levelSystem.set key, value unless key is 'js' # will compile code if needed
    @updatePatchButton()

  buildConfigSchemaTreema: ->
    treemaOptions =
      supermodel: @supermodel
      schema: LevelSystem.schema.properties.configSchema
      data: $.extend true, {}, @levelSystem.get 'configSchema'
      callbacks: {change: @onConfigSchemaEdited}
    treemaOptions.readOnly = me.get('anonymous')
    @configSchemaTreema = @$el.find('#config-schema-treema').treema treemaOptions
    @configSchemaTreema.build()
    @configSchemaTreema.open()
    # TODO: schema is not loaded for the first one here?
    @configSchemaTreema.tv4.addSchema('metaschema', LevelSystem.schema.properties.configSchema)

  onConfigSchemaEdited: =>
    @levelSystem.set 'configSchema', @configSchemaTreema.data
    @updatePatchButton()

  buildCodeEditor: ->
    @destroyAceEditor(@editor)
    editorEl = $('<div></div>').text(@levelSystem.get('code')).addClass('inner-editor')
    @$el.find('#system-code-editor').empty().append(editorEl)
    @editor = ace.edit(editorEl[0])
    @editor.setReadOnly(me.get('anonymous'))
    session = @editor.getSession()
    session.setMode 'ace/mode/coffee'
    session.setTabSize 2
    session.setNewLineMode = 'unix'
    session.setUseSoftTabs true
    @editor.on('change', @onEditorChange)

  onEditorChange: =>
    @levelSystem.set 'code', @editor.getValue()
    @updatePatchButton()

  updatePatchButton: ->
    @$el.find('#patch-system-button').toggle Boolean @levelSystem.hasLocalChanges()

  endEditing: (e) ->
    Backbone.Mediator.publish 'editor:level-system-editing-ended', system: @levelSystem
    null

  showVersionHistory: (e) ->
    systemVersionsModal = new SystemVersionsModal {}, @levelSystem.id
    @openModalView systemVersionsModal
    Backbone.Mediator.publish 'editor:view-switched', {}

  startPatchingSystem: (e) ->
    @openModalView new SaveVersionModal({model: @levelSystem})
    Backbone.Mediator.publish 'editor:view-switched', {}

  toggleWatchSystem: ->
    console.log 'toggle watch system?'
    button = @$el.find('#system-watch-button')
    @levelSystem.watch(button.find('.watch').is(':visible'))
    button.find('> span').toggleClass('secret')

  destroy: ->
    @destroyAceEditor(@editor)
    @systemSettingsTreema?.destroy()
    @configSchemaTreema?.destroy()
    super()
