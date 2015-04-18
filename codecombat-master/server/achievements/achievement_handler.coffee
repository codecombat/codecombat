Achievement = require './Achievement'
Handler = require '../commons/Handler'

class AchievementHandler extends Handler
  modelClass: Achievement

  # Used to determine which properties requests may edit
  editableProperties: [
    'name'
    'query'
    'worth'
    'collection'
    'description'
    'userField'
    'proportionalTo'
    'icon'
    'function'
    'related'
    'difficulty'
    'category'
    'rewards'
    'i18n'
    'i18nCoverage'
  ]

  allowedMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']
  jsonSchema = require '../../app/schemas/models/achievement.coffee'


  hasAccess: (req) ->
    req.method in ['GET', 'PUT'] or req.user?.isAdmin() or req.user?.isArtisan()

  hasAccessToDocument: (req, document, method=null) ->
    method = (method or req.method).toLowerCase()
    return true if method is 'get'
    return true if req.user?.isAdmin() or req.user?.isArtisan()
    return true if method is 'put' and @isJustFillingTranslations(req, document)
    return

  get: (req, res) ->
    # /db/achievement?related=<ID>
    if req.query.related
      return @sendForbiddenError(res) if not @hasAccess(req)
      Achievement.find {related: req.query.related}, (err, docs) =>
        return @sendDatabaseError(res, err) if err
        docs = (@formatEntity(req, doc) for doc in docs)
        @sendSuccess res, docs
    else
      super req, res

  delete: (req, res, slugOrID) ->
    return @sendForbiddenError res unless req.user?.isAdmin() or req.user?.isArtisan()
    @getDocumentForIdOrSlug slugOrID, (err, document) => # Check first
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless document?
      document.remove (err, document) =>
        return @sendDatabaseError(res, err) if err
        @sendNoContent res

  getNamesByIDs: (req, res) -> @getNamesByOriginals req, res, true

module.exports = new AchievementHandler()
