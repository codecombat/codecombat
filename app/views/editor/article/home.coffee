SearchView = require 'views/kinds/SearchView'

module.exports = class ThangTypeHomeView extends SearchView
  id: 'editor-article-home-view'
  modelLabel: 'Article'
  model: require 'models/Article'
  modelURL: '/db/article'
  tableTemplate: require 'templates/editor/article/table'

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.article_title'
    context.currentNew = 'editor.new_article_title'
    context.currentNewSignup = 'editor.new_article_title_login'
    context.currentSearch = 'editor.article_search_title'
    @$el.i18n()
    context
