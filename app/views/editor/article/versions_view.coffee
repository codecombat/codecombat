VersionsModalView = require 'views/modal/versions_modal'

module.exports = class ArticleVersionsView extends VersionsModalView
  id: 'editor-article-versions-view'
  url: '/db/article/'
  page: 'article'

  constructor: (options, @ID) ->
    super options, ID, require 'models/Article'
