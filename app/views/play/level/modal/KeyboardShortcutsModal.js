/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let KeyboardShortcutsModal
require('app/styles/play/level/modal/keyboard_shortcuts.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/play/level/modal/keyboard_shortcuts')

module.exports = (KeyboardShortcutsModal = (function () {
  KeyboardShortcutsModal = class KeyboardShortcutsModal extends ModalView {
    static initClass () {
      this.prototype.id = 'keyboard-shortcuts-modal'
      this.prototype.template = template
    }

    isMac () { return false }

    getRenderData () {
      const c = super.getRenderData()
      c.ctrl = this.isMac() ? '⌘' : '^'
      c.ctrlName = this.isMac() ? 'Cmd' : 'Ctrl'
      c.alt = this.isMac() ? '⌥' : '⎇'
      c.altName = this.isMac() ? 'Opt' : 'Alt'
      c.enter = $.i18n.t('keyboard_shortcuts.enter')
      c.space = $.i18n.t('keyboard_shortcuts.space')
      c.escapeKey = $.i18n.t('keyboard_shortcuts.escape')
      c.shift = $.i18n.t('keyboard_shortcuts.shift')
      return c
    }
  }
  KeyboardShortcutsModal.initClass()
  return KeyboardShortcutsModal
})())
