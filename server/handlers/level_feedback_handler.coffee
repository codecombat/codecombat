LevelFeedback = require './../models/LevelFeedback'
Handler = require '../commons/Handler'

class LevelFeedbackHandler extends Handler
  modelClass: LevelFeedback
  editableProperties: ['rating', 'review', 'level', 'levelID', 'levelName']
  jsonSchema: require '../../app/schemas/models/level_feedback'

  makeNewInstance: (req) ->
    feedback = super(req)
    feedback.set('creator', req.user._id)
    feedback.set('creatorName', req.user.get('name') or '')
    feedback

module.exports = new LevelFeedbackHandler()
