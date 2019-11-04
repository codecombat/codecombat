import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/interactives/interactive.schema'

class Interactive extends CocoModel { }

Interactive.className = 'Interactive'
Interactive.schema = schema
// TODO remove if not required
Interactive.urlRoot = '/db/interactive'
Interactive.prototype.urlRoot = '/db/interactive'

module.exports = Interactive
