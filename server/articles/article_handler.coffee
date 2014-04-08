Article = require('./Article')
Handler = require('../commons/Handler')

ArticleHandler = class ArticleHandler extends Handler
  modelClass: Article
  editableProperties: ['body', 'name', 'i18n']
  jsonSchema: require './article_schema'

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

module.exports = new ArticleHandler()
