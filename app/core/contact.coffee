module.exports =
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
  
  sendParentTeacherSignup: ({teacherEmail, parentEmail, parentName, customContent}) ->
    jqxhr = $.ajax('/contact/send-parent-refer-teacher', {
      method: 'POST'
      data: {teacherEmail, parentEmail, parentName, customContent}
    })
    return new Promise(jqxhr.then)

  sendTeacherSignupInstructions: (teacherEmail, studentName) ->
    jqxhr = $.ajax('/contact/send-teacher-signup-instructions', {
      method: 'POST'
      data: {teacherEmail, studentName}
    })
    return new Promise(jqxhr.then)

  sendTeacherGameDevProjectShare: ({teacherEmail, sessionId, codeLanguage, levelName}) ->
    jqxhr = $.ajax('/contact/send-teacher-game-dev-project-share', {
      method: 'POST'
      data: {teacherEmail, sessionId, levelName, codeLanguage: _.string.titleize(codeLanguage).replace('script', 'Script')}
    })
    return new Promise(jqxhr.then)

