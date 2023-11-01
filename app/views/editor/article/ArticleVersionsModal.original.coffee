VersionsModal = require 'views/editor/modal/VersionsModal'

module.exports = class ArticleVersionsModal extends VersionsModal
  id: 'editor-article-versions-view'
  url: '/db/article/'
  page: 'article'

  constructor: (options, @ID) ->
    super options, @ID, require 'models/Article'
