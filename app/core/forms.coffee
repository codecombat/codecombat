module.exports.formToObject = (el) ->
  obj = {}

  inputs = $('input', el).add('textarea', el)
  for input in inputs
    input = $(input)
    continue unless name = input.attr('name')
    obj[name] = input.val()
    obj[name] = obj[name].trim() if obj[name]?.trim

  obj

module.exports.applyErrorsToForm = (el, errors, warning=false) ->
  errors = [errors] if not $.isArray(errors)
  missingErrors = []
  for error in errors
    if error.dataPath
      prop = error.dataPath[1..]
      console.log prop
      message = error.message

    else
      message = "#{error.property} #{error.message}."
      message = message[0].toUpperCase() + message[1..]
      message = error.message if error.formatted
      prop = error.property

    missingErrors.push error unless setErrorToProperty el, prop, message, warning
  missingErrors

# Returns the jQuery form group element in case of success, otherwise undefined
module.exports.setErrorToField = setErrorToField = (el, message, warning=false) ->
  formGroup = el.closest('.form-group')
  unless formGroup.length
    return console.error el, " did not contain a form group, so couldn't show message:", message

  kind = if warning then 'warning' else 'error'
  formGroup.addClass "has-#{kind}"
  formGroup.append $("<span class='help-block #{kind}-help-block'>#{message}</span>")

module.exports.setErrorToProperty = setErrorToProperty = (el, property, message, warning=false) ->
  input = $("[name='#{property}']", el)
  unless input.length
    return console.error "#{property} not found in", el, "so couldn't show message:", message

  setErrorToField input, message, warning

module.exports.clearFormAlerts = (el) ->
  $('.has-error', el).removeClass('has-error')
  $('.has-warning', el).removeClass('has-warning')
  $('.alert.alert-danger', el).remove()
  $('.alert.alert-warning', el).remove()
  el.find('.help-block.error-help-block').remove()
  el.find('.help-block.warning-help-block').remove()
