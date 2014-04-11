module.exports.sendContactMessage = (contactMessageObject, modal) ->
  modal.find('.sending-indicator').show()
  jqxhr = $.post '/contact', contactMessageObject, (response) ->
    modal.find('.sending-indicator').hide()
    modal.find('#contact-message').val("Thanks!")
    _.delay ->
      modal.find('#contact-message').val("")
      modal.modal 'hide'
    , 1000
