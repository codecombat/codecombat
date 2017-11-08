SearchView = require 'views/common/SearchView'

module.exports = class ArticleSearchView extends SearchView
  id: 'editor-article-home-view'
  modelLabel: 'Article'
  model: require 'models/Article'
  modelURL: '/db/article'
  tableTemplate: require 'templates/editor/article/table'
  page: 'article'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.article_title'
    context.currentNew = 'editor.new_article_title'
    context.currentNewSignup = 'editor.new_article_title_login'
    context.currentSearch = 'editor.article_search_title'
    context.newModelsAdminOnly = true
    @$el.i18n()
    @applyRTLIfNeeded()
    context
