Article = require 'models/Article'

module.exports = class HintsState extends Backbone.Model

  initialize: (attributes, options) ->
    { @level, @session, @supermodel } = options
    @listenTo(@level, 'change:documentation', @update)
    @update()

  getHint: (index) ->
    @get('hints')?[index]

  update: ->
    articles = @supermodel.getModels(Article)
    docs = @level.get('documentation') ? {}
    general = _.filter (_.find(articles, (article) -> article.get('original') is doc.original)?.attributes for doc in docs.generalArticles or [])
    specific = docs.specificArticles or []
    hints = (docs.hintsB or docs.hints or []).concat(specific).concat(general)
    hints = _.sortBy hints, (doc) ->
      return -1 if doc.name is 'Intro'
      return 0

    total = _.size(hints)
    @set({
      hints
      total
    })
