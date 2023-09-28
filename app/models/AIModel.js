import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_model.schema'

class AIModel extends CocoModel { }

AIModel.className = 'AIModel'
AIModel.schema = schema
AIModel.urlRoot = '/db/ai_model'
AIModel.prototype.urlRoot = '/db/ai_model'
AIModel.prototype.defaults = {}

module.exports = AIModel
