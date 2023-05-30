import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/ai_project.schema'

class AIProject extends CocoModel { }

AIProject.className = 'AIProject'
AIProject.schema = schema
AIProject.urlRoot = '/db/ai_project'
AIProject.prototype.urlRoot = '/db/ai_project'
AIProject.prototype.defaults = {
  visibility: 'public'
}

export default AIProject;
