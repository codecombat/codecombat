const I18NEditModelView = require('./I18NEditModelView')
const AIJuniorScenario = require('models/AIJuniorScenario')

class I18NEditAIJuniorScenario extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      const name = this.model.get('name')
      const description = this.model.get('description')
      if (name) {
        this.wrapRow('Scenario Name', ['name'], name, i18n[lang]?.name, [])
      }
      if (description) {
        this.wrapRow('Scenario Description', ['description'], description, i18n[lang]?.description, [], 'markdown')
      }
    }

    for (const [inputIndex, input] of (this.model.get('inputs') || []).entries()) {
      if (input.i18n) {
        if (input.label) {
          this.wrapRow(`Input ${input.id} Label`, ['label'], input.label, input.i18n[lang]?.label, ['inputs', inputIndex])
        }
        if (input.text) {
          this.wrapRow(`Input ${input.id} Text`, ['text'], input.text, input.i18n[lang]?.text, ['inputs', inputIndex], 'markdown')
        }
      }

      for (const [choiceIndex, choice] of (input.choices || []).entries()) {
        if (choice.i18n && choice.text) {
          this.wrapRow(`Input ${input.id} choice ${choice.id} text`, ['text'], choice.text, choice.i18n[lang]?.text, ['inputs', inputIndex, 'choices', choiceIndex], 'markdown')
        }
      }
    }

    for (const [promptIndex, prompt] of (this.model.get('prompts') || []).entries()) {
      if (prompt.i18n) {
        if (prompt.text) {
          this.wrapRow(`Prompt ${prompt.id} Text`, ['text'], prompt.text, prompt.i18n[lang]?.text, ['prompts', promptIndex], 'markdown')
        }
        if (prompt.exampleResponse) {
          this.wrapRow(`Prompt ${prompt.id} ExampleResponse`, ['exampleResponse'], prompt.exampleResponse, prompt.i18n[lang]?.exampleResponse, ['prompts', promptIndex])
        }
        if (prompt.exampleImage) {
          this.wrapRow(`Prompt ${prompt.id} ExampleImage`, ['exampleImage'], prompt.exampleImage, prompt.i18n[lang]?.exampleImage, ['prompts', promptIndex])
        }
      }
    }
  }
}

I18NEditAIJuniorScenario.prototype.id = 'i18n-edit-ai-junior-scenario-view'
I18NEditAIJuniorScenario.prototype.modelClass = AIJuniorScenario

module.exports = I18NEditAIJuniorScenario
