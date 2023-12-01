/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SaveLoadView
require('app/styles/play/menu/save-load-view.sass')
const CocoView = require('views/core/CocoView')
const template = require('app/templates/play/menu/save-load-view')

module.exports = (SaveLoadView = (function () {
  SaveLoadView = class SaveLoadView extends CocoView {
    static initClass () {
      this.prototype.id = 'save-load-view'
      this.prototype.className = 'tab-pane'
      this.prototype.template = template

      this.prototype.events =
        { 'change #save-granularity-toggle input': 'onSaveGranularityChanged' }
    }

    afterRender () {
      return super.afterRender()
    }

    onSaveGranularityChanged (e) {
      this.playSound('menu-button-click')
      const toShow = $(e.target).val()
      this.$el.find('.save-list, .save-pane').hide()
      return this.$el.find('.save-list.' + toShow + ', .save-pane.' + toShow).show()
    }
  }
  SaveLoadView.initClass()
  return SaveLoadView
})())
