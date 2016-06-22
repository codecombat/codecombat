ModalView = require 'views/core/ModalView'
BasicInfoView = require 'views/core/CreateAccountModal/BasicInfoView'
template = require 'templates/core/create-account-modal/single-sign-on-confirm-view'
forms = require 'core/forms'
User = require 'models/User'

module.exports = class SingleSignOnConfirmView extends BasicInfoView
  id: 'single-sign-on-confirm-view'
  template: template

  events: _.extend {}, BasicInfoView.prototype.events, {
    'click .back-button': ->
      @trigger 'nav-back'
  }

  initialize: ({ @sharedState } = {}) ->
    super(arguments...)

  formSchema: ->
    type: 'object'
    properties:
      name: User.schema.properties.name
    required: ['name']
