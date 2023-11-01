require('app/styles/editor/ai-chat-message/table.sass')
SearchView = require 'views/common/SearchView'

module.exports = class AIModelSearchView extends SearchView
  id: 'editor-ai-chat-message-home-view'
  modelLabel: 'Model'
  model: require 'models/AIChatMessage'
  modelURL: '/db/ai_chat_message'
  tableTemplate: require 'app/templates/editor/ai-chat-message/table'
  projection: ['name', 'preview', 'actor', 'description', 'text', 'document','parent', 'parentKind'],
  page: 'ai-chat-message'
  canMakeNew: false

  events:
    'click #delete-button': 'deleteAIModel'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.ai_chat_message_title'
    context.currentNew = 'editor.new_ai_chat_message_title'
    context.currentNewSignup = 'editor.new_ai_chat_message_title_login'
    context.currentSearch = 'editor.ai_chat_message_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context

  deleteAIModel: (e) ->
    chatMessageId = $(e.target).parents('tr').data('chat-message')
    chatMessageName = $(e.target).parents('tr').data('name')
    unless window.confirm "Really delete chat message #{chatMessageName}?"
      noty text: 'Cancelled', timeout: 1000
      return
    @$el.find("tr[data-chat-message='#{chatMessageId}']").remove()
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 2000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting chat message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_chat_messsage/#{chatMessageId}"
