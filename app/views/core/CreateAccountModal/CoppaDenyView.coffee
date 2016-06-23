ModalView = require 'views/core/ModalView'
State = require 'models/State'
template = require 'templates/core/create-account-modal/coppa-deny-view'
forms = require 'core/forms'

module.exports = class SegmentCheckView extends ModalView
  id: 'coppa-deny-view'
  template: template

  events:
    'click .send-parent-email-button': 'onClickSendParentEmailButton'
    'input input[name="parentEmail"]': 'onInputParentEmail'

  initialize: ({ @sharedState } = {}) ->
    @state = new State({ parentEmail: '' })
    @listenTo @state, 'all', -> @renderSelectors('.render')
    
  onInputParentEmail: (e) ->
    @state.set { parentEmail: $(e.currentTarget).val() }, { silent: true }

  onClickSendParentEmailButton: (e) ->
    e.preventDefault()
    @state.set({ parentEmailSending: true })
    $.ajax('/send-parent-signup-instructions', {
      method: 'POST'
      data:
        parentEmail: @state.get('parentEmail')
      success: =>
        @state.set({ error: false, parentEmailSent: true, parentEmailSending: false })
      error: =>
        @state.set({ error: true, parentEmailSent: false, parentEmailSending: false })
    })
