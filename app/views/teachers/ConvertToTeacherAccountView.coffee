RootView = require 'views/core/RootView'
forms = require 'core/forms'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
AuthModal = require 'views/core/AuthModal'
storage = require 'core/storage'
errors = require 'core/errors'
User = require 'models/User'
ConfirmModal = require 'views/editor/modal/ConfirmModal'
algolia = require 'core/services/algolia'
NCES_KEYS = ['id', 'name', 'district', 'district_id', 'district_schools', 'district_students', 'students', 'phone']

FORM_KEY = 'request-quote-form'

module.exports = class ConvertToTeacherAccountView extends RootView
  id: 'convert-to-teacher-account-view'
  template: require 'templates/teachers/convert-to-teacher-account-view'
  logoutRedirectURL: null

  events:
    'change form': 'onChangeForm'
    'submit form': 'onSubmitForm'
    'click #logout-link': -> me.logout()
    'change input[name="city"]': 'invalidateNCES'
    'change input[name="state"]': 'invalidateNCES'
    'change input[name="district"]': 'invalidateNCES'
    'change input[name="country"]': 'invalidateNCES'

  initialize: ->
    if me.isAnonymous()
      application.router.navigate('/teachers/signup', {trigger: true, replace: true})
      return
    @trialRequest = new TrialRequest()
    @trialRequests = new TrialRequests()
    @trialRequests.fetchOwn()
    @supermodel.trackCollection(@trialRequests)

  invalidateNCES: ->
    for key in NCES_KEYS
      @$('input[name="nces_' + key + '"]').val ''

  onLoaded: ->
    if @trialRequests.size() and me.isTeacher()
      return application.router.navigate('/teachers', { trigger: true, replace: true })
    
    super()

  afterRender: ->
    super()

    # apply existing trial request on form
    properties = @trialRequest.get('properties')
    if properties
      forms.objectToForm(@$('form'), properties)
      commonLevels = _.map @$('[name="educationLevel"]'), (el) -> $(el).val()
      submittedLevels = properties.educationLevel or []
      otherLevel = _.first(_.difference(submittedLevels, commonLevels)) or ''
      @$('#other-education-level-checkbox').attr('checked', !!otherLevel)
      @$('#other-education-level-input').val(otherLevel)

    # apply changes from local storage
    obj = storage.load(FORM_KEY)
    if obj
      @$('#other-education-level-checkbox').attr('checked', obj.otherChecked)
      @$('#other-education-level-input').val(obj.otherInput)
      forms.objectToForm(@$('form'), obj, { overwriteExisting: true })

    $("#organization-control").autocomplete({hint: false}, [
      source: (query, callback) ->
        algolia.schoolsIndex.search(query, { hitsPerPage: 5, aroundLatLngViaIP: false }).then (answer) ->
          callback answer.hits
        , ->
          callback []
      displayKey: 'name',
      templates:
        suggestion: (suggestion) ->
          hr = suggestion._highlightResult
          "<div class='school'> #{hr.name.value} </div>" +
            "<div class='district'>#{hr.district.value}, " +
              "<span>#{hr.city?.value}, #{hr.state.value}</span></div>"

    ]).on 'autocomplete:selected', (event, suggestion, dataset) =>
      @$('input[name="city"]').val suggestion.city
      @$('input[name="state"]').val suggestion.state
      @$('input[name="district"]').val suggestion.district
      @$('input[name="country"]').val 'USA'

      for key in NCES_KEYS
        @$('input[name="nces_' + key + '"]').val suggestion[key]

      @onChangeRequestForm()

  onChangeRequestForm: ->
    # save changes to local storage
    obj = forms.formToObject(@$('form'))
    obj.otherChecked = @$('#other-education-level-checkbox').is(':checked')
    obj.otherInput = @$('#other-education-level-input').val()
    storage.save(FORM_KEY, obj, 10)

  onSubmitForm: (e) ->
    e.preventDefault()

    form = @$('form')
    attrs = forms.formToObject(form)
    
    if @$('#other-education-level-checkbox').is(':checked')
      val = @$('#other-education-level-input').val()
      attrs.educationLevel.push(val) if val

    forms.clearFormAlerts(form)

    result = tv4.validateMultiple(attrs, formSchema)
    error = false
    if not result.valid
      forms.applyErrorsToForm(form, result.errors)
      error = true
    if not _.size(attrs.educationLevel)
      forms.setErrorToProperty(form, 'educationLevel', 'Include at least one.')
      error = true
    if error
      forms.scrollToFirstError()
      return
    attrs['siteOrigin'] = 'convert teacher'
    @trialRequest = new TrialRequest({
      type: 'course'
      properties: attrs
    })
    if me.get('role') is 'student' and not me.isAnonymous()
      modal = new ConfirmModal({
        title: ''
        body: "<p>#{$.i18n.t('teachers_quote.conversion_warning')}</p><p>#{$.i18n.t('teachers_quote.learn_more_modal')}</p>"
        confirm: $.i18n.t('common.continue')
        decline: $.i18n.t('common.cancel')
      })
      @openModalView(modal)
      modal.once 'confirm', @saveTrialRequest, @
    else
      @saveTrialRequest()

  saveTrialRequest: ->
    @trialRequest.notyErrors = false
    @$('#create-account-btn').text('Sending').attr('disabled', true)
    @trialRequest.save()
    @trialRequest.on 'sync', @onTrialRequestSubmit, @
    @trialRequest.on 'error', @onTrialRequestError, @

  onTrialRequestError: (model, jqxhr) ->
    @$('#submit-request-btn').text('Submit').attr('disabled', false)
    errors.showNotyNetworkError(arguments...)

  onTrialRequestSubmit: ->
    me.setRole @trialRequest.get('properties').role.toLowerCase(), true
    storage.remove(FORM_KEY)
    application.router.navigate('/teachers/classes', {trigger: true})

formSchema = {
  type: 'object'
  required: ['firstName', 'lastName', 'organization', 'role', 'numStudents']
  properties:
    firstName: { type: 'string' }
    lastName: { type: 'string' }
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

for key in NCES_KEYS
  formSchema['nces_' + key] = type: 'string'
