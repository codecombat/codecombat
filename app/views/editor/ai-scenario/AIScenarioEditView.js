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
const AIScenarioForkModal = require('./AIScenarioForkModal')
const ScenarioScriptPanel = require('./ScenarioScriptPanel.vue').default
const { createScriptStore } = require('lib/scenario-script')

// Settings tab order: identity, catalog tags, AI behaviour, evaluation, translations.
const SETTINGS_ORDER = [
  'name', 'releasePhase', 'archived',
  'mode', 'tool', 'task', 'doc', 'persona', 'labels', 'priority', 'coverImage',
  'promptType', 'additionalSystemPrompts', 'allowFileUpload', 'minMsgs',
  'evaluationRules', 'evaluationPhase',
  'i18n',
]
// Edited elsewhere (the queue, in the Script tab) or maintained by the server.
const SETTINGS_HIDDEN = [
  'initialActionQueue', '_id', '__v', 'index', 'original', 'parent', 'creator', 'created',
  'version', 'commitMessage', 'watchers', 'patches', 'slug', 'i18nCoverage',
]
const template = require('app/templates/editor/ai-scenario/edit')
const AIScenario = require('models/AIScenario')
const ScenarioSaveVersionModal = require('./ScenarioSaveVersionModal')
const PatchesView = require('views/editor/PatchesView')
const ConfirmModal = require('views/core/ConfirmModal')
const fetchJson = require('core/api/fetch-json')
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
      this.prototype.className = 'editor' // full-viewport layout with the editor navbar, like levels and campaigns
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
        'click #fork-button': 'onFork',
        'click #play-button': 'onPlay',
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
        return this.treema.set('/', this.settingsData())
      })
    }

    // What the Settings treema shows: the scenario without the queue (Script tab)
    // and without server bookkeeping. Keys left out stay on the model untouched.
    settingsData () {
      return _.omit($.extend(true, {}, this.scenario.attributes), SETTINGS_HIDDEN)
    }

    buildTreema () {
      if ((this.treema != null) || (!this.scenario.loaded)) { return }
      const data = this.settingsData()
      const copySchema = $.extend(true, {}, AIScenario.schema)
      // Treema lists properties in schema order: name first, then by how often they matter.
      const ordered = {}
      for (const key of SETTINGS_ORDER) { if (copySchema.properties[key]) { ordered[key] = copySchema.properties[key] } }
      for (const key of Object.keys(copySchema.properties)) { if (!ordered[key] && !SETTINGS_HIDDEN.includes(key)) { ordered[key] = copySchema.properties[key] } }
      copySchema.properties = ordered
      copySchema.required = (copySchema.required || []).filter(key => !SETTINGS_HIDDEN.includes(key))
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
      this.patchesView.load()
      return this.mountScriptPanel()
    }

    // The Script tab: a Vue panel over lib/scenario-script. Mounted once; a
    // re-render of this view puts the same panel back (ModalComponent pattern).
    mountScriptPanel () {
      const mountPoint = this.$el.find('#scenario-script-panel')
      if (!mountPoint.length) { return }
      if (this.scriptPanel) {
        mountPoint.replaceWith(this.scriptPanel.$el)
        return
      }
      this.scriptStore = createScriptStore({ scenario: this.scenario.attributes })
      this.scriptPanel = new ScenarioScriptPanel({
        el: mountPoint[0],
        propsData: {
          store: this.scriptStore,
          readOnly: Boolean(me.get('anonymous')),
          releasePhase: this.scenario.get('releasePhase') || 'draft',
          mode: this.scenario.get('mode') || '',
        },
      })
      this.scriptPanel.$on('save', () => this.openSaveModal())
      this.scriptStore.load().catch(err => {
        noty({ type: 'error', text: `Could not load the script: ${err.message || err}`, timeout: 8000 })
      })
    }

    destroy () {
      if (this.scriptPanel) {
        this.scriptPanel.$destroy()
        this.scriptPanel = null
      }
      return super.destroy()
    }

    // Play the saved script as a player: one live project per scenario per user, like the
    // planet, so a second click restarts that project instead of adding another.
    async onPlay () {
      if (this.playPending) { return }
      // Open the tab inside the click; a tab opened after the awaits gets popup-blocked.
      const playTab = window.open('', '_blank')
      if (!playTab) {
        noty({ type: 'error', text: 'The browser blocked the play tab. Allow pop-ups for this site, then click Play again.' })
        return
      }
      this.playPending = true
      this.$('#play-button').prop('disabled', true)
      try {
        const original = this.scenario.get('original')
        const projects = await fetchJson('/db/ai_project?project=scenario,archived&limit=1000&sort=-_id')
        const scenarioOf = (p) => String(p.scenario && p.scenario.original ? p.scenario.original : p.scenario)
        const existing = (projects || []).find(p => !p.archived && scenarioOf(p) === String(original))
        let projectId = existing ? await this.restartProject(existing._id) : null
        if (!projectId) {
          projectId = await fetchJson('/db/ai_project', { method: 'POST', json: { scenarioOriginal: original } })
        }
        projectId = typeof projectId === 'string' ? projectId : projectId && projectId._id
        if (!projectId) { throw new Error('no project id in the response') }
        const url = `/ai/play/project/${projectId}`
        playTab.location.href = url
      } catch (err) {
        playTab.close()
        noty({ type: 'error', text: `Play failed: ${err.message || err} (${err.code || 'network'})` })
      } finally {
        this.playPending = false
        this.$('#play-button').prop('disabled', false)
      }
    }

    // A restart answers 403 when the project was archived meanwhile; fall back to a new project then.
    async restartProject (projectId) {
      try {
        return await fetchJson(`/db/ai_project/${projectId}/restart`, { method: 'POST' })
      } catch (err) {
        if (err.code === 403 || err.code === 404) { return null }
        throw err
      }
    }

    onFork () {
      this.openModalView(new AIScenarioForkModal({ scenario: this.scenario }))
    }

    onPopulateI18N () {
      if (me.get('anonymous')) { return }
      return this.scenario.populateI18N()
    }

    async onAITranslate () {
      if (me.get('anonymous')) { return }
      this.openModalView(new AITranslateConfirmModal(this.scenario))
    }

    onChange () {
      if (!this.treema) { return }
      for (const key in this.treema.data) {
        const value = this.treema.data[key]
        this.scenario.set(key, value)
      }
    }

    // Lines for the save modal: what saveMessages() will write before the version.
    scriptSummary () {
      if (!this.scriptStore) { return [] }
      const c = this.scriptStore.changes()
      if (!c.any) { return [] }
      const t = key => $.i18n.t(`editor.scenario_save_${key}`)
      const steps = this.scriptStore.state.steps
      const firstWords = step => (step.text || '').replace(/\s+/g, ' ').trim().slice(0, 40)
      const lines = []
      for (const step of c.newSteps) { lines.push(`${t('new_step')} ${steps.indexOf(step) + 1}: ${firstWords(step)}`) }
      for (const step of c.editedSteps) { lines.push(`${t('edited_step')} ${steps.indexOf(step) + 1} (${step.id}): ${firstWords(step)}`) }
      for (const id of c.deletedIds) { lines.push(`${t('deleted_message')} ${id}`) }
      if (c.queueChanged) { lines.push(t('queue_changed')) }
      return lines
    }

    openSaveModal () {
      if (me.get('anonymous')) { return }
      const problems = this.scriptStore ? this.scriptStore.validate() : []
      if (problems.length) {
        noty({ type: 'error', text: `${$.i18n.t('editor.scenario_save_fix_first')} ${problems.map(p => `${$.i18n.t('editor.scenario_step_title')} ${p.index + 1}: ${p.message}`).join('; ')}`, timeout: 8000 })
        return
      }
      const scriptSummary = this.scriptSummary()
      const modal = new ScenarioSaveVersionModal({
        model: this.scenario,
        noNewMajorVersions: true,
        scriptSummary,
        commitMessage: scriptSummary.length ? `${$.i18n.t('editor.scenario_script_tab')}: ${this.scriptStore.changes().count} ${$.i18n.t('editor.scenario_script_unsaved')}` : undefined,
      })
      this.openModalView(modal)
      this.listenToOnce(modal, 'save-new-version', this.saveNewScenario)
      return this.listenToOnce(modal, 'hidden', function () { return this.stopListening(modal) })
    }

    openRevertModal (e) {
      e.stopPropagation()
      return this.openModalView(new RevertModal())
    }

    // Messages first (new ones need ids for the queue), then the scenario
    // version. A failed message write stops before the version is saved and
    // the edit stays pending in the Script tab; a failed version save after
    // the messages went through leaves them saved and the queue to retry.
    saveNewScenario (e) {
      const modal = this.$el.find('#save-version-modal')
      this.enableModalInProgress(modal)
      const messages = this.scriptStore ? this.scriptStore.saveMessages() : Promise.resolve(null)
      messages.then(ids => {
        if (ids) { this.scenario.set('initialActionQueue', ids) }
        this.saveScenarioVersion(e, modal)
      }, err => {
        this.disableModalInProgress(modal)
        const index = err.step && this.scriptStore ? this.scriptStore.state.steps.indexOf(err.step) : -1
        const where = index >= 0 ? ` (${$.i18n.t('editor.scenario_step_title')} ${index + 1}, ${err.action || 'write'})` : (err.step && err.step.id ? ` (${err.action || 'write'} ${err.step.id})` : '')
        noty({ type: 'error', text: `${$.i18n.t('editor.scenario_save_failed')}${where}: ${err.message || err}`, timeout: 8000 })
      })
    }

    saveScenarioVersion (e, modal) {
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
