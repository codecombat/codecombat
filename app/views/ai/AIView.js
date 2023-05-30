/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIView
import 'app/styles/ai/ai.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/ai/ai';
let ai
try {
  ai = require('../../../node_modules/ai/dist/ai.js')
  require('../../../node_modules/ai/dist/style.css')
} catch (e) {
  console.warn('AI import unavailable; /ai will not work')
  console.warn(e)
  ai = { AI: () => {} }
}

export default AIView = (function () {
  AIView = class AIView extends RootView {
    static initClass() {
      this.prototype.id = 'ai-view'
      this.prototype.template = template
    }

    afterInsert() {
      // Undo our 62.5% default HTML font-size here
      $('html').css('font-size', '16px')
      ai.AI({ domElement: this.$el.find('#ai-wrapper')[0] })
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
})();
