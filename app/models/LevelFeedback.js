const CocoModel = require('./CocoModel')
const schema = require('schemas/models/level_feedback')

class LevelFeedback extends CocoModel {
  constructor () {
    super()
  }
}

LevelFeedback.className = 'LevelFeedback'
LevelFeedback.schema = schema
LevelFeedback.prototype.urlRoot = '/db/level.feedback'

module.exports = LevelFeedback
