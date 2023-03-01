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

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.chat_title'
    context.currentNew = 'editor.new_chat_title'
    context.currentNewSignup = 'editor.new_chat_title_login'
    context.currentSearch = 'editor.chat_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context
