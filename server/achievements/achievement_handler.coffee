Achievement = require './Achievement'
Handler = require '../commons/Handler'

class AchievementHandler extends Handler
  modelClass: Achievement

  # Used to determine which properties requests may edit
  editableProperties: ['name', 'query', 'worth', 'collection', 'description', 'userField', 'proportionalTo', 'icon', 'function', 'related', 'difficulty', 'category', 'recalculable']
  allowedMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']
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

  delete: (req, res, slugOrID) ->
    return @sendUnauthorizedError res unless req.user?.isAdmin()
    @getDocumentForIdOrSlug slugOrID, (err, document) => # Check first
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless document?
      document.remove (err, document) =>
        return @sendDatabaseError(res, err) if err
        @sendNoContent res

module.exports = new AchievementHandler()
