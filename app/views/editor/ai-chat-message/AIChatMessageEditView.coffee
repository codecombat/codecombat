require('app/styles/editor/ai-chat-message/edit.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/editor/ai-chat-message/edit'
AIChatMessage = require 'models/AIChatMessage'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'

nodes = require 'views/editor/level/treema_nodes'

require 'lib/game-libraries'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'

module.exports = class AIChatMessageEditView extends RootView
  id: 'editor-ai-chat-message-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'
    'click #delete-button': 'confirmDeletion'

  constructor: (options, @chatMessageID) ->
    super options
    @chatMessage = new AIChatMessage(_id: @chatMessageID)
    @chatMessage.saveBackups = true
    @supermodel.loadModel @chatMessage

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @chatMessage, 'change', =>
      @treema.set('/', @chatMessage.attributes)

  buildTreema: ->
    return if @treema? or (not @chatMessage.loaded)
    data = $.extend(true, {}, @chatMessage.attributes)
    options =
      data: data
      filePath: "db/ai_chat_message/#{@chatMessage.get('_id')}"
      schema: AIChatMessage.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
      nodeClasses:
        'chat-message-parent-link': nodes.ChatMessageParentLinkNode
        'ai-document-link': nodes.AIDocumentLinkNode
    @treema = @$el.find('#ai-chat-message-treema').treema(options)
    @treema.build()
    @treema.open(2)

  afterRender: ->
    super()
    return unless @supermodel.finished()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @chatMessage.set(key, value)

    res = @chatMessage.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/ai-chat-message/#{@chatMessage.get('slug') or @chatMessage.id}"
      document.location.href = url

  confirmDeletion: ->
    renderData =
      title: 'Are you really sure?'
      body: 'This will completely delete the chat message.'
      decline: 'Not really'
      confirm: 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @deleteAIChatMessage
    @openModalView confirmModal

  deleteAIChatMessage: =>
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 5000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
        _.delay ->
          application.router.navigate '/editor/ai-chat-message', trigger: true
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting chat message message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_chat_message/#{@chatMessage.id}"
