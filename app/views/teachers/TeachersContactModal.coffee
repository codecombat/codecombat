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
        email: ''
        message: ''
      }
      formErrors: {}
      sendingState: 'standby' # 'sending', 'sent', 'error'
    })
    @enrollmentsNeeded = options.enrollmentsNeeded or '-'
    @trialRequests = new TrialRequests()
    @supermodel.trackRequest @trialRequests.fetchOwn()
    @state.on 'change', @render, @

  onLoaded: ->
    trialRequest = @trialRequests.first()
    props = trialRequest?.get('properties') or {}
    message = """
        Name of School/District: #{props.organization or ''}
        Your Name: #{props.name || ''}
        Enrollments Needed: #{@enrollmentsNeeded}
        
        Message: Hi CodeCombat! I want to learn more about the Classroom experience and get licenses so that my students can access Computer Science 2 and on. 
      """
    email = props.email or me.get('email') or ''
    @state.set('formValues', { email, message })
    super()

  onSubmitForm: (e) ->
    e.preventDefault()
    return if @state.get('sendingState') is 'sending'
    
    formValues = forms.formToObject @$el
    @state.set('formValues', formValues)
    
    formErrors = {}
    if not forms.validateEmail(formValues.email)
      formErrors.email = 'Invalid email.'
    if not formValues.message
      formErrors.message = 'Message required.'
    @state.set({ formErrors, formValues, sendingState: 'standby' })
    return unless _.isEmpty(formErrors)
    
    @state.set('sendingState', 'sending')
    data = _.extend({ country: me.get('country'), recipientID: 'schools@codecombat.com', enrollmentsNeeded: @enrollmentsNeeded }, formValues)
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

