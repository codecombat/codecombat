errorModalTemplate = require 'templates/core/error'
{applyErrorsToForm} = require 'core/forms'

module.exports.parseServerError = (text) ->
  try
    error = JSON.parse(text) or {message: 'Unknown error.'}
  catch SyntaxError
    error = {message: text or 'Unknown error.'}
  error = error[0] if _.isArray(error)
  error

module.exports.genericFailure = (jqxhr) ->
  Backbone.Mediator.publish('errors:server-error', {response: jqxhr})
  return connectionFailure() if not jqxhr.status

  error = module.exports.parseServerError(jqxhr.responseText)
  message = error.message
  message = error.property + ' ' + message if error.property
  console.warn(jqxhr.status, jqxhr.statusText, error)
  existingForm = $('.form:visible:first')
  if existingForm[0]
    missingErrors = applyErrorsToForm(existingForm, [error])
    for error in missingErrors
      existingForm.append($('<div class="alert alert-danger"></div>').text(error.message))
  else
    res = errorModalTemplate(
      status: jqxhr.status
      statusText: jqxhr.statusText
      message: message
    )
    showErrorModal(res)

module.exports.backboneFailure = (model, jqxhr, options) ->
  module.exports.genericFailure(jqxhr)

module.exports.connectionFailure = connectionFailure = ->
  html = errorModalTemplate(
    status: 0
    statusText: 'Connection Gone'
    message: 'No response from the CoCo servers, captain.'
  )
  showErrorModal(html)

module.exports.showNotyNetworkError = ->
  jqxhr = _.find(arguments, 'promise') # handles jquery or backbone network error (jqxhr is first or second parameter)
  noty({
    text: jqxhr.responseJSON?.message or jqxhr.responseJSON?.errorName or 'Unknown error'
    layout: 'topCenter'
    type: 'error'
    timeout: 5000
    killer: false,
    dismissQueue: true
  })

showErrorModal = (html) ->
  # TODO: make a views/modal/error_modal view for this to use so the template can reuse templates/core/modal-base?
  $('#modal-wrapper').html(html)
  $('.modal:visible').modal('hide')
  $('#modal-error').modal('show')

shownWorkerError = false
  
module.exports.onWorkerError = ->
  # TODO: Improve worker error handling in general
  # TODO: Remove this code when IE11 is deprecated OR Aether is removed.
  
  # Sometimes on IE11, Aether isn't loaded. Handle that error by messaging the user, reloading the page.
  # Note: Edge is also considered 'msie'.
  if (not shownWorkerError) and $.browser.msie and $.browser.versionNumber is 11
    text = 'Explorer failure. Reloading...'
    shownWorkerError = true
    setTimeout((-> document.location.reload()), 5000)
    noty({text, layout: 'topCenter', type: 'error'})
