module.exports.formToObject = (el) ->
  obj = {}

  inputs = $('input', el).add('textarea', el)
  for input in inputs
    input = $(input)
    obj[input.attr('name')] = input.val()

  obj

module.exports.applyErrorsToForm = (el, errors) ->
  errors = [errors] if not $.isArray(errors)
  missingErrors = []
  for error in errors
    if error.dataPath
      prop = error.dataPath[1..]
      message = error.message
      
    else
      message = "#{error.property} #{error.message}."
      message = message[0].toUpperCase() + message[1..]
      message = error.message if error.formatted
      prop = error.property
      
    input = $("[name='#{prop}']", el)
    if not input[0]
      missingErrors.push(error)
      continue
    controls = input.closest('.controls')
    controls.append($("<span class='help-inline error-inline'>#{message}</span>"))
    group = controls.closest('.control-group')
    group.addClass('error')
  return missingErrors

module.exports.clearFormAlerts = (el) ->
  $('.error', el).removeClass('error')
  $('.error-inline', el).remove()
  $('.alert', el).remove()