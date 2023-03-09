require('app/styles/editor/chat/edit.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/editor/chat/edit'
ChatMessage = require 'models/ChatMessage'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'
unidiff = require 'unidiff'

require 'lib/game-libraries'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'

module.exports = class ChatEditView extends RootView
  id: 'editor-chat-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'
    'click #i18n-button': 'onPopulateI18N'
    'click #delete-button': 'confirmDeletion'
    'click #fix-button': 'onFix'
    'click #diff-button': 'onAddDiff'

  constructor: (options, @chatID) ->
    super options
    @chat = new ChatMessage(_id: @chatID)
    @chat.saveBackups = true
    @supermodel.loadModel @chat

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @chat, 'change', =>
      @chat.updateI18NCoverage()
      @treema.set('/', @chat.attributes)

  buildTreema: ->
    return if @treema? or (not @chat.loaded)
    data = $.extend(true, {}, @chat.attributes)
    options =
      data: data
      filePath: "db/chat_message/#{@chat.get('_id')}"
      schema: ChatMessage.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
    @treema = @$el.find('#chat-treema').treema(options)
    @treema.build()
    @treema.childrenTreemas.message?.open(2)
    @treema.childrenTreemas.context?.open(2)
    @treema.childrenTreemas.context?.childrenTreemas.i18n?.close()
    @treema.childrenTreemas.context?.childrenTreemas.apiProperties?.close()

  afterRender: ->
    super()
    return unless @supermodel.finished()

  onPopulateI18N: ->
    @chat.populateI18N()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @chat.set(key, value)
    @chat.updateI18NCoverage()

    res = @chat.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/chat/#{@chat.get('slug') or @chat.id}"
      document.location.href = url

  confirmDeletion: ->
    renderData =
      title: 'Are you really sure?'
      body: 'This will completely delete the chat message.'
      decline: 'Not really'
      confirm: 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @deleteChatMessage
    @openModalView confirmModal

  deleteChatMessage: =>
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 5000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
        _.delay ->
          application.router.navigate '/editor/chat', trigger: true
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting chat message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/chat_message/#{@chat.id}"

  onFix: (e) ->
    current = @treema.get('/context/code/current/javascript')
    if not current?
      return noty
        timeout: 5000
        text: 'You need to have current code to fix'
        type: 'error'
        layout: 'topCenter'
    @treema.set '/context/code/fixed', javascript: current
    @treema.childrenTreemas.context.childrenTreemas.code.open(1)
    @treema.childrenTreemas.context.childrenTreemas.code.childrenTreemas.fixed.open()
    @treema.childrenTreemas.context.childrenTreemas.code.childrenTreemas.current.open()

  onAddDiff: (e) ->
    a = @treema.get('/context/code/current/javascript')
    b = @treema.get('/context/code/fixed/javascript')
    b ?= @treema.get('/context/code/solution/javascript')
    if not a? or not b?
      return noty
        timeout: 5000
        text: 'You need to have both a current and solution context to diff.'
        type: 'error'
        layout: 'topCenter'
    diff = unidiff.diffAsText(a, b, {context: 1})
    diff = diff.replace(/^--- a\n/, '').replace(/^\+\+\+ b\n/, '')  # Remove "filename" part of header
    diff = diff.replace(/^(@@.*?)\n/m, '$1')  # Remove blank line after rest of diff header
    @treema.set '/message/textComponents/diff', diff
    messageText = @treema.get('/message/text')
    @treema.set '/message/text', messageText + '\n\ndiff\n' + diff  # TODO: replace existing diff?
    @treema.childrenTreemas.message?.close()
    @treema.childrenTreemas.message?.open(2)
