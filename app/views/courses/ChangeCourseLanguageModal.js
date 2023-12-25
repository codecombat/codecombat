// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ChangeCourseLanguageModal
require('app/styles/courses/change-course-language-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/courses/change-course-language-modal')

module.exports = (ChangeCourseLanguageModal = (function () {
  ChangeCourseLanguageModal = class ChangeCourseLanguageModal extends ModalView {
    static initClass () {
      this.prototype.id = 'change-course-language-modal'
      this.prototype.template = template

      this.prototype.events =
        { 'click .lang-choice-btn': 'onClickLanguageChoiceButton' }
    }

    onClickLanguageChoiceButton (e) {
      this.chosenLanguage = $(e.target).closest('.lang-choice-btn').data('language')
      const aceConfig = _.clone(me.get('aceConfig') || {})
      aceConfig.language = this.chosenLanguage
      me.set('aceConfig', aceConfig)
      const res = me.patch()
      if (res) {
        this.$('#choice-area').hide()
        this.$('#saving-progress').removeClass('hide')
        return this.listenToOnce(me, 'sync', this.onLanguageSettingSaved)
      } else {
        return this.onLanguageSettingSaved()
      }
    }

    onLanguageSettingSaved () {
      if (application.tracker != null) {
        application.tracker.trackEvent('Student changed language', { category: 'Courses', label: this.chosenLanguage })
      }
      this.trigger('set-language')
      return this.hide()
    }
  }
  ChangeCourseLanguageModal.initClass()
  return ChangeCourseLanguageModal
})())
