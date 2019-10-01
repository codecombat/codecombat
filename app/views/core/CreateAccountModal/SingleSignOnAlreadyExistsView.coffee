require('app/styles/modal/create-account-modal/sso-already-exists-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/core/create-account-modal/single-sign-on-already-exists-view'
forms = require 'core/forms'
User = require 'models/User'

module.exports = class SingleSignOnAlreadyExistsView extends CocoView
  id: 'single-sign-on-already-exists-view'
  template: template

  events:
    'click .back-button': 'onClickBackButton'

  initialize: ({ @signupState }) ->

  onClickBackButton: ->
    @signupState.set {
      ssoUsed: undefined
      ssoAttrs: undefined
    }
    @trigger('nav-back')
