require('app/styles/editor/chat/table.sass')
SearchView = require 'views/common/SearchView'

module.exports = class ChatSearchView extends SearchView
  id: 'editor-chat-home-view'
  modelLabel: 'Chat'
  model: require 'models/ChatMessage'
  modelURL: '/db/chat_message'
  tableTemplate: require 'app/templates/editor/chat/table'
  projection: ['startDate', 'endDate', 'kind', 'example', 'releasePhase', 'context.levelName', 'message.sender.name', 'message.text']
  page: 'chat'
  canMakeNew: false
  limit: 1000

  events:
    'click #delete-button': 'deleteChatMessage'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.chat_title'
    context.currentNew = 'editor.new_chat_title'
    context.currentNewSignup = 'editor.new_chat_title_login'
    context.currentSearch = 'editor.chat_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context

  deleteChatMessage: (e) ->
    chatId = $(e.target).parents('tr').data('chat')
    @$el.find("tr[data-chat='#{chatId}']").remove()
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
      url: "/db/chat_message/#{chatId}"
