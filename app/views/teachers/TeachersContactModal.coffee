ModalView = require 'views/core/ModalView'
State = require 'models/State'
TrialRequests = require 'collections/TrialRequests'
forms = require 'core/forms'
contact = require 'core/contact'

module.exports = class TeachersContactModal extends ModalView
  id: 'teachers-contact-modal'
  template: require 'templates/teachers/teachers-contact-modal'

  events:
    'submit form': 'onSubmitForm'

  initialize: (options={}) ->
    @state = new State({
      formValues: {
        name: ''
        email: ''
        licensesNeeded: ''
        message: ''
      }
      formErrors: {}
      sendingState: 'standby' # 'sending', 'sent', 'error'
    })
    @trialRequests = new TrialRequests()
    @supermodel.trackRequest @trialRequests.fetchOwn()
    @state.on 'change', @render, @

  onLoaded: ->
    trialRequest = @trialRequests.first()
    props = trialRequest?.get('properties') or {}
    name = if props.firstName and props.lastName then "#{props.firstName} #{props.lastName}" else me.get('name') ? ''
    email = props.email or me.get('email') or ''
    message = """
        Hi CodeCombat! I want to learn more about the Classroom experience and get licenses so that my students can access Computer Science 2 and on.

        Name of School/District: #{props.organization or ''}
        Role: #{props.role or ''}
        Phone Number: #{props.phoneNumber or ''}
      """
    @state.set('formValues', { name, email, message })
    super()

  onSubmitForm: (e) ->
    e.preventDefault()
    return if @state.get('sendingState') is 'sending'

    formValues = forms.formToObject @$el
    @state.set('formValues', formValues)

    formErrors = {}
    unless formValues.name
      formErrors.name = 'Name required.'
    unless forms.validateEmail(formValues.email)
      formErrors.email = 'Invalid email.'
    unless parseInt(formValues.licensesNeeded) > 0
      formErrors.licensesNeeded = 'Licenses needed is required.'
    unless formValues.message
      formErrors.message = 'Message required.'
    @state.set({ formErrors, formValues, sendingState: 'standby' })
    return unless _.isEmpty(formErrors)

    @state.set('sendingState', 'sending')
    data = _.extend({ country: me.get('country') }, formValues)
    contact.send({
      data
      context: @
      success: ->
        @state.set({ sendingState: 'sent' })
        me.set('enrollmentRequestSent', true)
        setTimeout(=>
          @hide?()
        , 3000)
      error: -> @state.set({ sendingState: 'error' })
    })

