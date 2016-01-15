ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/play-settings-modal'

module.exports = class PlaySettingsModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  modalWidthPercent: 90
  id: 'play-settings-modal'
  #instant: true

  #events:
  #  'change input.select': 'onSelectionChanged'

  constructor: (options) ->
    super options

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @playSound 'game-menu-open'

  onHidden: ->
    super()
    @playSound 'game-menu-close'
