const I18NEditModelView = require('./I18NEditModelView')
const AIChatMessage = require('models/AIChatMessage')

class I18NEditAIChatMessage extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      // TODO: there's lot of i18n stuff that needs to be customized here
      const text = this.model.get('text')
      const preview = this.model.get('preview')
      if (text) {
        this.wrapRow('ChatMessage Text', ['text'], text, i18n[lang]?.text, [])
      }
      if (preview) {
        this.wrapRow('Chat preview', ['preview'], preview, i18n[lang]?.preview, [])
      }
    }

    // post initalActionQueue url here
    const actionData = this.model.get('actionData')
    if (actionData && actionData.choices.length) {
      for (const [index, choice] of actionData.choices.entries()) {
        if (choice.i18n) {
          const choiceI18n = choice.i18n
          if (choiceI18n) {
            this.wrapRow('Choice Text', ['text'], choice.text, choiceI18n[lang]?.text, ['actionData', 'choices', index, 'text'])
            this.wrapRow('Choice Response Text', ['responseText'], choice.responseText, choiceI18n[lang]?.responseText, ['actionData', 'choices', index, 'responseText'])
          }
        }
      }
    }
  }
}

I18NEditAIChatMessage.prototype.id = 'i18n-edit-ai-chat-message-view'
I18NEditAIChatMessage.prototype.modelClass = AIChatMessage

module.exports = I18NEditAIChatMessage
