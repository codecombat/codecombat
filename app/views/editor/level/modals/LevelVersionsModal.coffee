VersionsModal = require 'views/editor/modal/VersionsModal'

module.exports = class LevelVersionsModal extends VersionsModal
  id: 'editor-level-versions-view'
  url: '/db/level/'
  page: 'level'

  constructor: (options, @ID) ->
    super options, @ID, require 'models/Level'
