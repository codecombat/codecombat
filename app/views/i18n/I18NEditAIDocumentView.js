const I18NEditModelView = require('./I18NEditModelView')
const AIDocument = require('models/AIDocument')

class I18NEditAIDocument extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      // TODO: there's lot of i18n stuff that needs to be customized here
      const source = this.model.get('source')
      if (source) {
        this.wrapRow('Source Code', ['source'], source, i18n[lang]?.source, [])
      }
    }
  }
}

I18NEditAIDocument.prototype.id = 'i18n-edit-ai-document-view'
I18NEditAIDocument.prototype.modelClass = AIDocument

module.exports = I18NEditAIDocument
