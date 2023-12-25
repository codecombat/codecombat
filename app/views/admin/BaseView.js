// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let BaseView
const RootView = require('views/core/RootView')
const template = require('app/templates/base')

module.exports = (BaseView = (function () {
  BaseView = class BaseView extends RootView {
    static initClass () {
      this.prototype.id = 'base-view'
      this.prototype.template = template
      this.prototype.usesSocialMedia = true
    }
  }
  BaseView.initClass()
  return BaseView
})())
