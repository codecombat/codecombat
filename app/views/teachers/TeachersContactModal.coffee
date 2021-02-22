require('app/styles/teachers/teachers-contact-modal.sass')
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
        licensesNeeded: 0
        message: ''
      }
      formErrors: {}
      sendingState: 'standby' # 'sending', 'sent', 'error'
    })
    @trialRequests = new TrialRequests()
    @supermodel.trackRequest @trialRequests.fetchOwn()
    @state.on 'change', @render, @

  onLoaded: ->
    try
      trialRequest = @trialRequests.first()
      props = trialRequest?.get('properties') or {}
      name = if props.firstName and props.lastName then "#{props.firstName} #{props.lastName}" else me.get('name') ? ''
      email = me.get('email') or props.email or ''
      message = """
        Hi CodeCombat! I want to learn more about the Classroom experience and get licenses so that my students can access Computer Science 2 and on.

        Name of School #{props.nces_name or props.organization or ''}
        Name of District: #{props.nces_district or props.district or ''}
        Role: #{props.role or ''}
        Phone Number: #{props.phoneNumber or ''}
      """
      @state.set('formValues', { name, email, message })
      @logContactFlowToSlack({
        event: 'Done loading',
        message: "name: #{name}, email: #{email}, trialRequest: #{trialRequest._id}"
      })
    catch e
      @logContactFlowToSlack({
        event: 'Done loading',
        error: e
      })
      console.error(e)

    super()

  onSubmitForm: (e) ->
    try
      @logContactFlowToSlack({
        event: 'Submitting',
        message: "Beginning. sendingState: #{@state.get('sendingState')}"
      })
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

      @logContactFlowToSlack({
        event: 'Submitting',
        message: "Validating. name: #{formErrors.name or formValues.name}, email: #{formErrors.email or formValues.email}, licensesNeeded: #{formErrors.licensesNeeded or formValues.licensesNeeded}, message: #{formErrors.message or formValues.message}"
      })

      return unless _.isEmpty(formErrors)

      @state.set('sendingState', 'sending')
      data = _.extend({ country: me.get('country') }, formValues)
      @logContactFlowToSlack({
        event: 'Submitting',
        message: "Sending. email: #{formValues.email}"
      })
      contact.send({
        data
        context: @
        success: ->
          @logContactFlowToSlack({
            event: 'Submitting',
            message: "Successfully sent. email: #{formValues.email}"
          })
          window.tracker?.trackEvent 'Teacher Contact',
            category: 'Contact',
            licensesNeeded: formValues.licensesNeeded
          @state.set({ sendingState: 'sent' })
          setTimeout(=>
            @hide?()
          , 3000)
        error: ->
          @logContactFlowToSlack({
            event: 'Submitting',
            message: "Error sending! email: #{formValues.email}"
          })
          @state.set({ sendingState: 'error' })
      })

      @trigger('submit')
    catch e
      @logContactFlowToSlack({
        event: 'Submitting',
        message: "General error! error: #{e}"
      })

  logContactFlowToSlack: (data) ->
    logUrl = '/contact/slacklog'
    # /teachers/licenses and /teachers/starter-licenses
    if window?.location?.pathname?.endsWith('licenses')
      logUrl = '/db/trial.request.slacklog'

    try
      data.name = me.broadName()
      data.email = me.get('email')
    catch e
      data.lookupError = e

    $.ajax({
      type: 'POST',
      url: logUrl,
      data
    })
