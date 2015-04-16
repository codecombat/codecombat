VersionsModal = require 'views/editor/modal/VersionsModal'

module.exports = class ComponentVersionsModal extends VersionsModal
  id: 'editor-component-versions-view'
  url: '/db/level.component/'
  page: 'component'

  constructor: (options, @ID) ->
    super options, @ID, require 'models/LevelComponent'
