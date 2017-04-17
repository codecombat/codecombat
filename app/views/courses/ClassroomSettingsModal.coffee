Classroom = require 'models/Classroom'
ModalView = require 'views/core/ModalView'
template = require 'templates/courses/classroom-settings-modal'
forms = require 'core/forms'
errors = require 'core/errors'

module.exports = class ClassroomSettingsModal extends ModalView
  id: 'classroom-settings-modal'
  template: template
  schema: require 'schemas/models/classroom.schema'

  events:
    'click #save-settings-btn': 'onSubmitForm'
    'click #update-courses-btn': 'onClickUpdateCoursesButton'
    'submit form': 'onSubmitForm'

  initialize: (options={}) ->
    @classroom = options.classroom or new Classroom()

  afterRender: ->
    super()
    forms.updateSelects(@$('form'))

  onSubmitForm: (e) ->
    @classroom.notyErrors = false
    e.preventDefault()
    form = @$('form')
    forms.clearFormAlerts(form)
    attrs = forms.formToObject(form, ignoreEmptyString: false)
    if attrs.language
      attrs.aceConfig = { language: attrs.language }
      delete attrs.language
    else
      forms.setErrorToProperty(form, 'language', $.i18n.t('common.required_field'))
      return
    
    settings = @classroom.get('settings') or {}
    mayTweak = settings?.optionsEditable or me.isAdmin()
    for k in Object.keys(attrs)
      if /^settings\//.test(k)
        val = (attrs[k].length > 0)
        key = k.substring(9)
        if val isnt @classroom.getSetting key
          settings[key] = val
        delete attrs[k]

    if mayTweak
      attrs.settings = settings
    
    @classroom.set(attrs)
    schemaErrors = @classroom.getValidationErrors()
    if schemaErrors
      for error in schemaErrors
        if error.schemaPath is "/properties/name/minLength"
          error.message = 'Please enter a class name.'
      forms.applyErrorsToForm(form, schemaErrors)
      return

    button = @$('#save-settings-btn')
    @oldButtonText = button.text()
    button.text($.i18n.t('common.saving')).attr('disabled', true)
    @classroom.save()
    @listenToOnce @classroom, 'error', (model, jqxhr) ->
      @stopListening @classroom, 'sync', @hide
      button.text(@oldButtonText).attr('disabled', false)
      errors.showNotyNetworkError(jqxhr)
    @listenToOnce @classroom, 'sync', @hide
    window.tracker?.trackEvent "Teachers Edit Class Saved", category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']

  onClickUpdateCoursesButton: ->
    @$('#update-courses-btn').attr('disabled', true)
    Promise.resolve(@classroom.updateCourses())
    .then =>
      @$('#update-courses-btn').attr('disabled', false)
      noty { text: 'Updated', timeout: 2000 }
    .catch (e) =>
      console.log 'e', e
      @$('#update-courses-btn').attr('disabled', false)
      noty { text: e.responseJSON?.message or e.responseText or 'Error!', type: 'error', timeout: 5000 }
