ModalView = require 'views/core/ModalView'
template = require 'templates/core/browser-recommendation'
forms = require 'core/forms'

module.exports = class BrowserRecommendationModal extends ModalView
  id: 'browser-recommendation-modal'
  template: template

  events:
    'click #downlaod-button': 'downloadChrome'

  downloadChrome: ->
    chromeUrl = "https://www.google.cn/intl/zh-CN/chrome/"
    window.open chromeUrl, target: "_blank"
