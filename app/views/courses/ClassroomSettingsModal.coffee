require('app/styles/courses/classroom-settings-modal.sass')
Classroom = require 'models/Classroom'
ModalView = require 'views/core/ModalView'
template = require 'templates/courses/classroom-settings-modal'
forms = require 'core/forms'
errors = require 'core/errors'
GoogleClassroomHandler = require('core/social-handlers/GoogleClassroomHandler')

module.exports = class ClassroomSettingsModal extends ModalView
  id: 'classroom-settings-modal'
  template: template
  schema: require 'schemas/models/classroom.schema'

  events:
    'click #save-settings-btn': 'onSubmitForm'
    'click #update-courses-btn': 'onClickUpdateCoursesButton'
    'submit form': 'onSubmitForm'
    'click #link-google-classroom-btn': 'onClickLinkGoogleClassroom'
    'click .create-manually': 'onClickCreateManually'

  initialize: (options={}) ->
    @classroom = options.classroom or new Classroom()
    @googleClassrooms = me.get('googleClassrooms') || []
    @isGoogleClassroom = false

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

    if !@isGoogleClassroom
      delete attrs.googleClassroomId
    else if attrs.googleClassroomId
      gClass = me.get('googleClassrooms').find((c)=>c.id==attrs.googleClassroomId)
      attrs.name = gClass.name
    else
      forms.setErrorToProperty(form, 'googleClassroomId', $.i18n.t('common.required_field'))
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

  shouldShowGoogleClassroomButton: ->
    me.useGoogleClassroom() && @classroom.isNew()

  onClickLinkGoogleClassroom: ->
    $('#link-google-classroom-btn').text("Linking...")
    $('#link-google-classroom-btn').attr('disabled', true)
    application.gplusHandler.loadAPI({
      success: =>
        application.gplusHandler.connect({
          scope: GoogleClassroomHandler.scopes
          success: =>
            @linkGoogleClassroom()
          error: =>
            $('#link-google-classroom-btn').text($.i18n.t("courses.link_google_classroom"))
            $('#link-google-classroom-btn').attr('disabled', false)
        })
    })

  linkGoogleClassroom: ->
    @isGoogleClassroom = true
    GoogleClassroomHandler.importClassrooms()
    .then(() =>
      @googleClassrooms = me.get('googleClassrooms').filter((c) => !c.importedToCoco)
      @render()
      $('.google-class-name').show()
      $('.class-name').hide()
      $('#link-google-classroom-btn').hide()
    )
    .catch((e) => 
      noty { text: e or "Error in importing classrooms", layout: 'topCenter', type: 'error', timeout: 3000 }
      @render()
    )


  onClickCreateManually: ->
    @isGoogleClassroom = false
    @render()
    $('.google-class-name').hide()
    $('.class-name').show()
    $('#link-google-classroom-btn').show()