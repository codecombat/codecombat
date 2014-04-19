View = require 'views/kinds/CocoView'
template = require 'templates/editor/level/system/edit'
LevelSystem = require 'models/LevelSystem'
VersionHistoryView = require 'views/editor/system/versions_view'
PatchesView = require 'views/editor/patches_view'
SaveVersionModal = require 'views/modal/save_version_modal'

module.exports = class LevelSystemEditView extends View
  id: "editor-level-system-edit-view"
  template: template
  editableSettings: ['name', 'description', 'language', 'dependencies', 'propertyDocumentation', 'i18n']

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
    console.log "Couldn't get levelSystem for", options, "from", @supermodel.models unless @levelSystem

  getRenderData: (context={}) ->
    context = super(context)
    context.editTitle = "#{@levelSystem.get('name')}"
    context

  afterRender: ->
    super()
    @buildSettingsTreema()
    @buildConfigSchemaTreema()
    @buildCodeEditor()
    @patchesView = @insertSubView(new PatchesView(@levelSystem), @$el.find('.patches-view'))

  buildSettingsTreema: ->
    data = _.pick @levelSystem.attributes, (value, key) => key in @editableSettings
    schema = _.cloneDeep LevelSystem.schema
    schema.properties = _.pick schema.properties, (value, key) => key in @editableSettings
    schema.required = _.intersection schema.required, @editableSettings

    treemaOptions =
      supermodel: @supermodel
      schema: schema
      data: data
      callbacks: {change: @onSystemSettingsEdited}
    treemaOptions.readOnly = true unless me.isAdmin()
    @systemSettingsTreema = @$el.find('#edit-system-treema').treema treemaOptions
    @systemSettingsTreema.build()
    @systemSettingsTreema.open()

  onSystemSettingsEdited: =>
    # Make sure it validates first?
    for key, value of @systemSettingsTreema.data
      @levelSystem.set key, value unless key is 'js' # will compile code if needed
    Backbone.Mediator.publish 'level-system-edited', levelSystem: @levelSystem
    null

  buildConfigSchemaTreema: ->
    treemaOptions =
      supermodel: @supermodel
      schema: LevelSystem.schema.properties.configSchema
      data: @levelSystem.get 'configSchema'
      callbacks: {change: @onConfigSchemaEdited}
    treemaOptions.readOnly = true unless me.isAdmin()
    @configSchemaTreema = @$el.find('#config-schema-treema').treema treemaOptions
    @configSchemaTreema.build()
    @configSchemaTreema.open()
    # TODO: schema is not loaded for the first one here?
    @configSchemaTreema.tv4.addSchema('metaschema', LevelSystem.schema.properties.configSchema)

  onConfigSchemaEdited: =>
    @levelSystem.set 'configSchema', @configSchemaTreema.data
    Backbone.Mediator.publish 'level-system-edited', levelSystem: @levelSystem

  buildCodeEditor: ->
    @editor?.destroy()
    editorEl = $('<div></div>').text(@levelSystem.get('code')).addClass('inner-editor')
    @$el.find('#system-code-editor').empty().append(editorEl)
    @editor = ace.edit(editorEl[0])
    @editor.setReadOnly(not me.isAdmin())
    session = @editor.getSession()
    session.setMode 'ace/mode/coffee'
    session.setTabSize 2
    session.setNewLineMode = 'unix'
    session.setUseSoftTabs true
    @editor.on('change', @onEditorChange)

  onEditorChange: =>
    @levelSystem.set 'code', @editor.getValue()
    Backbone.Mediator.publish 'level-system-edited', levelSystem: @levelSystem
    null

  endEditing: (e) ->
    Backbone.Mediator.publish 'level-system-editing-ended', levelSystem: @levelSystem
    null

  showVersionHistory: (e) ->
    versionHistoryView = new VersionHistoryView {}, @levelSystem.id
    @openModalView versionHistoryView
    Backbone.Mediator.publish 'level:view-switched', e

  startPatchingSystem: (e) ->
    @openModalView new SaveVersionModal({model:@levelSystem})
    Backbone.Mediator.publish 'level:view-switched', e

  toggleWatchSystem: ->
    console.log 'toggle watch system?'
    button = @$el.find('#system-watch-button')
    @levelSystem.watch(button.find('.watch').is(':visible'))
    button.find('> span').toggleClass('secret')

  destroy: ->
    @editor?.destroy()
    super()
