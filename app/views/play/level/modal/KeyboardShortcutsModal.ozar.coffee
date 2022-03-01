require('app/styles/play/level/modal/keyboard_shortcuts.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/play/level/modal/keyboard_shortcuts'

module.exports = class KeyboardShortcutsModal extends ModalView
  id: 'keyboard-shortcuts-modal'
  template: template

  isMac: -> false

  getRenderData: ->
    c = super()
    c.ctrl = if @isMac() then '⌘' else '^'
    c.ctrlName = if @isMac() then 'Cmd' else 'Ctrl'
    c.alt = if @isMac() then '⌥' else '⎇'
    c.altName = if @isMac() then 'Opt' else 'Alt'
    c.enter = $.i18n.t 'keyboard_shortcuts.enter'
    c.space = $.i18n.t 'keyboard_shortcuts.space'
    c.escapeKey = $.i18n.t 'keyboard_shortcuts.escape'
    c.shift = $.i18n.t 'keyboard_shortcuts.shift'
    c
