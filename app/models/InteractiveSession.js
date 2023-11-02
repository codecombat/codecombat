const CocoModel = require('./CocoModel')
const schema = require('schemas/models/interactives/interactive_session.schema')

class InteractiveSession extends CocoModel {
  constructor () {
    super()
  }
}
InteractiveSession.className = 'InteractiveSession'
InteractiveSession.schema = schema
InteractiveSession.prototype.urlRoot = '/db/interactive.session'

module.exports = InteractiveSession
