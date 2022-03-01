require('app/styles/modal/recover-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/core/recover-modal'
forms = require 'core/forms'
{genericFailure} = require 'core/errors'

filterKeyboardEvents = (allowedEvents, func) ->
  return (splat...) ->
    e = splat[0]
    return unless e.keyCode in allowedEvents or not e.keyCode
    return func(splat...)

module.exports = class RecoverModal extends ModalView
  id: 'recover-modal'
  template: template

  events:
    'click #recover-button': 'recoverAccount'
    'keydown input': 'recoverAccount'

  subscriptions:
    'errors:server-error': 'onServerError'

  onServerError: (e) -> # TODO: work error handling into a separate forms system
    @disableModalInProgress(@$el)

  constructor: (options) ->
    @recoverAccount = filterKeyboardEvents([13], @recoverAccount) # TODO: part of forms
    super options

  recoverAccount: (e) =>
    @playSound 'menu-button-click'
    forms.clearFormAlerts(@$el)
    email = (forms.formToObject @$el).email
    return unless email
    res = $.post '/auth/reset', {email: email}, @successfullyRecovered
    res.fail(genericFailure)
    @enableModalInProgress(@$el)

  successfullyRecovered: =>
    @disableModalInProgress(@$el)
    @$el.find('.modal-body:visible').text($.i18n.t('recover.recovery_sent'))
    @$el.find('.modal-footer').remove()
