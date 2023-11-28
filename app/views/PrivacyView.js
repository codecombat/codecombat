// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PrivacyView
require('app/styles/privacy.sass')
const RootView = require('views/core/RootView')
const template = require('templates/privacy')

module.exports = (PrivacyView = (function () {
  PrivacyView = class PrivacyView extends RootView {
    static initClass () {
      this.prototype.id = 'privacy-view'
      this.prototype.template = template
    }

    afterRender () {
      super.afterRender()
      if (_.contains(location.href, '#')) {
        return _.defer(() => {
          // Remind the browser of the fragment in the URL, so it jumps to the right section.
          return location.href = location.href
        })
      }
    }
  }
  PrivacyView.initClass()
  return PrivacyView
})())
