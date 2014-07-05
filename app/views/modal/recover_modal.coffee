View = require 'views/kinds/ModalView'
template = require 'templates/modal/recover'
forms = require 'lib/forms'
{genericFailure} = require 'lib/errors'

filterKeyboardEvents = (allowedEvents, func) ->
  return (splat...) ->
    e = splat[0]
    return unless e.keyCode in allowedEvents or not e.keyCode
    return func(splat...)

module.exports = class RecoverModalView extends View
  id: 'recover-modal'
  template: template

  events:
    'click #recover-button': 'recoverAccount'
    'keydown input': 'recoverAccount'

  subscriptions:
    'server-error': 'onServerError'

  onServerError: (e) -> # TODO: work error handling into a separate forms system
    @disableModalInProgress(@$el)

  constructor: (options) ->
    @recoverAccount = filterKeyboardEvents([13], @recoverAccount) # TODO: part of forms
    super options

  recoverAccount: (e) =>
    forms.clearFormAlerts(@$el)
    email = (forms.formToObject @$el).email
    return unless email
    res = $.post '/auth/reset', {email: email}, @successfullyRecovered
    res.fail(genericFailure)
    @enableModalInProgress(@$el)

  successfullyRecovered: =>
    @disableModalInProgress(@$el)
    @$el.find('.modal-body:visible').text('Recovery email sent.')
    @$el.find('.modal-footer').remove()
