import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/cutscene.schema'

class Cutscene extends CocoModel { }

Cutscene.className = 'Cutscene'
Cutscene.schema = schema
Cutscene.urlRoot = '/db/cutscene'

module.exports = Cutscene
