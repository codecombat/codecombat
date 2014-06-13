ModalView = require '../kinds/ModalView'
template = require 'templates/modal/confirm'

module.exports = class ConfirmModal extends ModalView
  id: "confirm-modal"
  template: template
  closeButton: true
  closeOnConfirm: true

  events:
    'click #decline-button': 'doDecline'
    'click #confirm-button': 'doConfirm'

  constructor: (@renderData={}, options={}) ->
    super(options)

  getRenderData: ->
    context = super()
    context.closeOnConfirm = @closeOnConfirm
    _.extend context, @renderData

  setRenderData: (@renderData) ->

  onDecline: (@decline) ->

  onConfirm: (@confirm) ->

  doConfirm: -> @confirm() if @confirm

  doDecline: -> @decline() if @decline
