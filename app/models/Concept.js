import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/concept.schema'

class Concept extends CocoModel { }

Concept.className = 'Concept'
Concept.schema = schema
Concept.urlRoot = '/db/concept'
Concept.prototype.urlRoot = '/db/concept'

module.exports = Concept
