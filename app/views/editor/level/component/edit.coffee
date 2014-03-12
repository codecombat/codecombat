View = require 'views/kinds/CocoView'
VersionHistoryView = require 'views/editor/component/versions_view'
template = require 'templates/editor/level/component/edit'
LevelComponent = require 'models/LevelComponent'

module.exports = class LevelComponentEditView extends View
  id: "editor-level-component-edit-view"
  template: template
  editableSettings: ['name', 'description', 'system', 'language', 'dependencies', 'propertyDocumentation', 'i18n']

  events:
    'click #done-editing-component-button': 'endEditing'
    'click #history-button': 'showVersionHistory'
    'click .nav a': (e) -> $(e.target).tab('show')

  constructor: (options) ->
    super options
    @levelComponent = @supermodel.getModelByOriginalAndMajorVersion LevelComponent, options.original, options.majorVersion or 0
    console.log "Couldn't get levelComponent for", options, "from", @supermodel.models unless @levelComponent

  getRenderData: (context={}) ->
    context = super(context)
    context.editTitle = "#{@levelComponent.get('system')}.#{@levelComponent.get('name')}"
    context

  afterRender: ->
    super()
    @buildSettingsTreema()
    @buildConfigSchemaTreema()
    @buildCodeEditor()

  buildSettingsTreema: ->
    data = _.pick @levelComponent.attributes, (value, key) => key in @editableSettings
    schema = _.cloneDeep LevelComponent.schema.attributes
    schema.properties = _.pick schema.properties, (value, key) => key in @editableSettings
    schema.required = _.intersection schema.required, @editableSettings

    treemaOptions =
      supermodel: @supermodel
      schema: schema
      data: data
      callbacks: {change: @onComponentSettingsEdited}
    treemaOptions.readOnly = true unless me.isAdmin()
    @componentSettingsTreema = @$el.find('#edit-component-treema').treema treemaOptions
    @componentSettingsTreema.build()
    @componentSettingsTreema.open()

  onComponentSettingsEdited: =>
    # Make sure it validates first?
    for key, value of @componentSettingsTreema.data
      @levelComponent.set key, value unless key is 'js' # will compile code if needed
    Backbone.Mediator.publish 'level-component-edited', levelComponent: @levelComponent
    null

  buildConfigSchemaTreema: ->
    treemaOptions =
      supermodel: @supermodel
      schema: LevelComponent.schema.get('properties').configSchema
      data: @levelComponent.get 'configSchema'
      callbacks: {change: @onConfigSchemaEdited}
    treemaOptions.readOnly = true unless me.isAdmin()
    @configSchemaTreema = @$el.find('#config-schema-treema').treema treemaOptions
    @configSchemaTreema.build()
    @configSchemaTreema.open()
    # TODO: schema is not loaded for the first one here?
    @configSchemaTreema.tv4.addSchema('metaschema', LevelComponent.schema.get('properties').configSchema)

  onConfigSchemaEdited: =>
    @levelComponent.set 'configSchema', @configSchemaTreema.data
    Backbone.Mediator.publish 'level-component-edited', levelComponent: @levelComponent

  buildCodeEditor: ->
    editorEl = @$el.find '#component-code-editor'
    editorEl.text @levelComponent.get('code')
    @editor = ace.edit(editorEl[0])
    @editor.setReadOnly(not me.isAdmin())
    session = @editor.getSession()
    session.setMode 'ace/mode/coffee'
    session.setTabSize 2
    session.setNewLineMode = 'unix'
    session.setUseSoftTabs true
    @editor.on 'change', @onEditorChange
    
  onEditorChange: =>
    @levelComponent.set 'code', @editor.getValue()
    Backbone.Mediator.publish 'level-component-edited', levelComponent: @levelComponent
    null

  endEditing: (e) ->
    Backbone.Mediator.publish 'level-component-editing-ended', levelComponent: @levelComponent
    null

  destroy: ->
    @editor?.destroy()
    super()

  showVersionHistory: (e) ->
    console.debug @levelComponent
    versionHistoryView = new VersionHistoryView component:@levelComponent, @levelComponent.id
    @openModalView versionHistoryView
    Backbone.Mediator.publish 'level:view-switched', e