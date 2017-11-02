require('app/styles/play/level/chat.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/chat'
{me} = require 'core/auth'
LevelBus = require 'lib/LevelBus'

module.exports = class LevelChatView extends CocoView
  id: 'level-chat-view'
  template: template
  open: false

  events:
    'keypress textarea': 'onChatKeydown'
    'click i': 'onIconClick'

  subscriptions:
    'bus:new-message': 'onNewMessage'

  constructor: (options) ->
    @levelID = options.levelID
    @session = options.session
    # TODO: we took out session.multiplayer, so this will not fire. If we want to resurrect it, we'll of course need a new way of activating chat.
    @listenTo(@session, 'change:multiplayer', @updateMultiplayerVisibility)
    @sessionID = options.sessionID
    @bus = LevelBus.get(@levelID, @sessionID)
    super()
    @regularlyClearOldMessages()
    @playNoise = _.debounce(@playNoise, 100)

  updateMultiplayerVisibility: ->
    return unless @$el?
    try
      @$el.toggle Boolean @session.get('multiplayer')
    catch e
      console.error "Couldn't toggle the style on the LevelChatView to #{Boolean @session.get('multiplayer')} because of an error:", e

  afterRender: ->
    @chatTables = $('table', @$el)
    @updateMultiplayerVisibility()

  regularlyClearOldMessages: ->
    @clearOldMessagesInterval = setInterval(@clearOldMessages, 5000)

  clearOldMessages: =>
    rows = $('.closed-chat-area tr')
    for row in rows
      row = $(row)
      added = row.data('added')
      if new Date().getTime() - added > 60 * 1000
        row.fadeOut(1000, -> $(this).remove())

  onNewMessage: (e) ->
    @$el.show() unless e.message.system
    @addOne(e.message)
    @trimClosedPanel()
    @playNoise() if e.message.authorID isnt me.id

  playNoise: ->
    @playSound 'chat_received'

  messageObjectToJQuery: (message) ->
    td = $('<td></td>')
    content = message.content
    content = _.string.escapeHTML(content)
    content = content.replace(/\n/g, '<br/>')
    content = content.replace(RegExp('  ', 'g'), '&nbsp; ') # coffeescript can't compile '/  /g'
    if _.string.startsWith(content, '/me')
      content = message.authorName + content.slice(3)

    if message.system
      td.append($('<span class="system"></span>').html(content))

    else if _.string.startsWith(content, '/me')
      td.append($('<span class="action"></span>').html(content))

    else
      td.append($('<strong></strong>').text(message.authorName+': '))
      td.append($('<span></span>').html(content))

    tr = $('<tr></tr>')
    tr.addClass('me') if message.authorID is me.id
    tr.append(td)

  addOne: (message) ->
    return if message.system and message.authorID is me.id
    if @open
      openPanel = $('.open-chat-area', @$el)
      height = openPanel.outerHeight()
      distanceFromBottom = openPanel[0].scrollHeight - height - openPanel[0].scrollTop
      doScroll = distanceFromBottom < 10
    tr = @messageObjectToJQuery(message)
    tr.data('added', new Date().getTime())
    @chatTables.append(tr)
    @scrollDown() if doScroll

  trimClosedPanel: ->
    closedPanel = $('.closed-chat-area', @$el)
    limit = 5
    rows = $('tr', closedPanel)
    for row, i in rows
      break if rows.length - i <= limit
      row.remove()

  onChatKeydown: (e) ->
    if key.isPressed('enter')
      message = _.string.strip($(e.target).val())
      return false unless message
      @bus.sendMessage(message)
      $(e.target).val('')
      return false

  onIconClick: ->
    @open = not @open
    openPanel = $('.open-chat-area', @$el).toggle @open
    closedPanel = $('.closed-chat-area', @$el).toggle not @open
    @scrollDown() if @open
    if window.getSelection?
      sel = window.getSelection()
      sel.empty?()
      sel.removeAllRanges?()
    else
      document.selection.empty()

  scrollDown: ->
    openPanel = $('.open-chat-area', @$el)[0]
    openPanel.scrollTop = openPanel.scrollHeight or 1000000

  destroy: ->
    key.deleteScope('level')
    clearInterval @clearOldMessagesInterval if @clearOldMessagesInterval
    super()
