// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let KeyThangTabView
const LevelThangEditView = require('views/editor/level/thangs/LevelThangEditView')
const template = require('app/templates/editor/level/thang/key-thang-tab-view')

module.exports = (KeyThangTabView = (function () {
  KeyThangTabView = class KeyThangTabView extends LevelThangEditView {
    static initClass () {
      this.prototype.id = null
      this.prototype.className = 'key-thang-tab-view tab-pane'
      this.prototype.template = template
    }

    constructor (options) {
      super(options)
      this.id = options.id
      this.interval = setInterval(this.reportChanges, 750)
    }

    destroy () {
      clearInterval(this.interval)
      return super.destroy()
    }
  }
  KeyThangTabView.initClass()
  return KeyThangTabView
})())
