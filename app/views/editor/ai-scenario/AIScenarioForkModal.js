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
    const name = this.$('#fork-scenario-name').val().trim()
    if (!name) {
      noty({ type: 'error', text: 'Give the fork a name.' })
      return
    }
    this.$('#fork-modal-confirm-button').prop('disabled', true)
    fetchJson(`/db/ai_scenario/${this.scenario.get('original')}/fork`, {
      method: 'POST',
      json: { name },
    }).then((fork) => {
      this.hide()
      application.router.navigate(`/editor/ai-scenario/${fork.slug || fork._id}`, { trigger: true })
    }).catch((err) => {
      this.$('#fork-modal-confirm-button').prop('disabled', false)
      const detail = err.code === 409 ? 'That name is already in use.' : (err.message || 'Fork failed.')
      noty({ type: 'error', text: `${detail} (${err.code || 'network'})` })
    })
  }
}
module.exports.initClass()
