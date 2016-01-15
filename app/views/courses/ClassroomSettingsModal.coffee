Classroom = require 'models/Classroom'
ModalView = require 'views/core/ModalView'
template = require 'templates/courses/classroom-settings-modal'

module.exports = class AddLevelSystemModal extends ModalView
  id: 'classroom-settings-modal'
  template: template

  events:
    'click #save-settings-btn': 'onClickSaveSettingsButton'

  initialize: (options) ->
    @classroom = options.classroom
    if @classroom
      application.tracker?.trackEvent 'Classroom started edit settings', category: 'Courses', classroomID: @classroom.id
    else
      application.tracker?.trackEvent 'Create new class', category: 'Courses'

  afterRender: ->
    super()
    disableLangSelect = @classroom?.get('members')?.length > 0
    @$('#programming-language-select').prop('disabled', disableLangSelect)
    @$('.language-locked').toggle(disableLangSelect)

  onClickSaveSettingsButton: ->
    name = $('.settings-name-input').val()
    unless @classroom
      return unless name
      @classroom = new Classroom({ name: name })
    if name
      @classroom.set('name', name)
    description = $('.settings-description-input').val()
    @classroom.set('description', description)
    @classroom.set('aceConfig', {
      language: @$('#programming-language-select').val()
    })
    @classroom.save()
    @hide()
