require('app/styles/modal/create-account-modal/sso-confirm-view.sass')
CocoView = require 'views/core/CocoView'
BasicInfoView = require 'views/core/CreateAccountModal/BasicInfoView'
template = require 'templates/core/create-account-modal/single-sign-on-confirm-view'
forms = require 'core/forms'
User = require 'models/User'

module.exports = class SingleSignOnConfirmView extends BasicInfoView
  id: 'single-sign-on-confirm-view'
  template: template

  events: _.extend {}, BasicInfoView.prototype.events, {
    'click .back-button': 'onClickBackButton'
  }

  initialize: ({ @signupState } = {}) ->
    super(arguments...)

  afterRender: ->
    super()
    if @signupState.get('path') is 'teacher'
      @$('form').submit()

  onClickBackButton: ->
    @signupState.set {
      ssoUsed: undefined
      ssoAttrs: undefined
    }
    @trigger 'nav-back'


  formSchema: ->
    type: 'object'
    properties:
      name: User.schema.properties.name
    required: []
