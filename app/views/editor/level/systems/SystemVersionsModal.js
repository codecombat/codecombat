VersionsModal = require 'views/editor/modal/VersionsModal'

module.exports = class SystemVersionsModal extends VersionsModal
  id: 'editor-system-versions-view'
  url: '/db/level.system/'
  page: 'system'

  constructor: (options, @ID) ->
    super options, @ID, require 'models/LevelSystem'
