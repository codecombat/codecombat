RootView = require 'views/core/RootView'
template = require 'templates/base-flat'
OutcomesReportComponent = Vue.extend(require('./OutcomesReportComponent.vue')['default'])

module.exports = class OutcomesReportView extends RootView
  id: 'outcomes-report-view'
  template: template

  afterRender: ->
    @vueComponent?.$destroy()
    @vueComponent = new OutcomesReportComponent({
      data: {parentView: @}
      el: @$el.find('#site-content-area')[0]
      store: @store
    })
    super(arguments...)
