const I18NEditModelView = require('./I18NEditModelView')
const AIScenario = require('models/AIScenario')

class I18NEditAIScenario extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      // TODO: there's lot of i18n stuff that needs to be customized here
      const name = this.model.get('name')
      const description = this.model.get('description')
      const mode = this.model.get('mode')
      const task = this.model.get('task')
      const doc = this.model.get('doc')
      if (name) {
        this.wrapRow('Scenario Name', ['name'], name, i18n[lang]?.name, [])
      }
      if (description) {
        this.wrapRow('Chat description', ['description'], description, i18n[lang]?.description, [], 'markdown')
      }
      if (mode) {
        this.wrapRow('Mode', ['mode'], mode, i18n[lang]?.mode, [])
      }
      if (task) {
        this.wrapRow('Task', ['task'], task, i18n[lang]?.task, [])
      }
      if (doc) {
        this.wrapRow('Documentation', ['doc'], doc, i18n[lang]?.doc, [])
      }
    }

    // post initalActionQueue url here
    // for()
  }
}

I18NEditAIScenario.prototype.id = 'i18n-edit-ai-scenario-view'
I18NEditAIScenario.prototype.modelClass = AIScenario

module.exports = I18NEditAIScenario
