/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIView
require('app/styles/ai/ai.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/ai/ai')
const ai = require('../../../node_modules/ai/dist/ai')
require('../../../node_modules/ai/dist/style.css')

module.exports = (AIView = (function() {
  AIView = class AIView extends RootView {
    static initClass() {
      this.prototype.id = 'ai-view'
      this.prototype.template = template
    }

    afterInsert() {
      // Undo our 62.5% default HTML font-size here
      $('html').css('font-size', '16px')
      ai.AI({ domElement: this.$el.find('#root')[0], baseDirectory: '/ai' })
      return super.afterInsert()
    }

    destroy() {
      // Redo our 62.5% default HTML font-size here
      $('html').css('font-size', '62.5%')
      return super.destroy()
    }
  }
  AIView.initClass()
  return AIView
})())
