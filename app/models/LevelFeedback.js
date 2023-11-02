const CocoModel = require('./CocoModel')
const schema = require('schemas/models/level_feedback')

class LevelFeedback extends CocoModel {
  constructor () {
    super()
    this.className = 'LevelFeedback'
    this.schema = schema
    this.urlRoot = '/db/level.feedback'
  }
}

module.exports = LevelFeedback
