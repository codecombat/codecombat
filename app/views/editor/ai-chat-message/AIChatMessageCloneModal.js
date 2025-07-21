const ModalView = require('views/core/ModalView')
const template = require('app/templates/editor/ai-chat-message/clone')
const CocoCollection = require('collections/CocoCollection')
const AIScenario = require('models/AIScenario')
require('lib/setupTreema')
const treemaExt = require('core/treema-ext')
const fetchJson = require('core/api/fetch-json')

const cloneSchema = {
  additionalProperties: false,
  properties: {
    newScenario: {
      title: 'New Scenario',
      description: 'Input scenario id or scenario title to search',
      format: 'scenario',
      links: [{ rel: 'db', href: '/db/ai_scenario/{{$}}', model: 'AIScenario' }],
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
          scenario: ScenarioNode,
        },
      }
      this.treema = this.$el.find('#scenario-search-treema').treema(options)
      this.treema.build()
      return this.treema.open(2)
    }

    onClickSaveButton () {
      const scenarioId = this.treema.data.newScenario
      fetchJson(`/db/ai_chat_message/${this.messageId}/clone`, {
        method: 'POST',
        json: {
          pid: scenarioId,
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

class ScenarioNode extends treemaExt.IDReferenceNode {
  valueClass = 'treema-scenario'
  lastTerm = null
  scenarios = {}
  keyed = false
  ordered = false
  collection = false
  directlyEditable = true

  constructor (...args) {
    super(...args)
    // seems term search for announcement doesn't work well. so
    // here i search for all and filter it locally first.
    // TODO: fix the term search
    this.getSearchResultsEl().empty().append('Searching')
    this.collections = new CocoCollection([], { model: AIScenario })
    this.collections.url = '/db/ai_scenario?project[]=_id&project[]=name&limit=1000'
    this.collections.fetch()
    this.collections.once('sync', this.loadAIScenarios, this)
  }

  loadAIScenarios () {
    this.scenarios = this.collections
    this.searchCallback()
  }

  buildValueForEditing (valEl, data) {
    valEl.html(this.searchValueTemplate)
    const input = valEl.find('input')
    input.focus().keyup(this.search)
    if (data) {
      input.attr('placeholder', this.formatDocument(data))
    }
  }

  searchCallback () {
    const container = this.getSearchResultsEl().detach().empty()
    let first = true
    this.collections.models.forEach(model => {
      const row = $('<div></div>').addClass('treema-search-result-row')
      const text = this.formatDocument(model)
      if (!text) {
        return
      }
      if (first) {
        row.addClass('treema-search-selected')
      }
      first = false
      row.text(text)
      row.data('value', model)
      container.append(row)
    })
    if (!this.collections.models.length) {
      container.append($('<div>No results</div>'))
    }
    this.getValEl().append(container)
  }

  search () {
    const term = this.getValEl().find('input').val()
    if (term === this.lastTerm) {
      return
    }
    this.lastTerm = term
    this.getSearchResultsEl().empty().append('Searching')
    this.collections = new CocoCollection(this.scenarios.filter((scenario) => {
      return scenario.get('_id').toString() === term || scenario.get('name').toLowerCase().includes(term.toLowerCase())
    }), { model: AIScenario })
    this.searchCallback()
  }
}
