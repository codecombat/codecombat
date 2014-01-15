VersionsView = require 'views/kinds/VersionsView'

module.exports = class SuperVersionsView extends VersionsView
  id: "editor-thang-versions-view"
  url: "/db/thang.type/"
  page: "thang"

  constructor: (options, @ID) ->
    super options, ID, require 'models/ThangType'