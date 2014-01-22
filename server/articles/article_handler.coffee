winston = require('winston')
request = require('request')
Article = require('./Article')
Handler = require('../commons/Handler')

ArticleHandler = class ArticleHandler extends Handler
  modelClass: Article
  editableProperties: ['body', 'name']

  hasAccess: (req) ->
    req.method is 'GET' or req.user?.isAdmin()

module.exports = new ArticleHandler()
