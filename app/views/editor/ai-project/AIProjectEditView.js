require('app/styles/editor/ai-project/edit.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/editor/ai-project/edit'
AIProject = require 'models/AIProject'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'

nodes = require 'views/editor/level/treema_nodes'

require 'lib/game-libraries'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'

module.exports = class AIProjectEditView extends RootView
  id: 'editor-ai-project-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'
    'click #delete-button': 'confirmDeletion'

  constructor: (options, @projectID) ->
    super options
    @project = new AIProject(_id: @projectID)
    @project.saveBackups = true
    @supermodel.loadModel @project

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @project, 'change', =>
      @treema.set('/', @project.attributes)

  buildTreema: ->
    return if @treema? or (not @project.loaded)
    data = $.extend(true, {}, @project.attributes)
    options =
      data: data
      filePath: "db/ai_project/#{@project.get('_id')}"
      schema: AIProject.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
      nodeClasses:
        'chat-message-link': nodes.ChatMessageLinkNode
    @treema = @$el.find('#ai-project-treema').treema(options)
    @treema.build()
    @treema.open(2)

  afterRender: ->
    super()
    return unless @supermodel.finished()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @project.set(key, value)

    res = @project.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/ai-project/#{@project.get('slug') or @project.id}"
      document.location.href = url

  confirmDeletion: ->
    renderData =
      title: 'Are you really sure?'
      body: 'This will completely delete the project.'
      decline: 'Not really'
      confirm: 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @deleteAIProject
    @openModalView confirmModal

  deleteAIProject: =>
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 5000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
        _.delay ->
          application.router.navigate '/editor/ai-project', trigger: true
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting project message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_project/#{@project.id}"
