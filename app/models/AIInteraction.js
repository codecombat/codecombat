import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_interaction.schema'

class AIInteraction extends CocoModel { }

AIInteraction.className = 'AIInteraction'
AIInteraction.schema = schema
AIInteraction.urlRoot = '/db/ai_interaction'
AIInteraction.prototype.urlRoot = '/db/ai_interaction'
AIInteraction.prototype.defaults = {}

export default AIInteraction;
