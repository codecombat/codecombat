Achievement = require './Achievement'
Handler = require '../commons/Handler'

class AchievementHandler extends Handler
  modelClass: Achievement

  # Used to determine which properties requests may edit
  editableProperties: ['name', 'query', 'worth', 'collection', 'description', 'userField', 'proportionalTo']
  jsonSchema = require '../../app/schemas/models/achievement.coffee'

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

  get: (req, res) ->
    query = @modelClass.find({})
    query.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (@formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

module.exports = new AchievementHandler()
