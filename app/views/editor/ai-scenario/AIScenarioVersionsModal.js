let AIScenarioVersionsModal
const VersionsModal = require('views/editor/modal/VersionsModal')

module.exports = (AIScenarioVersionsModal = (function () {
  AIScenarioVersionsModal = class AIScenarioVersionsModal extends VersionsModal {
    static initClass () {
      this.prototype.id = 'editor-scenario-versions-view'
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
