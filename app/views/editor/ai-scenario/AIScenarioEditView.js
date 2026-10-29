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
const { translatedPaths, staleTranslations } = require('lib/stale-translations')
const { loadWorldChain, buildStoryContext } = require('lib/story-world-chain')
const { versionFromSearch, versionLabel, resolveVersion, isStale, editUrl } = require('lib/scenario-version')

// Settings tab order: identity, catalog tags, AI behaviour, evaluation, story, translations.
const SETTINGS_ORDER = [
  'name', 'releasePhase', 'archived',
  'mode', 'tool', 'task', 'doc', 'persona', 'labels', 'priority', 'coverImage',
  'promptType', 'additionalSystemPrompts', 'allowFileUpload', 'minMsgs',
  'evaluationRules', 'evaluationPhase',
  'isStory', 'storyWorld', 'forkOf', 'objectives', 'characters', 'backgrounds',
  'i18n',
]
// Edited elsewhere (the queue, in the Script tab) or maintained by the server.
const SETTINGS_HIDDEN = [
  'initialActionQueue', '_id', '__v', 'index', 'original', 'parent', 'creator', 'created',
  'version', 'commitMessage', 'watchers', 'patches', 'slug', 'i18nCoverage',
]
const template = require('app/templates/editor/ai-scenario/edit')
const AIScenario = require('models/AIScenario')
const SCENARIO_TRANSLATED_PATHS = translatedPaths(AIScenario.schema)
const firstWords = step => (step.text || '').replace(/\s+/g, ' ').trim().slice(0, 40)
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
        'click #discard-script-button': 'onDiscardScript',
        'click .copy-id': 'onCopyId',
      }
    }

    constructor (options, scenarioID) {
      super(options)
      this.onChange = this.onChange.bind(this)
      this.deleteAIScenario = this.deleteAIScenario.bind(this)
      // Treema fires a change per keystroke; the story context rebuild waits for a pause.
      this.scheduleStoryContext = _.debounce(() => this.refreshStoryContext(), 150)
      this.scenarioID = scenarioID
      this.requestedVersion = this.locationVersion()
      this.scenario = this.supermodel.loadModel(new AIScenario({ _id: this.scenarioID })).model
      // Holds the page until the version to edit is settled, so the Settings treema, the Script
      // tab and Save are all built from that version.
      this.versionResource = this.supermodel.addSomethingResource('scenario-version')
      if (this.scenario.loaded) { this.resolveEditedVersion() } else { this.listenToOnce(this.scenario, 'sync', this.resolveEditedVersion) }
    }

    // The Backbone route drops the query, so ?version=M.m (Version history rows) comes from the location.
    locationVersion () {
      return versionFromSearch(document.location.search)
    }

    // Settle which version this page edits before anything is built from it. The handle resolved
    // to the exact document it names, so an original id (the _id of v0.0) gave v0.0: switch to
    // the latest version and put the slug in the URL, so the save builds on the latest and the
    // Slack link of that save (X-Current-Path) is a slug link too. ?version=M.m loads exactly
    // that version. Any other document is kept. When the check fails the loaded document is kept
    // too and the latest stays unknown, so the Save modal still asks before replacing it.
    resolveEditedVersion () {
      const loaded = this.scenario.attributes
      const load = resolveVersion({ handle: this.scenarioID, loaded, version: this.requestedVersion })
      const versionUrl = `/db/ai_scenario/${loaded.original}/version`
      const latest = fetchJson(versionUrl)
      const target = load === 'exact' ? fetchJson(`${versionUrl}/${this.requestedVersion}`) : latest
      Promise.all([latest, load ? target : null]).then(([latestDoc, targetDoc]) => {
        this.latestVersion = latestDoc
        this.editScenario(targetDoc && isStale(loaded, targetDoc) ? targetDoc : null)
        if (load === 'latest') { window.history.replaceState(window.history.state, '', editUrl(this.scenario.attributes)) }
      }, err => {
        console.warn('Could not settle which scenario version to edit:', err)
        this.versionCheckFailed = true
        this.editScenario(null)
      }).then(() => this.versionResource.markLoaded())
    }

    // Backups are keyed by version id and go on only now: the loaded document must not restore
    // or write a backup for a version this page does not edit.
    editScenario (doc) {
      if (doc) {
        this.scenario = new AIScenario(doc)
        this.scenario.loaded = true
        this.supermodel.registerModel(this.scenario)
      }
      this.scenario.saveBackups = true
      this.scenario.loadFromBackup()
    }

    // The banner and the Save modal's confirm, when this page does not edit the latest version
    // or could not find out which version that is.
    versionNotice () {
      if (!this.versionCheckFailed && !isStale(this.scenario.attributes, this.latestVersion)) { return null }
      const viewing = versionLabel(this.scenario.attributes)
      const latest = this.latestVersion ? versionLabel(this.latestVersion) : null
      return {
        viewing,
        latest,
        latestUrl: this.latestVersion ? editUrl(this.latestVersion) : null,
        text: latest ? $.i18n.t('editor.scenario_version_banner', { viewing, latest }) : $.i18n.t('editor.scenario_version_banner_unknown', { viewing }),
      }
    }

    onLoaded () {
      super.onLoaded()
      this.buildTreema()
      return this.listenTo(this.scenario, 'change', () => {
        this.scenario.updateI18NCoverage()
        if (this.scriptPanel) {
          // Settings edits to the phase or mode change the live-edit warning and the lint.
          this.scriptPanel.$props.releasePhase = this.scenario.get('releasePhase') || 'draft'
          this.scriptPanel.$props.mode = this.scenario.get('mode') || ''
          this.scheduleStoryContext()
        }
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
          readOnly: Boolean(me.get('anonymous')) || !this.scenario.hasWriteAccess(),
          releasePhase: this.scenario.get('releasePhase') || 'draft',
          mode: this.scenario.get('mode') || '',
          storyContext: buildStoryContext(this.scenario.attributes, null),
        },
      })
      this.scriptPanel.$on('changed', (changes, problems) => this.updateSaveBadge(changes, problems))
      this.refreshStoryContext()
      this.scriptStore.load().catch(err => {
        noty({ type: 'error', text: `Could not load the script: ${err.message || err}`, timeout: 8000 })
      })
    }

    // The Story controls offer the cast and scenes the story page will resolve: the scenario's own
    // lists, live from the Settings tab, plus its world chain, fetched once per storyWorld and only
    // for a story scenario (the classic page resolves nothing, so a non-story script must not pick
    // up a missing-world warning). A world that fails to load leaves the panel working with what
    // did load (storyContext.missingWorld).
    refreshStoryContext () {
      if (!this.scriptPanel) { return }
      const slug = this.scenario.get('isStory') ? (this.scenario.get('storyWorld') || '') : null
      if (slug !== this.worldChainSlug) {
        this.worldChainSlug = slug
        this.worldChain = null
        if (slug !== null) {
          loadWorldChain(slug, fetchJson).then(chain => {
            if (!this.scriptPanel || this.worldChainSlug !== slug) { return }
            this.worldChain = chain
            this.refreshStoryContext()
          })
        }
      }
      this.scriptPanel.$props.storyContext = buildStoryContext(this.scenario.attributes, this.worldChain)
    }

    // The navbar Save icon carries the number of pending script changes, red when something blocks Save.
    updateSaveBadge (changes, problems) {
      const badge = this.$('#script-change-count')
      if (!badge.length) { return }
      const count = changes ? changes.count : 0
      badge.text(count).toggleClass('hide', count === 0).toggleClass('has-problems', Boolean(problems && problems.length))
    }

    onCopyId (e) {
      const value = $(e.currentTarget).data('copy')
      if (!value || !navigator.clipboard) { return }
      navigator.clipboard.writeText(String(value)).then(() => {
        noty({ type: 'success', text: `${$.i18n.t('editor.scenario_copied')} ${value}`, timeout: 2000 })
      }, () => {})
    }

    onDiscardScript () {
      if (me.get('anonymous') || !this.scriptPanel) { return }
      this.scriptPanel.discard()
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
      if (me.get('anonymous') || this.playPending) { return }
      // Open the tab inside the click; a tab opened after the awaits gets popup-blocked.
      const playTab = window.open('', '_blank')
      if (!playTab) {
        noty({ type: 'error', text: 'The browser blocked the play tab. Allow pop-ups for this site, then click Play again.' })
        return
      }
      this.playPending = true
      this.$('#play-button').addClass('disabled')
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
        this.$('#play-button').removeClass('disabled')
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
      if (me.get('anonymous')) { return }
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
      const lines = []
      for (const step of c.newSteps) { lines.push(`${t('new_step')} ${steps.indexOf(step) + 1}: ${firstWords(step)}`) }
      for (const step of c.editedSteps) { lines.push(`${t('edited_step')} ${steps.indexOf(step) + 1} (${step.id}): ${firstWords(step)}`) }
      for (const id of c.deletedIds) { lines.push(`${t('deleted_message')} ${id}`) }
      if (c.queueChanged) { lines.push(t('queue_changed')) }
      return lines
    }

    // Lines for the save modal: what the server will clear because its English changed, so AI Translate fills it again.
    translationSummary () {
      const lines = []
      if (this.scriptStore) {
        const steps = this.scriptStore.state.steps
        for (const step of this.scriptStore.changes().editedSteps) {
          if (this.scriptStore.staleTranslationsOf(step).length) {
            lines.push(`${$.i18n.t('editor.scenario_step_title')} ${steps.indexOf(step) + 1}: ${firstWords(step)}`)
          }
        }
      }
      if (staleTranslations(this.scenario._revertAttributes, this.scenario.attributes, SCENARIO_TRANSLATED_PATHS).length) {
        lines.push($.i18n.t('editor.scenario_save_translations_settings'))
      }
      return lines
    }

    openSaveModal () {
      if (me.get('anonymous')) { return }
      if (!this.scenario.hasWriteAccess() && this.scriptStore && this.scriptStore.changes().any) {
        noty({ type: 'error', text: $.i18n.t('editor.scenario_save_no_write_access'), timeout: 8000 })
        return
      }
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
        translationSummary: this.translationSummary(),
        versionNotice: this.versionNotice(),
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
      // An unloaded script (fetch failed, or Save before it arrived) must not replace the queue with nothing.
      const scriptLoaded = Boolean(this.scriptStore && this.scriptStore.state.loaded)
      const messages = scriptLoaded ? this.scriptStore.saveMessages() : Promise.resolve(null)
      messages.then(ids => {
        if (Array.isArray(ids)) { this.scenario.set('initialActionQueue', ids) }
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
        const url = `/editor/ai-scenario/${this.scenario.get('slug') || this.scenario.id}`
        const finish = () => {
          modal.modal('hide')
          document.location.href = url
        }
        if (!this.scriptStore) { return finish() }
        // Deletes run only now, with the new queue published; the script backup goes with them.
        this.scriptStore.applyDeletes().then(() => {
          this.scriptStore.clearBackup()
        }, err => {
          this.scriptStore.clearBackup()
          noty({ type: 'warning', text: `${$.i18n.t('editor.scenario_save_delete_failed')} ${err.message || err}`, timeout: 8000 })
        }).then(finish)
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
      const versionHistoryView = new VersionHistoryView({ scenario: this.scenario }, this.scenario.id)
      this.openModalView(versionHistoryView)
      return Backbone.Mediator.publish('editor:view-switched', {})
    }
  }
  AIScenarioEditView.initClass()
  return AIScenarioEditView
})())
