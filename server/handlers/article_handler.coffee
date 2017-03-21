# TODO: Remove once mapping.coffee is refactored out

Article = require './../models/Article'
Handler = require '../commons/Handler'

ArticleHandler = class ArticleHandler extends Handler
  modelClass: Article
  editableProperties: Article.schema.editableProperties 
  jsonSchema: Article.schema.jsonSchema

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin() or req.user?.isArtisan()

  hasAccessToDocument: (req, document, method=null) ->
    return true if req.method is 'GET' or method is 'get' or req.user?.isAdmin() or req.user?.isArtisan()
    return false

module.exports = new ArticleHandler()
