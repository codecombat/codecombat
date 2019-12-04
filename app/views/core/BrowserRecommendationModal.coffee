require('app/styles/modal/recommendation-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/core/recommendation-modal.pug'
forms = require 'core/forms'
storage = require 'core/storage'

module.exports = class BrowserRecommendationModal extends ModalView
  id: 'browser-recommendation-modal'
  closesOnClickOutside: false
  template: template

  events:
    'click #downlaod-button': 'downloadChrome'
    'click #cancel-button': 'onClickClose'

  downloadChrome: ->
    chromeUrl = "https://www.google.cn/intl/zh-CN/chrome/"
    window.open chromeUrl, target: "_blank"

  onClickClose: ->
    storage.save 'hideBrowserRecommendation', true
