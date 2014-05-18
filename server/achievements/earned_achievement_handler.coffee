mongoose = require('mongoose')
EarnedAchievement = require './EarnedAchievement'
Handler = require '../commons/Handler'

class EarnedAchievementHandler extends Handler
  modelClass: EarnedAchievement

  # Don't allow POSTs or anything yet
  hasAccess: (req) ->
    req.method is 'GET'

  getByRelationship: (req, res, related, id) ->
    switch related
      when 'user'
        query = @modelClass.find({user: new mongoose.Types.ObjectId(id)})
        query.exec (err, documents) =>
          return @sendDatabaseError(res, err) if err?
          documents = (@formatEntity(req, doc) for doc in documents)
          @sendSuccess(res, documents)
      else return @sendNotFoundError(res)

module.exports = new EarnedAchievementHandler()