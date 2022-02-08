require('app/styles/editor/resource/edit.sass')
RootView = require 'views/core/RootView'
template = require 'templates/editor/resource/edit'
ResourceHubResource = require 'models/ResourceHubResource'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'

require 'lib/game-libraries'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'

module.exports = class ResourceEditView extends RootView
  id: 'editor-resource-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'
    'click #i18n-button': 'onPopulateI18N'

  constructor: (options, @resourceID) ->
    super options
    @resource = new ResourceHubResource(_id: @resourceID)
    @resource.saveBackups = true
    @supermodel.loadModel @resource

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @resource, 'change', =>
      @resource.updateI18NCoverage()
      @treema.set('/', @resource.attributes)

  buildTreema: ->
    return if @treema? or (not @resource.loaded)
    data = $.extend(true, {}, @resource.attributes)
    options =
      data: data
      filePath: "db/resource_hub_resource/#{@resource.get('_id')}"
      schema: ResourceHubResource.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
    @treema = @$el.find('#resource-treema').treema(options)
    @treema.build()
    @treema.childrenTreemas.rewards?.open(3)

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @showReadOnly() if me.get('anonymous')
    @patchesView = @insertSubView(new PatchesView(@resource), @$el.find('.patches-view'))
    @patchesView.load()

  onPopulateI18N: ->
    @resource.populateI18N()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @resource.set(key, value)
    @resource.updateI18NCoverage()

    res = @resource.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/resource/#{@resource.get('slug') or @resource.id}"
      document.location.href = url
