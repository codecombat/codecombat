require('app/styles/play/level/chat.sass')
CocoView = require 'views/core/CocoView'
template = require 'app/templates/play/level/chat'
{me} = require 'core/auth'
LevelBus = require 'lib/LevelBus'
ChatMessage = require 'models/ChatMessage'
utils = require 'core/utils'
fetchJson = require 'core/api/fetch-json'
co = require 'co'

module.exports = class LevelChatView extends CocoView
  id: 'level-chat-view'
  template: template
  open: false
  visible: false

  events:
    'keydown textarea': 'onChatKeydown'
    'keypress textarea': 'onChatKeypress'
    'click i': 'onIconClick'
    'click .fix-code-button': 'onFixCodeClick'

  subscriptions:
    'level:toggle-solution': 'onToggleSolution'
    'level:close-solution': 'onCloseSolution'
    'level:add-user-chat': 'onAddUserChat'

  constructor: (options) ->
    @levelID = options.levelID
    @session = options.session
    @sessionID = options.sessionID
    @bus = LevelBus.get(@levelID, @sessionID)
    super options
    @onWindowResize = _.debounce @onWindowResize, 50
    $(window).on 'resize', @onWindowResize

    ## TODO: we took out session.multiplayer, so this will not fire. If we want to resurrect it, we'll of course need a new way of activating chat.
    #@listenTo(@session, 'change:multiplayer', @updateMultiplayerVisibility)
    @visible = me.getLevelChatExperimentValue() is 'beta'  # not 'control'

    @regularlyClearOldMessages()
    @playNoise = _.debounce(@playNoise, 100)

  updateMultiplayerVisibility: ->
    return unless @$el?
    try
      @$el.toggle Boolean @session.get('multiplayer')
    catch e
      console.error "Couldn't toggle the style on the LevelChatView to #{Boolean @session.get('multiplayer')} because of an error:", e

  afterRender: ->
    @chatTables = $('.table', @$el)
    #@updateMultiplayerVisibility()
    @$el.toggle @visible
    @onWindowResize {}

  regularlyClearOldMessages: ->
    return  # Leave chatbot messages around, actually
    @clearOldMessagesInterval = setInterval(@clearOldMessages, 5000)

  clearOldMessages: =>
    rows = $('.closed-chat-area.tr')
    for row in rows
      row = $(row)
      added = row.data('added')
      if new Date().getTime() - added > 60 * 1000
        row.fadeOut(1000, -> $(this).remove())

  onNewMessage: ({ message, messageId }) ->
    @$el.show() unless message?.system
    @addOne { message, messageId }
    @trimClosedPanel()
    @playNoise() if message.authorID isnt me.id

  playNoise: ->
    @playSound 'chat_received'

  messageObjectToJQuery: ({ message, messageId, existingRow }) ->
    td = $('<div class="td message-content"></div>')
    content = message.content or message.text

    # Hide incomplete structured chat tags
    content = content.replace /^\|$/gm, ''
    content = content.replace /^\|Free\|?:? ?(.*?)$/gm, '$1'
    content = content.replace /^\|Issue\|?:? ?(.*?)$/gm, '\n$1'
    content = content.replace /^\|Explanation\|?:? ?(.*?)$/gm, '\n*$1*\n'
    #content = content.replace /\|Code\|?:? ?`{0,3}\n?((.|\n)*?)`{0,3}\n?$/g, '```$1```'
    content = content.replace /\|Code\|?:? ?\n?```.*?\n((.|\n)*?)```\n?/g, (match, p1) =>
      @lastFixedCode = p1
      '[Show Me]'
    content = content.replace /\|Code\|?:? ?\n?`{0,3}.*?\n((.|\n)*?)`{0,3}\n?$/g, ( match, p1) ->
      numberOfLines = (p1.match(/\n/g) || []).length + 1
      if p1
        Backbone.Mediator.publish 'level:update-solution', code: p1
      '\n[Show Me]\n*Loading code fix' + '.'.repeat(numberOfLines) + '...*'
    # Close any unclosed backticks delimiters so we get complete <code> tags
    unclosedBackticks = (content.match(/`/g) || []).length
    if unclosedBackticks % 2 != 0
      content += '`'

    #content = _.string.escapeHTML(content.trim())  # hmm, what to do with escaping when we often need code?
    content = content.trim()
    content = marked content, gfm: true, breaks: true
    # TODO: this probably doesn't work with the links and buttons we intend to have, gotta think about sanitization properly

    content = content.replace(RegExp('  ', 'g'), '&nbsp; ') # coffeescript can't compile '/  /g'

    # Replace any <p><code>...</code></p> with <pre><code>...</code></pre>
    content = content.replace /<p><code>((.|\n)*?)(?:(?!<\/code>)(.|\n))*?<\/code><\/p>/g, (match) ->
      match.replace(/<p><code>/g, '<pre><code>').replace(/<\/code><\/p>/g, '</code></pre>')

    content = content.replace /\[Show Me\]/g, "<p><button class='btn btn-illustrated btn-small btn-primary fix-code-button'>#{$.i18n.t('play_level.chat_fix_show')}</button></p>"
    @$el.find('.fix-code-button').parent().remove()  # We only keep track of the latest one to fix, so get rid of old ones

    if _.string.startsWith(content, '/me')
      content = (message.authorName or message.sender?.name) + content.slice(3)

    if message.system
      td.append($('<span class="system"></span>').html(content))

    else if _.string.startsWith(content, '/me')
      td.append($('<span class="action"></span>').html(content))

    else
      # td.append($('<strong></strong>').text((message.authorName or message.sender?.name) + ': '))
      td.append($('<span></span>').html(content))

    if existingRow?.length
      tr = $(existingRow[0])
      tr.find('.td.message-content').replaceWith(td)
    else
      tr = $('<div class="tr message-row"></div>')
      mbody = $('<div class="message-body"></div>')
      if message.authorID is me.id or message.sender?.id is me.id
        tr.addClass('me')
        avatarTd = $("<div class='td player-avatar-cell avatar-cell'><a href='/editor/chat/#{messageId or ''}' target='_blank'><img class='avatar' src='/db/user/#{me.id}/avatar?s=80' alt='Player'></a></div>")
      else
        avatarTd = $("<div class='td chatbot-avatar-cell avatar-cell'><a href='/editor/chat/#{messageId or ''}' target='_blank'><img class='avatar' src='/images/level/baby-griffin.png' alt='AI'></a></div>")
      tr.addClass 'streaming' if message.streaming
      mbody.append(avatarTd)
      mbody.append(td)
      tr.append(mbody)
    tr

  addOne: ({ message, messageId }) ->
    return if message.system and message.authorID is me.id
    if not @open
      @onIconClick {}
    openPanel = $('.open-chat-area', @$el)
    height = openPanel.outerHeight()
    distanceFromBottom = openPanel[0].scrollHeight - height - openPanel[0].scrollTop
    doScroll = distanceFromBottom < 10
    tr = @messageObjectToJQuery { message, messageId }
    tr.data('added', new Date().getTime())
    @chatTables.append(tr)
    @scrollDown() if doScroll

  trimClosedPanel: ->
    closedPanel = $('.closed-chat-area', @$el)
    limit = 10
    rows = $('.tr', closedPanel)
    for row, i in rows
      break if rows.length - i <= limit
      row.remove()
    @scrollDown()

  onChatKeydown: (e) ->
    _.defer ->
      $(e.target).css 'height', 27
      $(e.target).css 'height', e.target.scrollHeight

  onChatKeypress: (e) ->
    return unless key.isPressed('enter') and not key.shift
    text = _.string.strip($(e.target).val())
    return false unless text
    #@bus.sendMessage(text)  # TODO: bring back bus?
    @saveChatMessage { text }
    $(e.target).val('')
    return false

  onIconClick: (e) ->
    @open = not @open
    openPanel = $('.open-chat-area', @$el).toggle @open
    closedPanel = $('.closed-chat-area', @$el).toggle not @open
    @scrollDown()
    if window.getSelection?
      sel = window.getSelection()
      sel.empty?()
      sel.removeAllRanges?()
    else
      document.selection.empty()

  onFixCodeClick: (e) ->
    Backbone.Mediator.publish 'level:toggle-solution', { code: @lastFixedCode ? '' }

  onToggleSolution: ->
    btn = @$el.find('.fix-code-button')
    show = $.i18n.t('play_level.chat_fix_show')
    hide = $.i18n.t('play_level.chat_fix_hide')
    if btn.html() == show
      btn.html hide
    else
      btn.html show

  onCloseSolution: (e) ->
    @$el.find('.fix-code-button').html $.i18n.t('play_level.chat_fix_show')

  onAddUserChat: (e) ->
    @saveChatMessage { text: e.message }

  scrollDown: ->
    openPanel = $('.open-chat-area', @$el)[0]
    openPanel.scrollTop = openPanel.scrollHeight or 1000000

  saveChatMessage: ({ text, sender }) ->
    chatMessage = new ChatMessage @getChatMessageProps { text, sender }
    @chatMessages ?= []
    @chatMessages.push chatMessage
    Backbone.Mediator.publish 'level:gather-chat-message-context', { chat: chatMessage.attributes }
    # This will enrich the message with the props from other parts of the app
    @listenToOnce chatMessage, 'sync', @onChatMessageSaved
    chatMessage.save()
    @$el.find('textarea').attr('placeholder', '')
    #@onNewMessage message: chatMessage.get('message'), messageId: chatMessage.get('_id')  # TODO: do this now and add message id link later

  onChatMessageSaved: (chatMessage) ->
    @onNewMessage message: chatMessage.get('message'), messageId: chatMessage.get('_id')  # TODO: temporarily putting this after save so we have message id link
    return if chatMessage.get('message')?.sender?.kind is 'bot'
    #fetchJson("/db/chat_message/#{chatMessage.id}/ai-response").then @onChatResponse
    @fetchChatMessageStream chatMessage.id

  fetchChatMessageStream: (chatMessageId) ->
    model = utils.getQueryVariable('model') or 'gpt-4' # or 'chima'
    fetch("/db/chat_message/#{chatMessageId}/ai-response?model=#{model}").then co.wrap (response) =>
      reader = response.body.getReader()
      decoder = new TextDecoder('utf-8')
      sender = { kind: 'bot', name: 'Code AI' }  # TODO: handle sender name again
      @startStreamingAIChatMessage sender
      result = ''
      Backbone.Mediator.publish 'level:streaming-solution', finish: false
      while true
        { done, value } = yield reader.read()
        chunk = decoder.decode value
        chunk = chunk.replace(/(^{"propertyA":\["|"\],"propertyB":\[\]}$)/g, '').replace(/\\n/g, '\n').replace(/\\"/g, '"')
        result += chunk
        @addToStreamingAIChatMessage sender: sender, chunk: chunk, result: result
        break if done

      Backbone.Mediator.publish 'level:streaming-solution', finish: true
      @clearStreamingAIChatMessage()
      @saveChatMessage text: result, sender: sender

  startStreamingAIChatMessage: (sender) ->
    @onNewMessage message: { sender: sender, text: '...', streaming: true }

  addToStreamingAIChatMessage: ({ sender, chunk, result }) ->
    lastRow = @chatTables.find('.tr.streaming:last-child')
    # TODO: I commented out the .closed-chat-area to make this work, should bring that back and not have two elements in lastRow
    tr = @messageObjectToJQuery { message: { sender: sender, text: result, streaming: true }, existingRow: lastRow }
    tr.data('added', new Date().getTime())
    if not lastRow?.length
      @chatTables.append(tr)
    @scrollDown()

  clearStreamingAIChatMessage: ->
    lastRow = @chatTables.find('.tr.streaming:last-child')
    lastRow.remove()

  onChatResponse: (message) =>
    return if @destroyed
    #@onNewMessage message: message
    @saveChatMessage text: message.text, sender: message.sender

  getChatMessageProps: ({ text, sender }) ->
    sender =
      if sender?.kind is 'bot'
        name: if /(^Line \d|```)/m.test(text) then 'Code AI' else 'Chat AI'
        kind: 'bot'
      else
        id: me.get('_id')
        name: me.displayName() or me.broadName()
        kind: 'player'
    props =
      product: utils.getProduct()
      kind: 'level-chat'
      #example: Boolean me.isAdmin() # TODO: implement the non-example version of the chat
      example: true
      message:
        text: text
        textComponents: {}
        sender: sender
        startDate: new Date()  # TODO: track when they started typing
        endDate: new Date()
      context:
        spokenLanguage: me.get('preferredLanguage', true)
        player: me.get('_id')
        playerName: me.displayName() or me.broadName()
        previousMessages: (m.serializeMessage() for m in (@chatMessages ? []))
      permissions: [{ target: me.get('_id'), access: 'owner' }]
    props.releasePhase = 'beta' if props.example

    structuredMessage = props.message.text

    codeIssueWithLineRegex = /^\|Issue\|: Line (\d+): (.+)$/m
    codeIssueWithLine = structuredMessage.match(codeIssueWithLineRegex)
    if codeIssueWithLine
      props.message.textComponents.codeIssue = line: parseInt(codeIssueWithLine[1], 10), text: codeIssueWithLine[2]
      structuredMessage = structuredMessage.replace(codeIssueWithLineRegex, '')
    else
      codeIssueRegex = /^\|Issue\|: (.+)$/m
      codeIssue = structuredMessage.match(codeIssueRegex)
      if codeIssue
        props.message.textComponents.codeIssue = text: codeIssue[1]
        structuredMessage = structuredMessage.replace(codeIssueRegex, '')

    codeIssueExplanationRegex = /^\|Explanation\|: (.+)$/m
    codeIssueExplanation = structuredMessage.match(codeIssueExplanationRegex)
    if codeIssueExplanation
      props.message.textComponents.codeIssueExplanation = text: codeIssueExplanation[1]
      structuredMessage = structuredMessage.replace(codeIssueExplanationRegex, '')

    linkRegex = /^\|Link\|: \[(.+?)\]\((.+?)\)$/m
    while link = structuredMessage.match(linkRegex)
      props.message.textComponents.links ?= []
      props.message.textComponents.links.push text: link[1], url: link[2]
      structuredMessage = structuredMessage.replace(linkRegex, '')

    # TODO: remove explicit actionButton references, we'll probably autogenerate action buttons and just always have [Fix It] buttons
    actionButtonRegex = /^<button( action='?"?(.+?)'?"?)?>(.+?)<\/button>$/m
    while actionButton = structuredMessage.match(actionButtonRegex)
      props.message.textComponents.actionButtons ?= []
      button = text: actionButton[3]
      if actionButton[2]
        button.action = actionButton[2]
      props.message.textComponents.actionButtons.push button
      structuredMessage = structuredMessage.replace(actionButtonRegex, '')

    codeRegex = /\|Code\|?:? ?```\n?((.|\n)+)```\n?/
    code = structuredMessage.match(codeRegex)
    if code
      props.message.textComponents.code = code[1]
      structuredMessage = structuredMessage.replace(codeRegex, '')

    freeTextRegex = /^\|Free\|: (.+)$/m
    freeTextMatch = _.string.strip(structuredMessage).match(freeTextRegex)
    if freeTextMatch
      freeText = freeTextMatch[1]
      structuredMessage = _.string.strip(structuredMessage).replace(freeTextRegex, '')
    else
      freeText = _.string.strip(structuredMessage)

    props.message.textComponents.freeText = freeText if freeText.length
    props

  onWindowResize: (e) =>
    # Couldn't figure out the CSS to make this work, so doing it here
    return if @destroyed
    maxHeight = $(window).height() - $('#thang-hud').offset().top - $('#thang-hud').height() - 25 - 30
    if maxHeight < 0
      # Just have to overlay the level, and have them close when done
      maxHeight = 0
    @$el.find('.closed-chat-area').css('max-height', maxHeight)

  destroy: ->
    key.deleteScope('level')
    clearInterval @clearOldMessagesInterval if @clearOldMessagesInterval
    $(window).off 'resize', @onWindowResize
    super()
