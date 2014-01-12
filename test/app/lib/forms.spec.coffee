describe 'forms library', ->
  forms = require 'lib/forms'
  Router = require 'lib/Router'
  #it 'adds errors to the create account form', ->
  #  router = new Router()
  #  router.openRoute('home')
  #
  #  # doesn't work
  #  console.log "going to click", $('button[data-target="modal/signup"]').click().length, "signup buttons"
  #  forms.applyErrorsToForm($('#signup-modal'), [message:"is bad", property:"email"])
  #  messages = $('#signup-modal .help-inline')
  #  expect(messages.length).toBe(1)
  #  expect($('#signup-modal .error').length).toBe(1)
  #  expect(messages.text()).toBe('Email is bad.')
  #
  #it 'clears errors from the create account form', ->
  #  expect($('#signup-modal .help-inline').length).toBe(1)
  #  expect($('#signup-modal .error').length).toBe(1)
  #  forms.clearFormAlerts($('#signup-modal'))
  #  expect($('#signup-modal .help-inline').length).toBe(0)
  #  expect($('#signup-modal .error').length).toBe(0)