require('app/styles/play/modal/share-progress-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/share-progress-modal'
storage = require 'core/storage'

module.exports = class ShareProgressModal extends ModalView
  id: 'share-progress-modal'
  template: template
  plain: true
  closesOnClickOutside: false

  events:
    'click .close-btn': 'hide'
    'click .continue-link': 'hide'
    'click .send-btn': 'onClickSend'

  onClickSend: (e) ->
    email = $('.email-input').val()
    unless /[\w\.]+@\w+\.\w+/.test email
      $('.email-input').parent().addClass('has-error')
      $('.email-invalid').show()
      return false

    request = @supermodel.addRequestResource 'send_one_time_email', {
      url: '/db/user/-/send_one_time_email'
      data: {email: email, type: 'share progress modal parent'}
      method: 'POST'
    }, 0
    request.load()

    storage.save 'sent-parent-email', true
    @hide()
