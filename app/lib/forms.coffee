module.exports.formToObject = (el) ->
  obj = {}

  inputs = $('input', el).add('textarea', el)
  for input in inputs
    input = $(input)
    continue unless name = input.attr('name')
    obj[name] = input.val()

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
    if not input.length
      missingErrors.push(error)
      continue
    formGroup = input.closest('.form-group')
    formGroup.addClass 'has-error'
    formGroup.append($("<span class='help-block error-help-block'>#{message}</span>"))
  return missingErrors

module.exports.clearFormAlerts = (el) ->
  $('.has-error', el).removeClass('has-error')
  $('.alert.alert-danger', el).remove()
  el.find('.help-block.error-help-block').remove()