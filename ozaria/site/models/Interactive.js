import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/interactives/interactive.schema'

class Interactive extends CocoModel { }

Interactive.className = 'Interactive'
Interactive.schema = schema
Interactive.urlRoot = '/db/interactive'

module.exports = Interactive
