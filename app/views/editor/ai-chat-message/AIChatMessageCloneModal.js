const ModalView = require('views/core/ModalView')
const template = require('app/templates/editor/ai-chat-message/clone')
const { HackstackScenarioIDNode } = require('views/editor/ai-scenario/AIScenarioNode')
const fetchJson = require('core/api/fetch-json')
require('lib/setupTreema')

const cloneSchema = {
  additionalProperties: false,
  properties: {
    newScenario: {
      title: 'New Scenario',
      description: 'Input scenario id or scenario title to search',
      format: 'scenario',
      links: [{ rel: 'db', href: '/db/ai_scenario/{{$}}/version', model: 'AIScenario' }],
    },
  },
}

let AIChatMessageCloneView

module.exports = (AIChatMessageCloneView = (function () {
  AIChatMessageCloneView = class AIChatMessageCloneView extends ModalView {
    static initClass () {
      this.prototype.id = 'editor-ai-chat-message-edit-view'
      this.prototype.template = template

      this.prototype.events = {
        'click #clone-modal-confirm-button': 'onClickSaveButton',
      }
    }

    constructor (options = {}) {
      super(options)
      this.messageId = options.messageId
    }

    afterRender () {
      super.afterRender()
      this.buildTreema()
    }

    buildTreema () {
      if ((this.treema != null)) { return }
      const data = {
        newScenario: '',
      }
      const options = {
        data,
        // filePath: `db/ai_chat_message/${this.messageId}`,
        schema: cloneSchema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          scenario: HackstackScenarioIDNode,
        },
      }
      this.treema = this.$el.find('#scenario-search-treema').treema(options)
      this.treema.build()
      return this.treema.open(2)
    }

    onClickSaveButton () {
      const scenarioOriginal = this.treema.data.newScenario
      fetchJson(`/db/ai_chat_message/${this.messageId}/clone`, {
        method: 'POST',
        json: {
          pid: scenarioOriginal,
        },
      }).then((newMessage) => {
        this.hide()
        application.router.navigate(`/editor/ai-chat-message/${newMessage._id}`, { trigger: true })
      }).catch(err => {
        noty({
          type: 'error',
          text: err.message,
        })
      })
    }
  }

  AIChatMessageCloneView.initClass()
  return AIChatMessageCloneView
})())
