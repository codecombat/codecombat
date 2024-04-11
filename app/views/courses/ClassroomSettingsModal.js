// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ClassroomSettingsModal
require('app/styles/courses/classroom-settings-modal.sass')
const Classroom = require('models/Classroom')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/courses/classroom-settings-modal')
const forms = require('core/forms')
const errors = require('core/errors')
const GoogleClassroomHandler = require('core/social-handlers/GoogleClassroomHandler')
const globalVar = require('core/globalVar')
const classroomsApi = require('core/api/classrooms')

const initializeFilePicker = function () {
  if (!globalVar.application.isIPadApp) { return require('core/services/filepicker')() }
}

module.exports = (ClassroomSettingsModal = (function () {
  ClassroomSettingsModal = class ClassroomSettingsModal extends ModalView {
    constructor (...args) {
      super(...args)
      this.onFileChosen = this.onFileChosen.bind(this)
      this.onFileUploaded = this.onFileUploaded.bind(this)
    }

    static initClass () {
      this.prototype.id = 'classroom-settings-modal'
      this.prototype.template = template
      this.prototype.schema = require('schemas/models/classroom.schema')

      this.prototype.events = {
        'click #save-settings-btn': 'onSubmitForm',
        'click #update-courses-btn': 'onClickUpdateCoursesButton',
        'submit form': 'onSubmitForm',
        'click #link-google-classroom-btn': 'onClickLinkGoogleClassroom',
        'click .create-manually': 'onClickCreateManually',
        'click .pick-image-button': 'onPickImage',
        'click #link-lms-classroom-btn': 'onClickLinkLMSClassroom',
        'change #classroom-items': 'onChangeClassroomItems'
      }
    }

    initialize (options) {
      if (options == null) { options = {} }
      this.classroom = options.classroom || new Classroom()
      this.googleClassrooms = me.get('googleClassrooms') || []
      this.lmsClassrooms = []
      this.isGoogleClassroom = false
      this.enableCpp = me.enableCpp()
      this.enableJava = me.enableJava()
      this.enableBlocks = ['python', 'javascript', 'lua'].includes(this.classroom.get('aceConfig')?.language || 'python') && (me.isBetaTester() || me.isAdmin())
      this.uploadFilePath = `db/classroom/${this.classroom.id}`
      initializeFilePicker()
      if (this.shouldShowLMSButton()) {
        classroomsApi.getEdLinkClassrooms().then(resp => {
          this.lmsClassrooms = resp.data
          if (this.showLMSDropDown) {
            this.render()
            $('.class-name').hide()
          }
        })
      }
      this.showLMSDropDown = false
    }

    afterRender () {
      super.afterRender()
      forms.updateSelects(this.$('form'))
    }

    onChangeClassroomItems (e) {
      // Unless we manually change this, we're not saving it, so that we can easily change the schema default later
      this.hasChangedClassroomItems = true
    }

    onSubmitForm (e) {
      this.classroom.notyErrors = false
      e.preventDefault()
      const form = this.$('form')
      forms.clearFormAlerts(form)
      const attrs = forms.formToObject(form, { ignoreEmptyString: false })
      if (attrs.language) {
        attrs.aceConfig = { language: attrs.language }
        delete attrs.language
      } else {
        forms.setErrorToProperty(form, 'language', $.i18n.t('common.required_field'))
        return
      }

      if (!attrs.type && me.isILK()) {
        forms.setErrorToProperty(form, 'type', $.i18n.t('common.required_field'))
        return
      }

      if (attrs.classroomItems && this.hasChangedClassroomItems) {
        attrs.classroomItems = attrs.classroomItems[0] === 'on'
      } else {
        delete attrs.classroomItems
      }

      if (attrs.liveCompletion) {
        attrs.aceConfig.liveCompletion = attrs.liveCompletion[0] === 'on'
        delete attrs.liveCompletion
      }

      if (attrs.codeFormats) {
        attrs.aceConfig.codeFormats = attrs.codeFormats
        delete attrs.codeFormats
      }

      if (attrs.defaultCodeFormat) {
        attrs.aceConfig.codeFormatDefault = attrs.defaultCodeFormat
        delete attrs.defaultCodeFormat
      }

      // Make sure that codeFormats includes defaultCodeFormat, including when these aren't specified
      const codeFormats = attrs.aceConfig.codeFormats || ['text-code']
      const defaultCodeFormat = attrs.aceConfig.codeFormatDefault || 'text-code'
      if (!codeFormats.includes(defaultCodeFormat)) {
        attrs.aceConfig.codeFormats = attrs.aceConfig.codeFormats || codeFormats
        attrs.aceConfig.codeFormats.push(defaultCodeFormat)
      }

      if (attrs.levelChat) {
        attrs.aceConfig.levelChat = attrs.levelChat[0] || 'none'
        delete attrs.levelChat
      }

      if (!this.isGoogleClassroom && !this.showLMSDropDown) {
        delete attrs.googleClassroomId
        delete attrs.lmsClassroomId
      } else if (attrs.googleClassroomId) {
        const gClass = me.get('googleClassrooms').find(c => c.id === attrs.googleClassroomId)
        attrs.name = gClass.name
        delete attrs.lmsClassroomId
      } else if (attrs.lmsClassroomId) {
        attrs.name = this.lmsClassrooms.find(c => c.id === attrs.lmsClassroomId).name
        delete attrs.googleClassroomId
      } else {
        forms.setErrorToProperty(form, 'googleClassroomId', $.i18n.t('common.required_field'))
        return
      }

      this.classroom.set(attrs)
      const schemaErrors = this.classroom.getValidationErrors()
      if (schemaErrors) {
        for (const error of schemaErrors) {
          if (error.schemaPath === '/properties/name/minLength') {
            error.message = 'Please enter a class name.'
          }
        }
        forms.applyErrorsToForm(form, schemaErrors)
        return
      }

      const button = this.$('#save-settings-btn')
      this.oldButtonText = button.text()
      button.text($.i18n.t('common.saving')).attr('disabled', true)
      this.classroom.save()
      this.listenToOnce(this.classroom, 'error', function (model, jqxhr) {
        this.stopListening(this.classroom, 'sync', this.hide)
        button.text(this.oldButtonText).attr('disabled', false)
        errors.showNotyNetworkError(jqxhr)
      })
      this.listenToOnce(this.classroom, 'sync', this.hide)
      window.tracker?.trackEvent('Teachers Edit Class Saved', { category: 'Teachers', classroomID: this.classroom.id })
    }

    onClickUpdateCoursesButton () {
      this.$('#update-courses-btn').attr('disabled', true)
      Promise.resolve(this.classroom.updateCourses())
        .then(() => {
          this.$('#update-courses-btn').attr('disabled', false)
          noty({ text: 'Updated', timeout: 2000 })
        })
        .catch(e => {
          console.log('e', e)
          this.$('#update-courses-btn').attr('disabled', false)
          noty({ text: e.responseJSON?.message || e.responseText || 'Error!', type: 'error', timeout: 5000 })
        })
    }

    shouldShowGoogleClassroomButton () {
      return me.useGoogleClassroom() && this.classroom.isNew()
    }

    shouldShowLMSButton () {
      return me.isEdLinkAccount()
    }

    onClickLinkLMSClassroom () {
      this.showLMSDropDown = true
      this.render()
      return $('.class-name').hide()
    }

    onClickLinkGoogleClassroom () {
      $('#link-google-classroom-btn').text('Linking...')
      $('#link-google-classroom-btn').attr('disabled', true)
      application.gplusHandler.loadAPI({
        success: () => {
          this.linkGoogleClassroom()
        }
      })
    }

    linkGoogleClassroom () {
      this.isGoogleClassroom = true
      GoogleClassroomHandler.importClassrooms()
        .then(() => {
          this.googleClassrooms = me.get('googleClassrooms').filter(c => !c.importedToCoco && !c.deletedFromGC)
          this.render()
          $('.google-class-name').show()
          $('.class-name').hide()
          $('#link-google-classroom-btn').hide()
        })
        .catch(e => {
          noty({ text: e || 'Error in importing classrooms', layout: 'topCenter', type: 'error', timeout: 3000 })
          this.render()
        })
    }

    onClickCreateManually () {
      this.isGoogleClassroom = false
      this.render()
      $('.google-class-name').hide()
      $('.class-name').show()
      $('#link-google-classroom-btn').show()
    }

    onPickImage () {
      filepicker.pick(this.onFileChosen)
    }

    onFileChosen (inkBlob) {
      const body = {
        url: inkBlob.url,
        filename: inkBlob.filename,
        mimetype: inkBlob.mimetype,
        path: this.uploadFilePath,
        force: true
      }

      this.uploadingPath = [this.uploadFilePath, inkBlob.filename].join('/')
      $.ajax('/file', { type: 'POST', data: body, success: this.onFileUploaded })
    }

    onFileUploaded (e) {
      const textarea = $('textarea#classroom-announcement')
      textarea.append(`![${e.metadata.name}](/file/${this.uploadingPath})`)
    }
  }
  ClassroomSettingsModal.initClass()
  return ClassroomSettingsModal
})())
