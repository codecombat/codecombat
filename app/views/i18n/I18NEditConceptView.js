const I18NEditModelView = require('./I18NEditModelView')
const Concept = require('models/Concept')

class I18NEditConcept extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      const name = this.model.get('name')
      const description = this.model.get('description')
      if (name) {
        this.wrapRow('Label / Name', ['name'], name, i18n[lang]?.name, [])
      }
      if (description) {
        this.wrapRow('Concept description', ['description'], description, i18n[lang]?.description, [], 'markdown')
      }
    }
  }
}

I18NEditConcept.prototype.id = 'i18n-edit-concept-view'
I18NEditConcept.prototype.modelClass = Concept

module.exports = I18NEditConcept
