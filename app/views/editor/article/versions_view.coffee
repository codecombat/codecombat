VersionsModalView = require 'views/modal/versions_modal'

module.exports = class ArticleVersionsView extends VersionsModalView
  id: 'version-history-modal'
  url: "/db/article/"
  page: "article"

  constructor: (options, @ID) ->
    super options, ID, require 'models/Article'