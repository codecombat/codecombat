View = require 'views/kinds/CocoView'
template = require 'templates/editor/level/component/edit'
LevelComponent = require 'models/LevelComponent'
VersionHistoryView = require 'views/editor/component/versions_view'
PatchesView = require 'views/editor/patches_view'
SaveVersionModal = require 'views/modal/save_version_modal'

module.exports = class LevelComponentEditView extends View
  id: "editor-level-component-edit-view"
  template: template
  editableSettings: ['name', 'description', 'system', 'language', 'dependencies', 'propertyDocumentation', 'i18n']

  events:
    'click #done-editing-component-button': 'endEditing'
    'click .nav a': (e) -> $(e.target).tab('show')
    'click #component-patches-tab': -> @patchesView.load()
    'click #component-code-tab': 'buildCodeEditor'
    'click #component-config-schema-tab': 'buildConfigSchemaTreema'
    'click #component-settings-tab': 'buildSettingsTreema'
    'click #component-history-button': 'showVersionHistory'
    'click #patch-component-button': 'startPatchingComponent'
    'click #component-watch-button': 'toggleWatchComponent'

  constructor: (options) ->
    super options
    @levelComponent = @supermodel.getModelByOriginalAndMajorVersion LevelComponent, options.original, options.majorVersion or 0
    console.log "Couldn't get levelComponent for", options, "from", @supermodel.models unless @levelComponent

  getRenderData: (context={}) ->
    context = super(context)
    context.editTitle = "#{@levelComponent.get('system')}.#{@levelComponent.get('name')}"
    context.component = @levelComponent
    context

  onLoaded: -> @render()
  afterRender: ->
    super()
    @buildSettingsTreema()
    @buildConfigSchemaTreema()
    @buildCodeEditor()
    @patchesView = @insertSubView(new PatchesView(@levelComponent), @$el.find('.patches-view'))
    @$el.find('#component-watch-button').find('> span').toggleClass('secret') if @levelComponent.watching()

  buildSettingsTreema: ->
    data = _.pick @levelComponent.attributes, (value, key) => key in @editableSettings
    schema = _.cloneDeep LevelComponent.schema
    schema.properties = _.pick schema.properties, (value, key) => key in @editableSettings
    schema.required = _.intersection schema.required, @editableSettings
    
    treemaOptions =
      supermodel: @supermodel
      schema: schema
      data: data
      callbacks: {change: @onComponentSettingsEdited}
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
      schema: LevelComponent.schema.properties.configSchema
      data: @levelComponent.get 'configSchema'
      callbacks: {change: @onConfigSchemaEdited}
    @configSchemaTreema = @$el.find('#config-schema-treema').treema treemaOptions
    @configSchemaTreema.build()
    @configSchemaTreema.open()
    # TODO: schema is not loaded for the first one here?
    @configSchemaTreema.tv4.addSchema('metaschema', LevelComponent.schema.properties.configSchema)

  onConfigSchemaEdited: =>
    @levelComponent.set 'configSchema', @configSchemaTreema.data
    Backbone.Mediator.publish 'level-component-edited', levelComponent: @levelComponent

  buildCodeEditor: ->
    @editor?.destroy()
    editorEl = $('<div></div>').text(@levelComponent.get('code')).addClass('inner-editor')
    @$el.find('#component-code-editor').empty().append(editorEl)
    @editor = ace.edit(editorEl[0])
    session = @editor.getSession()
    session.setMode 'ace/mode/coffee'
    session.setTabSize 2
    session.setNewLineMode = 'unix'
    session.setUseSoftTabs true
    @editor.on('change', @onEditorChange)
    
  onEditorChange: =>
    @levelComponent.set 'code', @editor.getValue()
    Backbone.Mediator.publish 'level-component-edited', levelComponent: @levelComponent
    null

  endEditing: (e) ->
    Backbone.Mediator.publish 'level-component-editing-ended', levelComponent: @levelComponent
    null

  showVersionHistory: (e) ->
    versionHistoryView = new VersionHistoryView {}, @levelComponent.id
    @openModalView versionHistoryView
    Backbone.Mediator.publish 'level:view-switched', e
    
  startPatchingComponent: (e) ->
    @openModalView new SaveVersionModal({model:@levelComponent})
    Backbone.Mediator.publish 'level:view-switched', e

  toggleWatchComponent: ->
    button = @$el.find('#component-watch-button')
    @levelComponent.watch(button.find('.watch').is(':visible'))
    button.find('> span').toggleClass('secret')

  destroy: ->
    @editor?.destroy()
    super()

