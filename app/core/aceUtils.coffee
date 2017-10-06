# These were extracted out of utils.coffee to prevent everything from having Ace as a dependency.

ace = require('lib/aceContainer');

aceEditModes =
  javascript: 'ace/mode/javascript'
  coffeescript: 'ace/mode/coffee'
  python: 'ace/mode/python'
  lua: 'ace/mode/lua'
  java: 'ace/mode/java'
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

module.exports = {
  aceEditModes
  initializeACE
}
