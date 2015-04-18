Article = require './Article'
Handler = require '../commons/Handler'

ArticleHandler = class ArticleHandler extends Handler
  modelClass: Article
  editableProperties: ['body', 'name', 'i18n']
  jsonSchema: require '../../app/schemas/models/article'

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin() or req.user?.isArtisan()

  hasAccessToDocument: (req, document, method=null) ->
    return true if req.method is 'GET' or method is 'get' or req.user?.isAdmin() or req.user?.isArtisan()
    return false

module.exports = new ArticleHandler()
