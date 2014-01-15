VersionsView = require 'views/kinds/VersionsView'

module.exports = class SuperVersionsView extends VersionsView
  id: "editor-level-versions-view"
  url: "/db/level/"
  page: "level"

  constructor: (options, @ID) ->
    super options, ID, require 'models/Level'