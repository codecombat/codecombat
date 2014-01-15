VersionsView = require 'views/kinds/VersionsView'

module.exports = class SuperVersionsView extends VersionsView
  id: "editor-article-versions-view"
  url: "/db/article/"
  page: "article"

  constructor: (options, @ID) ->
    super options, ID, require 'models/Article'