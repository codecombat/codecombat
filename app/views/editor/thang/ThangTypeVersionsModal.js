VersionsModal = require 'views/editor/modal/VersionsModal'

module.exports = class ThangTypeVersionsModal extends VersionsModal
  id: 'editor-thang-versions-view'
  url: '/db/thang.type/'
  page: 'thang'

  constructor: (options, @ID) ->
    super options, @ID, require 'models/ThangType'
