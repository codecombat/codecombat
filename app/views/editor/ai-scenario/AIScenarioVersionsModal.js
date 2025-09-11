// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIScenarioVersionsModal
const VersionsModal = require('views/editor/modal/VersionsModal')

module.exports = (AIScenarioVersionsModal = (function () {
  AIScenarioVersionsModal = class AIScenarioVersionsModal extends VersionsModal {
    static initClass () {
      this.prototype.id = 'editor-cenario-versions-view'
      this.prototype.url = '/db/ai_scenario/'
      this.prototype.page = 'ai-scenario'
    }

    constructor (options, ID) {
      super(options, ID, require('models/AIScenario'))
      this.ID = ID
    }
  }
  AIScenarioVersionsModal.initClass()
  return AIScenarioVersionsModal
})())
