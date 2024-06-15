import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_junior_scenario.schema'

class AIJuniorScenario extends CocoModel { }

AIJuniorScenario.className = 'AIJuniorScenario'
AIJuniorScenario.schema = schema
AIJuniorScenario.urlRoot = '/db/ai_junior_scenario'
AIJuniorScenario.prototype.urlRoot = '/db/ai_junior_scenario'
AIJuniorScenario.prototype.defaults = {
  releasePhase: 'draft',
}

module.exports = AIJuniorScenario
