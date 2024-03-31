// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIJuniorScenarioEditView
require('app/styles/editor/ai-junior-scenario/edit.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/editor/ai-junior-scenario/edit')
const AIJuniorScenario = require('models/AIJuniorScenario')
const ConfirmModal = require('views/core/ConfirmModal')

const nodes = require('views/editor/level/treema_nodes')

require('lib/game-libraries')
require('lib/setupTreema')
require('core/treema-ext')

module.exports = (AIJuniorScenarioEditView = (function () {
  AIJuniorScenarioEditView = class AIJuniorScenarioEditView extends RootView {
    static initClass () {
      this.prototype.id = 'editor-ai-junior-scenario-edit-view'
      this.prototype.template = template

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #i18n-button': 'onPopulateI18N',
        'click #delete-button': 'confirmDeletion',
        'click #fix-button': 'onFix',
        'click #diff-button': 'onAddDiff'
      }
    }

    constructor (options, scenarioID) {
      super(options)
      this.deleteAIJuniorScenario = this.deleteAIJuniorScenario.bind(this)
      this.scenarioID = scenarioID
      this.scenario = new AIJuniorScenario({ _id: this.scenarioID })
      this.scenario.saveBackups = true
      this.supermodel.loadModel(this.scenario)
    }

    onLoaded () {
      super.onLoaded()
      this.buildTreema()
      this.listenTo(this.scenario, 'change', () => {
        this.scenario.updateI18NCoverage()
        this.treema.set('/', this.scenario.attributes)
      })
    }

    buildTreema () {
      if ((this.treema != null) || (!this.scenario.loaded)) { return }
      const data = $.extend(true, {}, this.scenario.attributes)
      const options = {
        data,
        filePath: `db/ai_junior__scenario/${this.scenario.get('_id')}`,
        schema: AIJuniorScenario.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'chat-message-link': nodes.ChatMessageLinkNode
        }
      }
      this.treema = this.$el.find('#ai-junior-scenario-treema').treema(options)
      this.treema.build()
      this.treema.open(5)
    }

    onPopulateI18N () {
      this.scenario.populateI18N()
    }

    onClickSaveButton (e) {
      this.treema.endExistingEdits()
      for (const key in this.treema.data) {
        const value = this.treema.data[key]
        this.scenario.set(key, value)
      }
      this.scenario.updateI18NCoverage()

      const res = this.scenario.save()

      res.error((collection, response, options) => {
        console.error(response)
      })

      res.success(() => {
        const url = `/editor/ai-junior-scenario/${this.scenario.get('slug') || this.scenario.id}`
        document.location.href = url
      })
    }

    confirmDeletion () {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the scenario.',
        decline: 'Not really',
        confirm: 'Definitely'
      }

      const confirmModal = new ConfirmModal(renderData)
      confirmModal.on('confirm', this.deleteAIJuniorScenario)
      this.openModalView(confirmModal)
    }

    deleteAIJuniorScenario () {
      $.ajax({
        type: 'DELETE',
        success () {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          })
          _.delay(() => application.router.navigate('/editor/ai-junior-scenario', { trigger: true })
            , 500)
        },
        error (jqXHR, status, error) {
          console.error(jqXHR)
          noty({
            timeout: 5000,
            text: `Deleting scenario message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          })
        },
        url: `/db/ai_junior__scenario/${this.scenario.id}`
      })
    }
  }
  AIJuniorScenarioEditView.initClass()
  return AIJuniorScenarioEditView
})())
