import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/cinematic.schema'

class Cinematic extends CocoModel { }

Cinematic.className = 'Cinematic'
Cinematic.schema = schema
Cinematic.urlRoot = '/db/cinematic'

module.exports = Cinematic
