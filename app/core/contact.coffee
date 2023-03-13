module.exports =
  sendContactMessage: (contactMessageObject, modal) ->
    # deprecated
    modal?.find('.sending-indicator').show()
    jqxhr = $.post '/contact', contactMessageObject, (response) ->
      return unless modal
      modal.find('.sending-indicator').hide()
      modal.find('#contact-message').val('Thanks!')
      _.delay ->
        modal.find('#contact-message').val('')
        modal.modal 'hide'
      , 1000
    jqxhr.fail ->
      return unless modal
      if jqxhr.status is 500
        modal.find('.sending-indicator').text $.i18n.t('loading_error.server_error')
    return jqxhr

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

  sendTeacherSignupInstructions: (teacherEmail, studentName) ->
    jqxhr = $.ajax('/contact/send-teacher-signup-instructions', {
      method: 'POST'
      data: {teacherEmail, studentName}
    })
    return new Promise(jqxhr.then)

  sendAPCSPContactMail: ({email, name, role, message}) ->
    jqxhr = $.ajax('/contact/apcsp', {
      method: 'POST'
      data: {email, name, role, message}
    })
    return new Promise(jqxhr.then)

  sendTeacherGameDevProjectShare: ({teacherEmail, sessionId, codeLanguage, levelName}) ->
    jqxhr = $.ajax('/contact/send-teacher-game-dev-project-share', {
      method: 'POST'
      data: {teacherEmail, sessionId, levelName, codeLanguage: _.string.titleize(codeLanguage).replace('script', 'Script')}
    })
    return new Promise(jqxhr.then)

  sendSlackMessage: (data) ->
    try
      data.name ?= me?.broadName()
      data.email ?= me?.get('email')
    catch e
      data.lookupError = e
    jqxhr = $.ajax type: 'POST', url: '/contact/slacklog', data: data
    return new Promise(jqxhr.then)
