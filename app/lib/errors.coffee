errorModalTemplate = require 'templates/modal/error'
{applyErrorsToForm} = require 'lib/forms'

module.exports.parseServerError = (text) ->
  try
    error = JSON.parse(text) or {message: 'Unknown error.'}
  catch SyntaxError
    error = {message: text or 'Unknown error.'}
  error = error[0] if _.isArray(error)
  error

module.exports.genericFailure = (jqxhr) ->
  Backbone.Mediator.publish('server-error', {response: jqxhr})
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

showErrorModal = (html) ->
  # TODO: make a views/modal/error_modal view for this to use so the template can reuse templates/modal/modal_base?
  $('#modal-wrapper').html(html)
  $('.modal:visible').modal('hide')
  $('#modal-error').modal('show')
