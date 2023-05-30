import I18NEditModelView from './I18NEditModelView';
import Interactive from 'ozaria/site/models/Interactive';

class I18NEditInteractiveView extends I18NEditModelView {
  buildTranslationList () {
    const lang = this.selectedLanguage

    const i18n = this.model.get('i18n')
    if (i18n) {
      const name = this.model.get('name')
      const displayName = this.model.get('displayName')
      const promptText = this.model.get('promptText')
      if (name) {
        this.wrapRow('Short Name / Internal Name', ['name'], name, (i18n[lang] || {}).name, [])
      }
      if (displayName) {
        this.wrapRow('Display Name', ['displayName'], displayName, (i18n[lang] || {}).displayName, [])
      }
      if (promptText) {
        this.wrapRow('Prompt Text', ['promptText'], promptText, (i18n[lang] || {}).promptText, [])
      }
    }

    const articles = (this.model.get('documentation') || {}).specificArticles || []
    for (let articleIndex = 0; articleIndex < articles.length; articleIndex++) {
      const article = articles[articleIndex]
      const { i18n, name, body } = article
      if (i18n && name) {
        this.wrapRow('Article Name', ['name'], name, (i18n[lang] || {}).name, ['documentation', 'specificArticles', articleIndex])
      }
      if (i18n && body) {
        this.wrapRow('Article Body', ['body'], body, (i18n[lang] || {}).body, ['documentation', 'specificArticles', articleIndex])
      }
    }

    if (this.model.get('draggableStatementCompletionData')) {
      const { elements, labels } = this.model.get('draggableStatementCompletionData')
      for (let i = 0; i < (elements || []).length; i++) {
        const { text, i18n } = elements[i] || {}
        if (i18n && text) {
          this.wrapRow('Element Text', ['text'], text, (i18n[lang] || {}).text, ['draggableStatementCompletionData', 'elements', i])
        }
      }
      for (let i = 0; i < (labels || []).length; i++) {
        const { text, i18n } = labels[i] || {}
        if (i18n && text) {
          this.wrapRow('Label Text', ['text'], text, (i18n[lang] || {}).text, ['draggableStatementCompletionData', 'labels', i])
        }
      }
    }
    if (this.model.get('draggableOrderingData')) {
      const { elements, labels } = this.model.get('draggableOrderingData')
      for (let i = 0; i < (elements || []).length; i++) {
        const { text, i18n } = elements[i] || {}
        if (i18n && text) {
          this.wrapRow('Element Text', ['text'], text, (i18n[lang] || {}).text, ['draggableOrderingData', 'elements', i])
        }
      }
      for (let i = 0; i < (labels || []).length; i++) {
        const { text, i18n } = labels[i] || {}
        if (i18n && text) {
          this.wrapRow('Label Text', ['text'], text, (i18n[lang] || {}).text, ['draggableOrderingData', 'labels', i])
        }
      }
    }
  }
}

I18NEditInteractiveView.prototype.id = 'i18n-edit-interactive-view'
I18NEditInteractiveView.prototype.modelClass = Interactive

export default I18NEditInteractiveView;
