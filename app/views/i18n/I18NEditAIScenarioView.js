const I18NEditModelView = require('./I18NEditModelView')
const AIScenario = require('models/AIScenario')
const AIChatMessage = require('models/AIChatMessage')
const CocoCollection = require('collections/CocoCollection')

class I18NEditAIScenario extends I18NEditModelView {
  constructor (options, modelHandle) {
    super(options, modelHandle)

    this.actionQueue = []
    this.listenToOnce(this.model, 'sync', () => {
      for (const actionId of this.model.get('initialActionQueue') || []) {
        this.fetchAndwrapInitalActionQueue(actionId)
      }
    })
  }

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

    for (const q of this.actionQueue) {
      this.translationList.push(q)
    }
  }

  fetchAndwrapInitalActionQueue (id) {
    const chatMessageCollection = new CocoCollection([], {
      url: '/db/ai_chat_message',
      project: ['actor', 'text'],
      model: AIChatMessage
    })
    this.supermodel.trackRequest(chatMessageCollection.fetch({ url: `/db/ai_chat_message/${id}` }))
    chatMessageCollection.once('sync', () => {
      const data = chatMessageCollection.models[0].attributes
      this.actionQueue.push({ title: 'InitialActionQueue', enValue: `${data.actor}: ${data.text}`, format: 'url', link: '/i18n/ai/chat_message/' + id })
    })
  }
}

I18NEditAIScenario.prototype.id = 'i18n-edit-ai-scenario-view'
I18NEditAIScenario.prototype.modelClass = AIScenario

module.exports = I18NEditAIScenario
