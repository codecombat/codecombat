VersionsView = require 'views/kinds/VersionsView'
ModalView = require 'views/kinds/ModalView'
template = require 'templates/editor/level/versions'

module.exports = class ModalVersionsView extends VersionsView
  id: 'version-history-modal'
  url: "/db/level/"
  page: "level"
  template: template
  startsLoading: true

  className: "modal fade"
  closeButton: true
  closesOnClickOutside: true
  modalWidthPercent: null

  shortcuts:
    'esc': 'hide'

  constructor: (options, @ID) ->
    super options, ID, require 'models/Level'
    _.extend @, ModalView
    ModalView.prototype.constructor options

  getRenderData: (context={}) ->
    context = super(context)
    context.closeButton = true
    context

  hide: ->
    @$el.removeClass('fade').modal "hide"