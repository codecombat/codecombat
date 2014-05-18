Achievement = require './Achievement'
Handler = require '../commons/Handler'

class AchievementHandler extends Handler
  modelClass: Achievement

  jsonSchema = require '../../app/schemas/models/achievement.coffee'

  getAll: (req, res) ->
    query = @modelClass.find({})
    query.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (@formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

module.exports = new AchievementHandler()