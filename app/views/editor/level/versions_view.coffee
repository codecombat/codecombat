SuperVersionsView = require './versions'
template = require 'templates/editor/level/versions'

module.exports = class ModalVersionsView extends SuperVersionsView
  id: 'version-history-modal'
  template: template

  constructor: (options, @ID) ->
    super options, ID