CocoView = require 'views/core/CocoView'
State = require 'models/State'
template = require 'templates/core/create-account-modal/confirmation-view'
forms = require 'core/forms'

module.exports = class ConfirmationView extends CocoView
  id: 'confirmation-view'
  template: template

  initialize: ({ @signupState } = {}) ->
