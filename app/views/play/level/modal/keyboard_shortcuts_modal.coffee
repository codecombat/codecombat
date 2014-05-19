View = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/keyboard_shortcuts'

module.exports = class KeyboardShortcutsModal extends View
  id: 'keyboard-shortcuts-modal'
  template: template

  getRenderData: ->
    c = super()
    c.ctrl = if @isMac() then '⌘' else '^'
    c.ctrlName = if @isMac() then 'Cmd' else 'Ctrl'
    c.alt = if @isMac() then '⌥' else 'alt'
    c.altName = if @isMac() then 'Opt' else 'Alt'
    c.enter = $.i18n.t 'keyboard_shortcuts.enter'
    c.space = $.i18n.t 'keyboard_shortcuts.space'
    c.escapeKey = $.i18n.t 'keyboard_shortcuts.escape'
    c
