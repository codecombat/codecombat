View = require 'views/kinds/CocoView'
template = require 'templates/editor/level/system/edit'
LevelSystem = require 'models/LevelSystem'

module.exports = class LevelSystemEditView extends View
  id: "editor-level-system-edit-view"
  template: template

  events:
    'click #done-editing-system-button': 'endEditing'

  constructor: (options) ->
    super options
    @levelSystem = @supermodel.getModelByOriginalAndMajorVersion LevelSystem, options.original, options.majorVersion or 0
    console.log "Couldn't get levelSystem for", options, "from", @supermodel.models unless @levelSystem

  getRenderData: (context={}) =>
    context = super(context)
    context.editTitle = "Edit System: #{@levelSystem.get('name')}"
    context

  afterRender: ->
    super()
    @buildTreema()

  buildTreema: ->
    data = $.extend(true, {}, @levelSystem.attributes)
    treemaOptions =
      supermodel: @supermodel
      schema: LevelSystem.schema.attributes
      data: data
      callbacks: {change: @onSystemEdited}
    unless me.isAdmin()
      treemaOptions.readOnly = true
    @systemTreema = @$el.find('#edit-system-treema').treema treemaOptions
    @systemTreema.build()
    @systemTreema.open()
    # TODO: schema is not loaded for the first one here?
    @systemTreema.tv4.addSchema('metaschema', LevelSystem.schema.get('properties').configSchema)

  onSystemEdited: (e) =>
    # Make sure it validates first?
    for key, value of @systemTreema.data
      @levelSystem.set key, value unless key is 'js' # will compile code if needed
    Backbone.Mediator.publish 'level-system-edited', levelSystem: @levelSystem
    null

  endEditing: (e) ->
    Backbone.Mediator.publish 'level-system-editing-ended', levelSystem: @levelSystem
    null
