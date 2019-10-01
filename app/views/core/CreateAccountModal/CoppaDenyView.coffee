require('app/styles/modal/create-account-modal/coppa-deny-view.sass')
CocoView = require 'views/core/CocoView'
State = require 'models/State'
template = require 'templates/core/create-account-modal/coppa-deny-view'
forms = require 'core/forms'
contact = require 'core/contact'

module.exports = class CoppaDenyView extends CocoView
  id: 'coppa-deny-view'
  template: template

  events:
    'click .send-parent-email-button': 'onClickSendParentEmailButton'
    'change input[name="parentEmail"]': 'onChangeParentEmail'
    'click .back-btn': 'onClickBackButton'
    
  initialize: ({ @signupState } = {}) ->
    @state = new State({ parentEmail: '' })
    @listenTo @state, 'all', _.debounce(@render)
    
  onChangeParentEmail: (e) ->
    parentEmail = $(e.currentTarget).val()
    @state.set { parentEmail }, { silent: true }
    if /team@codecombat.com/i.test(parentEmail)
      @state.set { dontUseOurEmailSilly: true }
    else
      @state.set { dontUseOurEmailSilly: false, silent: true }

  onClickSendParentEmailButton: (e) ->
    e.preventDefault()
    @state.set({ parentEmailSending: true })
    window.tracker?.trackEvent 'CreateAccountModal Student CoppaDenyView Send Clicked', category: 'Students'
    contact.sendParentSignupInstructions(@state.get('parentEmail'))
      .then =>
        @state.set({ error: false, parentEmailSent: true, parentEmailSending: false })
      .catch =>
        @state.set({ error: true, parentEmailSent: false, parentEmailSending: false })

  onClickBackButton: ->
    if @signupState.get('path') is 'student'
      window.tracker?.trackEvent 'CreateAccountModal Student CoppaDenyView Back Clicked', category: 'Students'
    @trigger 'nav-back'
