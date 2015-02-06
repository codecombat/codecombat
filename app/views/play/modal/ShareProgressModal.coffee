ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/share-progress-modal'

module.exports = class SubscribeModal extends ModalView
  id: 'share-progress-modal'
  template: template
  plain: true
  closesOnClickOutside: false

  events:
    'click .back-link': 'onBackClick'
    'click .close-btn': 'hide'
    'click .continue-link': 'hide'
    'click .send-btn': 'onClickSend'
    'click .tell-friend-btn': 'onClickTellFriend'
    'click .tell-parent-btn': 'onClickTellParent'

  onBackClick: (e) ->
    $('.email-input').val('')
    $('.send-container').hide()
    $('.friend-blurb').hide()
    $('.parent-blurb').hide()
    $('.btn-picker-container').show()
    $('.email-input').parent().removeClass('has-error')
    $('.email-invalid').hide()

  onClickTellFriend: (e) ->
    @emailType = 'share progress modal friend'
    $('.btn-picker-container').hide()
    $('.friend-blurb').show()
    $('.send-container').show()

  onClickTellParent: (e) ->
    @emailType = 'share progress modal parent'
    $('.btn-picker-container').hide()
    $('.parent-blurb').show()
    $('.send-container').show()

  onClickSend: (e) ->
    email = $('.email-input').val()
    unless /[\w\.]+@\w+\.\w+/.test email
      $('.email-input').parent().addClass('has-error')
      $('.email-invalid').show()
      return false

    request = @supermodel.addRequestResource 'send_one_time_email', {
      url: '/db/user/-/send_one_time_email'
      data: {email: email, type: @emailType}
      method: 'POST'
    }, 0
    request.load()

    @hide()
