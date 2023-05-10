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

  formatChat: (chat) ->
    content = chat.get('message')?.text or ''
    content = content.replace /^\|Free\|?:? ?(.*?)$/gm, '$1'
    content = content.replace /^\|Issue\|?:? ?(.*?)$/gm, '\n$1'
    content = content.replace /^\|Explanation\|?:? ?(.*?)$/gm, '\n*$1*\n'
    content = content.replace /\|Code\|?:? ?```\n?((.|\n)*?)```\n?$/g, (match, p1) =>
      '[Fix Code]'
    content = content.trim()
    content = marked content, gfm: true, breaks: true
    content = content.replace(RegExp('  ', 'g'), '&nbsp; ') # coffeescript can't compile '/  /g'
    # Replace any <p><code>...</code></p> with <pre><code>...</code></pre>
    content = content.replace /<p><code>((.|\n)*?)(?:(?!<\/code>)(.|\n))*?<\/code><\/p>/g, (match) ->
      match.replace(/<p><code>/g, '<pre><code>').replace(/<\/code><\/p>/g, '</code></pre>')
    content = content.replace /\[Fix Code\]/g, '<p><button class="btn btn-illustrated btn-small btn-primary fix-code-button">Fix Code</button></p>'
    content
