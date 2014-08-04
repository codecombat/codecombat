Achievement = require './Achievement'
Handler = require '../commons/Handler'

class AchievementHandler extends Handler
  modelClass: Achievement

  # Used to determine which properties requests may edit
  editableProperties: ['name', 'query', 'worth', 'collection', 'description', 'userField', 'proportionalTo', 'icon', 'function']
  jsonSchema = require '../../app/schemas/models/achievement.coffee'

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

  get: (req, res) ->
    # /db/achievement?related=<ID>
    if req.query.related
      return @sendUnauthorizedError(res) if not @hasAccess(req)
      Achievement.find {related: req.query.related}, (err, docs) =>
        return @sendDatabaseError(res, err) if err
        docs = (@formatEntity(req, doc) for doc in docs)
        @sendSuccess res, docs
    else
      super req, res

module.exports = new AchievementHandler()
