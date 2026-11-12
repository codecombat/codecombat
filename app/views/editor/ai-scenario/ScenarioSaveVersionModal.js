// The scenario editor's save modal: the usual version modal plus a list of the
// script writes that will happen before the version (new, edited and deleted
// messages, queue order), and of the translations the save clears because their
// English changed. Script-only edits leave the scenario document unchanged, so
// `hasChanges` is forced on when the script has pending work.
const SaveVersionModal = require('views/editor/modal/SaveVersionModal')

module.exports = class ScenarioSaveVersionModal extends SaveVersionModal {
  constructor (options) {
    super(options)
    // A patch carries only the scenario delta, never message writes; the Script tab is read-only for patchers.
    this.scriptSummary = this.isPatch ? [] : (options.scriptSummary || [])
    // A patch clears nothing until it is accepted and saved as a version.
    this.translationSummary = this.isPatch ? [] : (options.translationSummary || [])
    if (this.scriptSummary.length) { this.hasChanges = true }
    // Not the latest version: the save replaces the latest with this one, a change even with
    // nothing edited, and one to tick first. A patch never replaces a version.
    this.versionNotice = options.versionNotice || null
    if (this.needsReplaceConfirm()) { this.hasChanges = true }
  }

  afterRender () {
    // Before super: it replaces .changes-stub with the delta view, and the lists go above it.
    this.insertVersionNotice()
    this.insertSummary(this.scriptSummary, 'script-summary', 'alert-info', 'editor.scenario_save_script_heading')
    this.insertSummary(this.translationSummary, 'translation-summary', 'alert-warning', 'editor.scenario_save_translations_heading')
    super.afterRender()
    if (this.needsReplaceConfirm()) { this.$el.find('#save-version-button').prop('disabled', true) }
  }

  needsReplaceConfirm () {
    return Boolean(this.versionNotice) && !this.isPatch
  }

  insertVersionNotice () {
    const notice = this.versionNotice
    if (!notice) { return }
    const block = $('<div class="alert alert-danger version-notice"></div>').append($('<strong></strong>').text(notice.text))
    if (this.needsReplaceConfirm()) {
      const label = notice.latest ? $.i18n.t('editor.scenario_version_replace_confirm', { latest: notice.latest }) : $.i18n.t('editor.scenario_version_save_anyway')
      const input = $('<input id="replace-latest" type="checkbox">')
      block.append($('<div class="checkbox"></div>').append($('<label></label>').append(input).append(document.createTextNode(` ${label}`))))
    }
    this.$el.find('.changes-stub').before(block)
  }

  onReplaceLatestToggled (e) {
    this.$el.find('#save-version-button').prop('disabled', !$(e.currentTarget).prop('checked'))
  }

  // The form submits on Enter too, so the tick is checked here and not only through the button.
  saveChanges () {
    if (this.needsReplaceConfirm() && !this.$el.find('#replace-latest').prop('checked')) { return }
    return super.saveChanges()
  }

  insertSummary (lines, listClass, alertClass, headingKey) {
    if (!lines.length) { return }
    const list = $(`<ul class="${listClass}"></ul>`)
    for (const line of lines) { list.append($('<li></li>').text(line)) }
    const block = $(`<div class="alert ${alertClass}"></div>`)
      .append($('<strong></strong>').text($.i18n.t(headingKey)))
      .append(list)
    this.$el.find('.changes-stub').before(block)
  }
}

module.exports.prototype.events = Object.assign({}, SaveVersionModal.prototype.events, { 'change #replace-latest': 'onReplaceLatestToggled' })
