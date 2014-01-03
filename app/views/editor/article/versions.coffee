View = require 'views/kinds/RootView'
template = require 'templates/editor/article/versions'
tableTemplate = require 'templates/editor/article/table'
Article = require 'models/Article'

class ArticleVersionsCollection extends Backbone.Collection
  url: '/db/article/'
  model: Article
  initialize: (@articleID) -> @url += articleID + '/versions'

module.exports = class ArticleVersionsView extends View
  id: "editor-article-versions-view"
  template: template
  startsLoading: true

  constructor: (options, @articleID) ->
    super options
    @article = new Article(_id: @articleID)
    @article.fetch()
    @article.once('sync', @onArticleSync)

  onArticleSync: =>
    @collection = new ArticleVersionsCollection(@article.attributes.original)
    @collection.fetch()
    @collection.on('reset', @onVersionFetched)

  onVersionFetched: =>
    @startsLoading = false
    @render()

  getRenderData: (context={}) =>
    context = super(context)
    context.articles = if @collection then (m.attributes for m in @collection.models) else []
    context
