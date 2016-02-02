RootView = require 'views/core/RootView'
forms = require 'core/forms'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
AuthModal = require 'views/core/AuthModal'

formSchema = {
  type: 'object'
  required: ['name', 'email', 'organization', 'role', 'numStudents']
  properties:
    name: { type: 'string', minLength: 1 }
    email: { type: 'string', format: 'email' }
    phoneNumber: { type: 'string' }
    role: { type: 'string' }
    organization: { type: 'string' }
    city: { type: 'string' }
    state: { type: 'string' }
    country: { type: 'string' }
    numStudents: { type: 'string' }
    educationLevel: {
      type: 'array'
      items: { type: 'string' }
    }
    notes: { type: 'string' }
}

module.exports = class RequestQuoteView extends RootView
  id: 'request-quote-view'
  template: require 'templates/request-quote-view'

  events:
    'submit form': 'onSubmitForm'
    'click #login-btn': 'onClickLoginButton'
    'click #signup-btn': 'onClickSignupButton'

  initialize: ->
    @trialRequest = new TrialRequest()
    @trialRequests = new TrialRequests()
    @trialRequests.fetchOwn()
    @supermodel.loadCollection(@trialRequests)

  onLoaded: ->
    if @trialRequests.size()
      @trialRequest = @trialRequests.first()
    me.setRole 'teacher'
    super()

  onSubmitForm: (e) ->
    e.preventDefault()
    form = @$('form')
    attrs = forms.formToObject(form)
    if @$('#other-education-level-checkbox').is(':checked')
      attrs.educationLevel.push(@$('#other-education-level-input').val())
    forms.clearFormAlerts(form)
    result = tv4.validateMultiple(attrs, formSchema)
    error = true
    if not result.valid
      forms.applyErrorsToForm(form, result.errors)
    else if not /^.+@.+\..+$/.test(attrs.email)
      forms.setErrorToProperty(form, 'email', 'Invalid email.')
    else if not _.size(attrs.educationLevel)
      return forms.setErrorToProperty(form, 'educationLevel', 'Check at least one.')
    else
      error = false
    if error
      forms.scrollToFirstError()
      return
    @trialRequest = new TrialRequest({
      type: 'course'
      properties: attrs
    })
    @$('#submit-request-btn').text('Sending').attr('disabled', true)
    @trialRequest.save()
    @trialRequest.on 'sync', @onTrialRequestSubmit, @
    @trialRequest.on 'error', @onTrialRequestError, @
    me.setRole attrs.role.toLowerCase(), true

  onTrialRequestError: ->
    @$('#submit-request-btn').text('Submit').attr('disabled', false)

  onTrialRequestSubmit: ->
    @$('form, #form-submit-success').toggleClass('hide')

  onClickLoginButton: ->
    modal = new AuthModal({
      mode: 'login'
      initialValues: { email: @trialRequest.get('properties')?.email }
    })
    @openModalView(modal)
    window.nextURL = '/courses/teachers' unless @trialRequest.isNew()

  onClickSignupButton: ->
    props = @trialRequest.get('properties') or {}
    me.set('name', props.name)
    modal = new AuthModal({
      mode: 'signup'
      initialValues: {
        email: props.email
        schoolName: props.organization
      }
    })
    @openModalView(modal)
    window.nextURL = '/courses/teachers' unless @trialRequest.isNew()
