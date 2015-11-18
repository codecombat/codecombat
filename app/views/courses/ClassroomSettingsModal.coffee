ModalView = require 'views/core/ModalView'
template = require 'templates/courses/classroom-settings-modal'

module.exports = class AddLevelSystemModal extends ModalView
  id: 'classroom-settings-modal'
  template: template
  
  events:
    'click #save-settings-btn': 'onClickSaveSettingsButton'

  initialize: (options) ->
    @classroom = options.classroom

  onClickSaveSettingsButton: ->
    return unless @classroom
    if name = $('.settings-name-input').val()
      @classroom.set('name', name)
    description = $('.settings-description-input').val()
    @classroom.set('description', description)
    @classroom.set('aceConfig', {
      language: @$('#programming-language-select').val()
    })
    @classroom.patch()
    @hide()

  