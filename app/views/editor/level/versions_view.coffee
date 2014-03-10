VersionsModalView = require 'views/modal/versions_modal'

module.exports = class LevelVersionsView extends VersionsModalView
  id: 'version-history-modal'
  url: "/db/level/"
  page: "level"

  constructor: (options, @ID) ->
    super options, ID, require 'models/Level'