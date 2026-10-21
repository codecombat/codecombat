// Fork a scenario from its editor: the server copies the scenario as a draft
// together with every message in its queue, and we open the copy's editor.
const ModalView = require('views/core/ModalView')
const template = require('app/templates/editor/ai-scenario/fork')
const fetchJson = require('core/api/fetch-json')

module.exports = class AIScenarioForkModal extends ModalView {
  static initClass () {
    this.prototype.id = 'editor-ai-scenario-fork-modal'
    this.prototype.template = template
    this.prototype.events = {
      'click #fork-modal-confirm-button': 'onClickForkButton',
      'keydown #fork-scenario-name': 'onNameKeydown',
    }
  }

  constructor (options = {}) {
    super(options)
    this.scenario = options.scenario
    this.defaultName = `${this.scenario.get('name')} (fork)`
  }

  onNameKeydown (e) {
    if (e.key === 'Enter') { this.onClickForkButton() }
  }

  onClickForkButton () {
    if (this.pending) { return }
    const name = this.$('#fork-scenario-name').val().trim()
    if (!name) {
      noty({ type: 'error', text: 'Give the fork a name.' })
      return
    }
    this.pending = true
    this.$('#fork-modal-confirm-button, .modal-footer [data-dismiss="modal"]').prop('disabled', true)
    fetchJson(`/db/ai_scenario/${this.scenario.get('original')}/fork`, {
      method: 'POST',
      json: { name },
    }).then((fork) => {
      this.pending = false
      const url = `/editor/ai-scenario/${fork.slug || fork._id}`
      if (this.destroyed) {
        // Dismissed while the request ran: the draft exists, say where instead of navigating away.
        noty({ type: 'success', text: `Fork created: ${url}`, timeout: 8000 })
        return
      }
      this.hide()
      application.router.navigate(url, { trigger: true })
    }).catch((err) => {
      this.pending = false
      if (this.destroyed) { return }
      this.$('#fork-modal-confirm-button, .modal-footer [data-dismiss="modal"]').prop('disabled', false)
      const detail = err.code === 409 ? 'That name is already in use.' : (err.message || 'Fork failed.')
      noty({ type: 'error', text: `${detail} (${err.code || 'network'})` })
    })
  }
}
module.exports.initClass()
