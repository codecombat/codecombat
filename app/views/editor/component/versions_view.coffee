VersionsModalView = require 'views/modal/versions_modal'

module.exports = class ComponentVersionsView extends VersionsModalView
  id: 'editor-component-versions-view'
  url: '/db/level.component/'
  page: 'component'

  constructor: (options, @ID) ->
    super options, ID, require 'models/LevelComponent'
