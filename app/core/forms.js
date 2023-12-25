// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const tv4 = require('tv4')
let setErrorToField, setErrorToProperty
module.exports.formToObject = function ($el, options) {
  options = _.extend({ trim: true, ignoreEmptyString: true }, options)
  const obj = {}

  const inputs = $('input, textarea, select', $el)
  for (let input of Array.from(inputs)) {
    let name
    input = $(input)
    if (!(name = input.attr('name'))) { continue }
    if (input.attr('type') === 'checkbox') {
      if (obj[name] == null) { obj[name] = [] }
      if (input.is(':checked')) {
        obj[name].push(input.val())
      }
    } else if (input.attr('type') === 'radio') {
      if (!input.is(':checked')) { continue }
      obj[name] = input.val()
    } else {
      let value = input.val() || ''
      if (options.trim) { value = _.string.trim(value) }
      if (value || (!options.ignoreEmptyString)) {
        obj[name] = value
      }
    }
  }
  return obj
}

module.exports.objectToForm = function ($el, obj, options) {
  if (options == null) { options = {} }
  options = _.extend({ overwriteExisting: false }, options)
  const inputs = $('input, textarea, select', $el)
  return (() => {
    const result = []
    for (let input of Array.from(inputs)) {
      let name, value
      input = $(input)
      if (!(name = input.attr('name'))) { continue }
      if (obj[name] == null) { continue }
      if (input.attr('type') === 'checkbox') {
        value = input.val()
        if (_.contains(obj[name], value)) {
          result.push(input.attr('checked', true))
        } else {
          result.push(undefined)
        }
      } else if (input.attr('type') === 'radio') {
        value = input.val()
        if (obj[name] === value) {
          result.push(input.attr('checked', true))
        } else {
          result.push(undefined)
        }
      } else {
        if (options.overwriteExisting || (!input.val())) {
          result.push(input.val(obj[name]))
        } else {
          result.push(undefined)
        }
      }
    }
    return result
  })()
}

module.exports.applyErrorsToForm = function (el, errors, warning) {
  if (warning == null) { warning = false }
  if (!$.isArray(errors)) { errors = [errors] }
  const missingErrors = []
  for (const error of Array.from(errors)) {
    let message, prop
    if (error.code === tv4.errorCodes.OBJECT_REQUIRED) {
      prop = _.last(_.string.words(error.message)) // hack
      message = $.i18n.t('common.required_field')
    } else if (error.dataPath) {
      prop = error.dataPath.slice(1);
      ({
        message
      } = error)
    } else {
      message = `${error.property} ${error.message}.`
      message = message[0].toUpperCase() + message.slice(1)
      if (error.formatted) {
        ({
          message
        } = error)
      }
      prop = error.property
    }

    if (error.code === tv4.errorCodes.FORMAT_CUSTOM) {
      // eslint-disable-next-line no-useless-escape
      const originalMessage = /Format validation failed \(([^\(\)]+)\)/.exec(message)[1]
      if (!_.isEmpty(originalMessage)) {
        message = originalMessage
      }
    }

    if ((error.code === 409) && (error.property === 'email')) {
      message += ' <a class="login-link">Log in?</a>'
    }

    if (!setErrorToProperty(el, prop, message, warning)) { missingErrors.push(error) }
  }
  return missingErrors
}

// Returns the jQuery form group element in case of success, otherwise undefined
module.exports.setErrorToField = (setErrorToField = function (el, message, warning) {
  if (warning == null) { warning = false }
  const formGroup = el.closest('.form-group')
  if (!formGroup.length) {
    return console.error(el, " did not contain a form group, so couldn't show message:", message)
  }

  const kind = warning ? 'warning' : 'error'
  const afterEl = $(formGroup.find('.help-block, .form-control, input, select, textarea, .control-label')[0])
  formGroup.addClass(`has-${kind}`)
  const helpBlock = $(`<span class='help-block ${kind}-help-block'>${message}</span>`)
  if (afterEl.length) {
    return afterEl.before(helpBlock)
  } else {
    return formGroup.append(helpBlock)
  }
})

module.exports.setErrorToProperty = (setErrorToProperty = function (el, property, message, warning) {
  if (warning == null) { warning = false }
  const input = $(`[name='${property}']`, el)
  if (!input.length) {
    return console.error(`${property} not found in`, el, "so couldn't show message:", message)
  }

  return setErrorToField(input, message, warning)
})

module.exports.scrollToFirstError = function ($el) {
  if ($el == null) { $el = $('body') }
  const $first = $el.find('.has-error, .alert-danger, .error-help-block, .has-warning, .alert-warning, .warning-help-block').filter(':visible').first()
  if ($first.length) {
    return $('html, body').animate({ scrollTop: $first.offset().top - 20 }, 300)
  }
}

module.exports.clearFormAlerts = function (el) {
  $('.has-error', el).removeClass('has-error')
  $('.has-warning', el).removeClass('has-warning')
  $('.alert.alert-danger', el).remove()
  $('.alert.alert-warning', el).remove()
  el.find('.help-block.error-help-block').remove()
  return el.find('.help-block.warning-help-block').remove()
}

module.exports.updateSelects = el => el.find('select').each(function (i, select) {
  const value = $(select).attr('value')
  return $(select).val(value)
})

module.exports.validateEmail = function (email) {
  if (!email) { return true } // allow null
  const filter = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,63}$/i // https://news.ycombinator.com/item?id=5763990
  return filter.test(email)
}

module.exports.validatePhoneNumber = function (phoneNumber) {
  const filter = /^\D*(\d\D*){10,}$/i // Just make sure there's at least 10 digits
  return filter.test(phoneNumber)
}

module.exports.disableSubmit = function (el, message) {
  if (message == null) { message = '...' }
  const $el = $(el)
  $el.data('original-text', $el.text())
  return $el.text(message).attr('disabled', true)
}

module.exports.enableSubmit = function (el) {
  const $el = $(el)
  return $el.text($el.data('original-text')).attr('disabled', false)
}
