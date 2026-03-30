const RootView = require('views/core/RootView')
let DynamicView
module.exports = (DynamicView = (function () {
  DynamicView = class DynamicView extends RootView {
    constructor (options) {
      super(options)
      this.template = require('templates/base-ai')
    }

    render () {
      super.render()
      const self = this
      const url = window.location.pathname
      $.get(`${url}.html`, function (data) {
        // Data is the raw HTML string from the file
        self.$el.find('#site-content-area').html(data)
      })
      return this
    }

    static initClass () {
      this.prototype.id = 'dynamic-view'
    }
  }
  DynamicView.initClass()
  return DynamicView
})())