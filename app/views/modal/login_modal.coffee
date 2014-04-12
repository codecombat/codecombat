View = require 'views/kinds/ModalView'
template = require 'templates/modal/login'
{loginUser} = require('lib/auth')
forms = require('lib/forms')
User = require 'models/User'

filterKeyboardEvents = (allowedEvents, func) ->
  return (splat...) ->
    e = splat[0]
    return unless e.keyCode in allowedEvents or not e.keyCode
    return func(splat...)

module.exports = class LoginModalView extends View
  id: "login-modal"
  template: template

  events:
    "click #login-button": "loginAccount"
    "keydown #login-password": "loginAccount"

  subscriptions:
    'server-error': 'onServerError'
    'logging-in-with-facebook': 'onLoggingInWithFacebook'

  onServerError: (e) -> # TODO: work error handling into a separate forms system
    @disableModalInProgress(@$el)

  constructor: (options) ->
    @loginAccount = filterKeyboardEvents([13], @loginAccount) # TODO: part of forms
    super options

  onLoggingInWithFacebook: (e) ->
    modal = $('.modal:visible', @$el)
    @enableModalInProgress(modal) # TODO: part of forms

  loginAccount: (e) =>
    forms.clearFormAlerts(@$el)
    userObject = forms.formToObject @$el
    res = tv4.validateMultiple userObject, User.schema
    return forms.applyErrorsToForm(@$el, res.errors) unless res.valid
    @enableModalInProgress(@$el) # TODO: part of forms
    loginUser(userObject)

  afterInsert: ->
    super()
    application.router.renderLoginButtons()
