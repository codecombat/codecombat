Classroom = require 'models/Classroom'
ModalView = require 'views/core/ModalView'
template = require 'templates/courses/classroom-settings-modal'
forms = require 'core/forms'
errors = require 'core/errors'

module.exports = class ClassroomSettingsModal extends ModalView
  id: 'classroom-settings-modal'
  template: template

  events:
    'click #save-settings-btn': 'onSubmitForm'
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

