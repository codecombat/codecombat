import I18NEditModelView from './I18NEditModelView';
import ChatMessage from 'models/ChatMessage';

class I18NEditChatMessage extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      // TODO: there's lot of i18n stuff that needs to be customized here
      const name = this.model.get('name')
      const description = this.model.get('description')
      if (name) {
        this.wrapRow('Label / Name', ['name'], name, i18n[lang]?.name, [])
      }

      if (description) {
        this.wrapRow('Chat description', ['description'], description, i18n[lang]?.description, [], 'markdown')
      }
    }
  }
}

I18NEditChatMessage.prototype.id = 'i18n-edit-chat-message-view'
I18NEditChatMessage.prototype.modelClass = ChatMessage

export default I18NEditChatMessage;
