// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18NEditAchievementView
const I18NEditModelView = require('./I18NEditModelView')
const Achievement = require('models/Achievement')

module.exports = (I18NEditAchievementView = (function () {
  I18NEditAchievementView = class I18NEditAchievementView extends I18NEditModelView {
    static initClass () {
      this.prototype.id = 'i18n-edit-achievement-view'
      this.prototype.modelClass = Achievement
    }

    buildTranslationList () {
      let i18n
      const lang = this.selectedLanguage

      // name, description
      if (i18n = this.model.get('i18n')) {
        let description, name
        if (name = this.model.get('name')) {
          this.wrapRow('Achievement name', ['name'], name, i18n[lang] != null ? i18n[lang].name : undefined, [])
        }
        if (description = this.model.get('description')) {
          return this.wrapRow('Achievement description', ['description'], description, i18n[lang] != null ? i18n[lang].description : undefined, [])
        }
      }
    }
  }
  I18NEditAchievementView.initClass()
  return I18NEditAchievementView
})())
