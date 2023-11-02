require('app/styles/editor/ai-model/edit.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/editor/ai-model/edit'
AIModel = require 'models/AIModel'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'

require 'lib/game-libraries'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'

module.exports = class AIModelEditView extends RootView
  id: 'editor-ai-model-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'
    'click #delete-button': 'confirmDeletion'

  constructor: (options, @modelID) ->
    super options
    @model = new AIModel(_id: @modelID)
    @model.saveBackups = true
    @supermodel.loadModel @model

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @model, 'change', =>
      @treema.set('/', @model.attributes)

  buildTreema: ->
    return if @treema? or (not @model.loaded)
    data = $.extend(true, {}, @model.attributes)
    options =
      data: data
      filePath: "db/ai_model/#{@model.get('_id')}"
      schema: AIModel.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
    @treema = @$el.find('#ai-model-treema').treema(options)
    @treema.build()
    @treema.open(2)

  afterRender: ->
    super()
    return unless @supermodel.finished()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @model.set(key, value)

    res = @model.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/ai-model/#{@model.get('slug') or @model.id}"
      document.location.href = url

  confirmDeletion: ->
    renderData =
      title: 'Are you really sure?'
      body: 'This will completely delete the model.'
      decline: 'Not really'
      confirm: 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @deleteAIModel
    @openModalView confirmModal

  deleteAIModel: =>
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 5000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
        _.delay ->
          application.router.navigate '/editor/ai-model', trigger: true
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting model message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_model/#{@model.id}"
