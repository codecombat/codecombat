module.exports = {
  sendContactMessage: (contactMessageObject, modal) ->
    # deprecated
    modal?.find('.sending-indicator').show()
    return $.post '/contact', contactMessageObject, (response) ->
      return unless modal
      modal.find('.sending-indicator').hide()
      modal.find('#contact-message').val('Thanks!')
      _.delay ->
        modal.find('#contact-message').val('')
        modal.modal 'hide'
      , 1000
      
  send: (options={}) ->
    options.type = 'POST'
    options.url = '/contact'
    $.ajax(options)


  sendParentSignupInstructions: (parentEmail) ->
    jqxhr = $.ajax('/contact/send-parent-signup-instructions', {
      method: 'POST'
      data: {parentEmail}
    })
    return new Promise(jqxhr.then)
}
