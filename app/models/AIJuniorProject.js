import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_junior_project.schema'

class AIJuniorProject extends CocoModel { }

AIJuniorProject.className = 'AIJuniorProject'
AIJuniorProject.schema = schema
AIJuniorProject.urlRoot = '/db/ai_junior_project'
AIJuniorProject.prototype.urlRoot = '/db/ai_junior_project'

module.exports = AIJuniorProject
