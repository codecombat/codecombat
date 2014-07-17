CocoModel = require './CocoModel'

module.exports = class LevelFeedback extends CocoModel
  @className: 'LevelFeedback'
  @schema: require 'schemas/models/level_feedback'
  urlRoot: '/db/level.feedback'
