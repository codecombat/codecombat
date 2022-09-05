# These were extracted out of utils.coffee to prevent everything from having Ace as a dependency.

ace = require('lib/aceContainer');
TokenIterator = ace.require('ace/token_iterator').TokenIterator
UndoManager = ace.require('ace/undomanager').UndoManager
Y = require 'yjs'
{ WebrtcProvider } = require 'y-webrtc'
{ WebsocketProvider } = require 'y-websocket'
{ AceBinding } = require 'y-ace'

aceEditModes =
  javascript: 'ace/mode/javascript'
  coffeescript: 'ace/mode/coffee'
  python: 'ace/mode/python'
  lua: 'ace/mode/lua'
  java: 'ace/mode/java'
  cpp: 'ace/mode/c_cpp'
  html: 'ace/mode/html'

# These ACEs are used for displaying code snippets statically, like in SpellPaletteEntryView popovers
# and have short lifespans
initializeACE = (el, codeLanguage) ->
  contents = $(el).text().trim()
  editor = ace.edit el
  editor.setOptions maxLines: Infinity
  editor.setReadOnly true
  editor.setTheme 'ace/theme/textmate'
  editor.setShowPrintMargin false
  editor.setShowFoldWidgets false
  editor.setHighlightActiveLine false
  editor.setHighlightActiveLine false
  editor.setBehavioursEnabled false
  editor.renderer.setShowGutter false
  editor.setValue contents
  editor.clearSelection()
  session = editor.getSession()
  session.setUseWorker false
  session.setMode aceEditModes[codeLanguage]
  session.setWrapLimitRange null
  session.setUseWrapMode true
  session.setNewLineMode 'unix'
  return editor

identifierRegex = (lang, type) ->
  if type is 'function'
    regexs =
      python: /def ([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+\s*\(?[^)]*\)?):/
      javascript: /function ([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+\s*\(?[^)]*\)?)/
      cpp: /[a-z]+\s+([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+\s*\(?[^)]*\)?)/
      java: /[a-z]+\s+([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+\s*\(?[^)]*\)?)/
    if lang of regexs
      return regexs[lang]
    return /./
  else if type is 'properties'
    return /\.([a-zA-Z_0-9\$\-\u00A2-\uFFFF]+)/g
  return /./

singleLineCommentRegex = (lang) ->
  commentStarts =
    javascript: '//'
    python: '#'
    coffeescript: '#'
    lua: '--'
    java: '//'
    cpp: '//'
    html: '<!--'
    css: '/\\*'

  if lang is 'html'
    commentStart = "#{commentStarts.html}|#{commentStarts.css}|#{commentStarts.javascript}"
  else
    commentStart = commentStarts[lang] or '//'
  new RegExp "[ \t]*(#{commentStart})[^\"'\n]*"

parseUserSnippets = (source, lang, session) ->
  replaceParams = (str) ->
    i = 1
    str = str.replace(/([a-zA-Z-0-9\$\-\u00A2-\uFFFF]+)([^,)]*)/g, "${:$1}")
    reg = /\$\{:/
    while (reg.test(str))
      str = str.replace(reg, "${#{i}:")
      i += 1
    str

  makeEntry = (name, content, importance) ->
    content = content ? name
    entry =
      meta: $.i18n.t('keyboard_shortcuts.press_enter', defaultValue: 'press enter')
      importance: importance ? 5
      content: content
      name: name
      tabTrigger: name

  userSnippets = []
  allIdentifiers = {}
  newIdentifiers = {}

  it = new TokenIterator session, 0, 0
  next = it.getCurrentToken()
  next = it.stepForward() unless next
  while next
    if next.type is 'string'
      unless next.value of newIdentifiers
        newIdentifiers[next.value] = makeEntry(next.value)
      else
        newIdentifiers[next.value].importance *= 2
    if next.type is 'identifier'
      if next.value.length is 1 # skip single char variables
        next = it.stepForward()
        continue
      unless next.value of allIdentifiers
        allIdentifiers[next.value] = 5
      else
        allIdentifiers[next.value] *= 2
    # console.log("deubg next:", next)
    next = it.stepForward()

  lines = source.split('\n')
  lines.forEach((line) =>
    if singleLineCommentRegex(lang).test line
      return

    match = identifierRegex(lang, 'function').exec(line)
    if match and match[1]
      [fun, params] = match[1].split('(')
      params = '(' + params
      unless fun of newIdentifiers
        newIdentifiers[fun] = makeEntry(match[1], fun + replaceParams(params), allIdentifiers[fun])
        delete allIdentifiers[fun]
    propertiesRegex = identifierRegex(lang, 'properties')
    while match = propertiesRegex.exec(line)
      if match[1] of allIdentifiers
        delete allIdentifiers[match[1]]
  )
  for id, importance of allIdentifiers
    if id is 'hero' and importance <= 20 # if hero doesn't appears more than twice
      continue
    newIdentifiers[id] = makeEntry(id, id, importance)

  # console.log 'debug newIdentifiers: ', newIdentifiers
  newIdentifiers
  # @autocomplete.addCustomSnippets Object.values(newIdentifiers), lang


setupCRDT = (key, userName, doc, editor) =>
  ydoc = new Y.Doc()
  server = window.location.host
  url = "ws://#{server}/yjs/websocket"
  provider = new WebsocketProvider(url, key, ydoc)
  yType = ydoc.getText('ace')
  provider.on('status', (event) =>
    console.log("what event.status:", event.status)
  )
  provider.once('synced', () =>
    console.log("provider synced here, value", yType.toString())
    if yType.toString() == ''
      yType.insert(0, doc)
    new AceBinding(yType, editor, provider.awareness)
    editor.session.setUndoManager(new UndoManager())
  )
  user =
    name: userName
    color: '#' + Math.floor(Math.random()*16777215).toString(16)
  provider.awareness.setLocalStateField('user', user)

  return provider


module.exports = {
  aceEditModes
  initializeACE
  parseUserSnippets
  setupCRDT
}
