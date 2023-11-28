// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let OutcomesReportView
const RootView = require('views/core/RootView')
const template = require('app/templates/base-flat')
const OutcomesReportComponent = Vue.extend(require('./OutcomesReportComponent.vue').default)

module.exports = (OutcomesReportView = (function () {
  OutcomesReportView = class OutcomesReportView extends RootView {
    static initClass () {
      this.prototype.id = 'outcomes-report-view'
      this.prototype.template = template
    }

    afterRender () {
      if (this.vueComponent != null) {
        this.vueComponent.$destroy()
      }
      this.vueComponent = new OutcomesReportComponent({
        data: { parentView: this },
        el: this.$el.find('#site-content-area')[0],
        store: this.store
      })
      return super.afterRender(...arguments)
    }
  }
  OutcomesReportView.initClass()
  return OutcomesReportView
})())
