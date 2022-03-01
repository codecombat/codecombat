require('app/styles/courses/change-course-language-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/courses/change-course-language-modal'

module.exports = class ChangeCourseLanguageModal extends ModalView
  id: 'change-course-language-modal'
  template: template

  events:
    'click .lang-choice-btn': 'onClickLanguageChoiceButton'

  onClickLanguageChoiceButton: (e) ->
    @chosenLanguage = $(e.target).closest('.lang-choice-btn').data('language')
    aceConfig = _.clone(me.get('aceConfig') or {})
    aceConfig.language = @chosenLanguage
    me.set('aceConfig', aceConfig)
    res = me.patch()
    if res
      @$('#choice-area').hide()
      @$('#saving-progress').removeClass('hide')
      @listenToOnce me, 'sync', @onLanguageSettingSaved
    else
      @onLanguageSettingSaved()

  onLanguageSettingSaved: ->
    application.tracker?.trackEvent 'Student changed language', category: 'Courses', label: @chosenLanguage
    @trigger('set-language')
    @hide()
