VersionsModalView = require 'views/modal/versions_modal'

module.exports = class ComponentVersionsView extends VersionsModalView
  id: 'editor-thang-versions-view'
  url: '/db/thang.type/'
  page: 'thang'

  constructor: (options, @ID) ->
    super options, ID, require 'models/ThangType'
