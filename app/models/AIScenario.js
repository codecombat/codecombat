import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_scenario.schema'

class AIScenario extends CocoModel { }

AIScenario.className = 'AIScenario'
AIScenario.schema = schema
AIScenario.urlRoot = '/db/ai_scenario'
AIScenario.prototype.urlRoot = '/db/ai_scenario'
AIScenario.prototype.defaults = {
  releasePhase: 'beta',
  interactions: []
}

module.exports = AIScenario
