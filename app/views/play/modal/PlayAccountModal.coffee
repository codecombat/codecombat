ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-account-modal'

module.exports = class PlayAccountModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  modalWidthPercent: 90
  id: 'play-account-modal'
  #instant: true

  #events:
  #  'change input.select': 'onSelectionChanged'

  constructor: (options) ->
    super options

  getRenderData: (context={}) ->
    context = super(context)
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1

  onHidden: ->
    super()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1
