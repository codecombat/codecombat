// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIScenarioEditView
require('app/styles/editor/ai-scenario/edit.sass')
const RootView = require('views/core/RootView')
const VersionHistoryView = require('./AIScenarioVersionsModal')
const template = require('app/templates/editor/ai-scenario/edit')
const AIScenario = require('models/AIScenario')
const SaveVersionModal = require('views/editor/modal/SaveVersionModal')
const PatchesView = require('views/editor/PatchesView')
const ConfirmModal = require('views/core/ConfirmModal')
const AITranslateConfirmModal = require('views/editor/modal/AITranslateConfirmModal')

const nodes = require('views/editor/level/treema_nodes')

require('views/modal/RevertModal')
const RevertModal = require('views/modal/RevertModal')
require('lib/game-libraries')
require('lib/setupTreema')
const treemaExt = require('core/treema-ext')

module.exports = (AIScenarioEditView = (function () {
  AIScenarioEditView = class AIScenarioEditView extends RootView {
    static initClass () {
      this.prototype.id = 'editor-ai-scenario-edit-view'
      this.prototype.template = template

      this.prototype.events = {
        'click #history-button': 'showVersionHistory',
        'click [data-toggle="coco-modal"][data-target="modal/RevertModal"]': 'openRevertModal',
        'click #save-button': 'openSaveModal',
        'click #i18n-button': 'onPopulateI18N',
        'click #delete-button': 'confirmDeletion',
        'click #fix-button': 'onFix',
        'click #diff-button': 'onAddDiff',
        'click #ai-translate-button': 'onAITranslate',
      }
    }

    constructor (options, scenarioID) {
      super(options)
      this.onChange = this.onChange.bind(this)
      this.deleteAIScenario = this.deleteAIScenario.bind(this)
      this.scenarioID = scenarioID
      this.scenario = new AIScenario({ _id: this.scenarioID })
      this.scenario.saveBackups = true
      this.supermodel.loadModel(this.scenario)
    }

    onLoaded () {
      super.onLoaded()
      this.buildTreema()
      return this.listenTo(this.scenario, 'change', () => {
        this.scenario.updateI18NCoverage()
        return this.treema.set('/', this.scenario.attributes)
      })
    }

    buildTreema () {
      if ((this.treema != null) || (!this.scenario.loaded)) { return }
      const data = $.extend(true, {}, this.scenario.attributes)
      const copySchema = $.extend(true, {}, AIScenario.schema)
      if (this.scenario.get('mode') === 'use') {
        copySchema.properties.minMsgs.minimum = 1
        copySchema.properties.minMsgs.default = 1
      }
      const options = {
        data,
        filePath: `db/ai_scenario/${this.scenario.get('original')}`,
        schema: copySchema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'chat-message-link': nodes.ChatMessageLinkNode,
          'prompt-type': nodes.PromptTypeNode,
        },
        callbacks: {
          change: this.onChange,
        },
      }
      this.treema = this.$el.find('#ai-scenario-treema').treema(options)
      this.treema.build()
      return this.treema.open(5)
    }

    afterRender () {
      super.afterRender()
      if (!this.supermodel.finished()) { return }
      if (me.get('anonymous')) { this.showReadOnly() }
      this.patchesView = this.insertSubView(new PatchesView(this.scenario), this.$el.find('.patches-view'))
      return this.patchesView.load()
    }

    onPopulateI18N () {
      return this.scenario.populateI18N()
    }

    async onAITranslate () {
      // todo: add warning & language modal.
      this.openModalView(new AITranslateConfirmModal(this.scenario))
    }

    onChange () {
      if (!this.treema) { return }
      for (const key in this.treema.data) {
        const value = this.treema.data[key]
        this.scenario.set(key, value)
      }
    }

    openSaveModal () {
      const modal = new SaveVersionModal({ model: this.scenario, noNewMajorVersions: true })
      this.openModalView(modal)
      this.listenToOnce(modal, 'save-new-version', this.saveNewScenario)
      return this.listenToOnce(modal, 'hidden', function () { return this.stopListening(modal) })
    }

    openRevertModal (e) {
      e.stopPropagation()
      return this.openModalView(new RevertModal())
    }

    saveNewScenario (e) {
      this.treema.endExistingEdits()
      for (const key in this.treema.data) {
        const value = this.treema.data[key]
        this.scenario.set(key, value)
      }
      const additionalSystemPrompts = this.scenario.get('additionalSystemPrompts')
      if (additionalSystemPrompts?.length < 1) {
        this.scenario.unset('additionalSystemPrompts')
      }
      this.scenario.updateI18NCoverage()

      this.scenario.set('commitMessage', e.commitMessage)
      const res = this.scenario.saveNewMinorVersion()

      const modal = this.$el.find('#save-version-modal')
      this.enableModalInProgress(modal)

      res.error((collection, response, options) => {
        return this.disableModalInProgress(modal)
      })

      return res.success(() => {
        this.scenario.clearBackup()
        modal.modal('hide')
        const url = `/editor/ai-scenario/${this.scenario.get('slug') || this.scenario.id}`
        return document.location.href = url
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
      confirmModal.on('confirm', this.deleteAIScenario)
      return this.openModalView(confirmModal)
    }

    deleteAIScenario () {
      return $.ajax({
        type: 'DELETE',
        success () {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          })
          return _.delay(() => application.router.navigate('/editor/ai-scenario', { trigger: true })
            , 500)
        },
        error (jqXHR, status, error) {
          console.error(jqXHR)
          return {
            timeout: 5000,
            text: `Deleting scenario message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          }
        },
        url: `/db/ai_scenario/${this.scenario.id}`
      })
    }

    showVersionHistory (e) {
      const versionHistoryView = new VersionHistoryView({ scenario: this.scenario }, this.scenarioID)
      this.openModalView(versionHistoryView)
      return Backbone.Mediator.publish('editor:view-switched', {})
    }
  }
  AIScenarioEditView.initClass()
  return AIScenarioEditView
})())
