ModalView = require 'views/core/ModalView'
template = require 'templates/core/create-account-modal/single-sign-on-confirm-view'
forms = require 'core/forms'
User = require 'models/User'

module.exports = class SingleSignOnConfirmView extends ModalView
  id: 'single-sign-on-confirm-view'
  template: template

  events:
    null

  initialize: ({ @sharedState } = {}) ->
