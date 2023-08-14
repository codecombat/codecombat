const I18NEditModelView = require('./I18NEditModelView')
const StandardsCorrelation = require('models/StandardsCorrelation')

class I18NEditStandardsView extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      const name = this.model.get('name')
      if (name) {
        this.wrapRow('Label / Name', ['name'], name, i18n[lang]?.name, [])
      }
    }
  }
}

I18NEditStandardsView.prototype.id = 'i18n-edit-standards-view'
I18NEditStandardsView.prototype.modelClass = StandardsCorrelation

module.exports = I18NEditStandardsView
