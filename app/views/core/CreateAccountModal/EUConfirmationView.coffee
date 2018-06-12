require('app/styles/modal/create-account-modal/eu-confirmation-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/core/create-account-modal/eu-confirmation-view'
forms = require 'core/forms'
Classroom = require 'models/Classroom'
State = require 'models/State'

module.exports = class EUConfirmationView extends CocoView
  id: 'eu-confirmation-view'
  template: template

  events:
    'click .back-button': -> @trigger 'nav-back'
    'click .forward-button': -> @trigger 'nav-forward'
    'change #eu-confirmation-checkbox': 'onChangeEUConfirmationCheckbox'

  initialize: ({ @signupState } = {}) ->
    @state = new State()

  onChangeEUConfirmationCheckbox: (e) ->
    @state.set 'euConfirmationGranted', $(e.target).is ':checked'
    @$('.forward-button').attr 'disabled', not $(e.target).is ':checked'
