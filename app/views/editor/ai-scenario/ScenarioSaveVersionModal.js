// The scenario editor's save modal: the usual version modal plus a list of the
// script writes that will happen before the version (new, edited and deleted
// messages, queue order). Script-only edits leave the scenario document
// unchanged, so `hasChanges` is forced on when the script has pending work.
const SaveVersionModal = require('views/editor/modal/SaveVersionModal')

module.exports = class ScenarioSaveVersionModal extends SaveVersionModal {
  constructor (options) {
    super(options)
    // A patch carries only the scenario delta, never message writes; the Script tab is read-only for patchers.
    this.scriptSummary = this.isPatch ? [] : (options.scriptSummary || [])
    if (this.scriptSummary.length) { this.hasChanges = true }
  }

  afterRender () {
    super.afterRender()
    if (!this.scriptSummary.length) { return }
    const list = $('<ul class="script-summary"></ul>')
    for (const line of this.scriptSummary) { list.append($('<li></li>').text(line)) }
    const block = $('<div class="alert alert-info"></div>')
      .append($('<strong></strong>').text($.i18n.t('editor.scenario_save_script_heading')))
      .append(list)
    this.$el.find('.changes-stub').before(block)
  }
}
