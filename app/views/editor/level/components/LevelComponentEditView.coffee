require('app/styles/editor/level/component/level-component-edit-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/component/level-component-edit-view'
LevelComponent = require 'models/LevelComponent'
ComponentVersionsModal = require 'views/editor/component/ComponentVersionsModal'
PatchesView = require 'views/editor/PatchesView'
SaveVersionModal = require 'views/editor/modal/SaveVersionModal'
ace = require('lib/aceContainer')

require 'lib/setupTreema'

module.exports = class LevelComponentEditView extends CocoView
  id: 'level-component-edit-view'
  template: template
  editableSettings: ['name', 'description', 'system', 'codeLanguage', 'dependencies', 'propertyDocumentation', 'i18n', 'context']

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
    'click #pop-component-i18n-button': 'onPopulateI18N'

  constructor: (options) ->
    super options
    @levelComponent = @supermodel.getModelByOriginalAndMajorVersion LevelComponent, options.original, options.majorVersion or 0
    console.log 'Couldn\'t get levelComponent for', options, 'from', @supermodel.models unless @levelComponent
    @onEditorChange = _.debounce @onEditorChange, 1000

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
    @updatePatchButton()

  buildSettingsTreema: ->
    data = _.pick @levelComponent.attributes, (value, key) => key in @editableSettings
    data = $.extend(true, {}, data)
    schema = _.cloneDeep LevelComponent.schema
    schema.properties = _.pick schema.properties, (value, key) => key in @editableSettings
    schema.required = _.intersection schema.required, @editableSettings
    schema.default = _.pick schema.default, (value, key) => key in @editableSettings

    treemaOptions =
      supermodel: @supermodel
      schema: schema
      data: data
      readonly: me.get('anonymous')
      callbacks: {change: @onComponentSettingsEdited}
    @componentSettingsTreema = @$el.find('#edit-component-treema').treema treemaOptions
    @componentSettingsTreema.build()
    @componentSettingsTreema.open()

  onComponentSettingsEdited: =>
    # Make sure it validates first?
    for key, value of @componentSettingsTreema.data
      @levelComponent.set key, value unless key is 'js' # will compile code if needed
    @updatePatchButton()

  buildConfigSchemaTreema: ->
    configSchema = $.extend true, {}, @levelComponent.get 'configSchema'
    if configSchema.properties
      # Alphabetize (#1297)
      propertyNames = _.keys configSchema.properties
      propertyNames.sort()
      orderedProperties = {}
      for prop in propertyNames
        orderedProperties[prop] = configSchema.properties[prop]
      configSchema.properties = orderedProperties
    treemaOptions =
      supermodel: @supermodel
      schema: LevelComponent.schema.properties.configSchema
      data: configSchema
      readOnly: me.get('anonymous')
      callbacks: {change: @onConfigSchemaEdited}
    @configSchemaTreema = @$el.find('#config-schema-treema').treema treemaOptions
    @configSchemaTreema.build()
    @configSchemaTreema.open()
    # TODO: schema is not loaded for the first one here?
    @configSchemaTreema.tv4.addSchema('metaschema', LevelComponent.schema.properties.configSchema)

  onConfigSchemaEdited: =>
    @levelComponent.set 'configSchema', @configSchemaTreema.data
    @updatePatchButton()

  buildCodeEditor: ->
    @destroyAceEditor(@editor)
    editorEl = $('<div></div>').text(@levelComponent.get('code')).addClass('inner-editor')
    @$el.find('#component-code-editor').empty().append(editorEl)
    @editor = ace.edit(editorEl[0])
    @editor.setReadOnly(me.get('anonymous'))
    session = @editor.getSession()
    session.setMode 'ace/mode/coffee'
    session.setTabSize 2
    session.setNewLineMode = 'unix'
    session.setUseSoftTabs true
    @editor.on('change', @onEditorChange)

  onEditorChange: =>
    return if @destroyed
    @levelComponent.set 'code', @editor.getValue()
    @updatePatchButton()

  updatePatchButton: ->
    @$el.find('#patch-component-button').toggle Boolean @levelComponent.hasLocalChanges()

  endEditing: (e) ->
    Backbone.Mediator.publish 'editor:level-component-editing-ended', component: @levelComponent
    null

  showVersionHistory: (e) ->
    componentVersionsModal = new ComponentVersionsModal {}, @levelComponent.id
    @openModalView componentVersionsModal
    Backbone.Mediator.publish 'editor:view-switched', {}

  startPatchingComponent: (e) ->
    @openModalView new SaveVersionModal({model: @levelComponent})
    Backbone.Mediator.publish 'editor:view-switched', {}

  toggleWatchComponent: ->
    button = @$el.find('#component-watch-button')
    @levelComponent.watch(button.find('.watch').is(':visible'))
    button.find('> span').toggleClass('secret')

  onPopulateI18N: ->
    @levelComponent.populateI18N()
    @render()

  destroy: ->
    @destroyAceEditor(@editor)
    @componentSettingsTreema?.destroy()
    @configSchemaTreema?.destroy()
    super()
