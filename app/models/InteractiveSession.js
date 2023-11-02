const CocoModel = require('./CocoModel')
const schema = require('schemas/models/interactives/interactive_session.schema')

class InteractiveSession extends CocoModel {
  constructor () {
    super()
    this.className = 'InteractiveSession'
    this.schema = schema
    this.urlRoot = '/db/interactive.session'
  }
}

module.exports = InteractiveSession
