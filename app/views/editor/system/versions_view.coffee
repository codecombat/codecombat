VersionsModalView = require 'views/modal/versions_modal'

module.exports = class SystemVersionsView extends VersionsModalView
  id: 'editor-system-versions-view'
  url: '/db/level.system/'
  page: 'system'

  constructor: (options, @ID) ->
    super options, ID, require 'models/LevelSystem'
