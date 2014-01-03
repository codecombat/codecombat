LevelFeedback = require('../models/LevelFeedback')
Handler = require('./Handler')

class LevelFeedbackHandler extends Handler
  modelClass: LevelFeedback
  editableProperties: ['rating', 'review', 'level', 'levelID', 'levelName']

  makeNewInstance: (req) ->
    feedback = super(req)
    feedback.set('creator', req.user._id)
    feedback.set('creatorName', req.user.get('name') or '')
    feedback

module.exports = new LevelFeedbackHandler()
