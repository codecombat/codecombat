View = require 'views/kinds/CocoView'
template = require 'templates/editor/level/component/edit'
LevelComponent = require 'models/LevelComponent'

module.exports = class LevelComponentEditView extends View
  id: "editor-level-component-edit-view"
  template: template

  events:
    'click #done-editing-component-button': 'endEditing'

  constructor: (options) ->
    super options
    @levelComponent = @supermodel.getModelByOriginalAndMajorVersion LevelComponent, options.original, options.majorVersion or 0
    console.log "Couldn't get levelComponent for", options, "from", @supermodel.models unless @levelComponent

  getRenderData: (context={}) =>
    context = super(context)
    context.editTitle = "Edit Component: #{@levelComponent.get('system')}.#{@levelComponent.get('name')}"
    context

  afterRender: ->
    super()
    @buildTreema()

  buildTreema: ->
    data = $.extend(true, {}, @levelComponent.attributes)
    treemaOptions =
      supermodel: @supermodel
      schema: LevelComponent.schema.attributes
      data: data
      callbacks: {change: @onComponentEdited}
    unless me.isAdmin()
      treemaOptions.readOnly = true
    @componentTreema = @$el.find('#edit-component-treema').treema treemaOptions
    @componentTreema.build()
    @componentTreema.open()
    # TODO: schema is not loaded for the first one here?
    @componentTreema.tv4.addSchema('metaschema', LevelComponent.schema.get('properties').configSchema)

  onComponentEdited: (e) =>
    # Make sure it validates first?
    for key, value of @componentTreema.data
      @levelComponent.set key, value unless key is 'js' # will compile code if needed
    Backbone.Mediator.publish 'level-component-edited', levelComponent: @levelComponent
    null

  endEditing: (e) ->
    Backbone.Mediator.publish 'level-component-editing-ended', levelComponent: @levelComponent
    null
