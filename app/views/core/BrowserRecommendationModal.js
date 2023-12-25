// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let BrowserRecommendationModal
require('app/styles/modal/recommendation-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('templates/core/recommendation-modal.pug')
const forms = require('core/forms')
const storage = require('core/storage')

module.exports = (BrowserRecommendationModal = (function () {
  BrowserRecommendationModal = class BrowserRecommendationModal extends ModalView {
    static initClass () {
      this.prototype.id = 'browser-recommendation-modal'
      this.prototype.closesOnClickOutside = false
      this.prototype.template = template

      this.prototype.events = {
        'click #downlaod-button': 'downloadChrome',
        'click #cancel-button': 'onClickClose'
      }
    }

    downloadChrome () {
      const chromeUrl = 'https://www.google.cn/intl/zh-CN/chrome/'
      return window.open(chromeUrl, { target: '_blank' })
    }

    onClickClose () {
      return storage.save('hideBrowserRecommendation', true)
    }
  }
  BrowserRecommendationModal.initClass()
  return BrowserRecommendationModal
})())
