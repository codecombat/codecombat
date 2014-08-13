ModalView = require '../kinds/ModalView'
template = require 'templates/modal/confirm'

module.exports = class ConfirmModal extends ModalView
  id: 'confirm-modal'
  template: template
  closeButton: true
  closeOnConfirm: true

  events:
    'click #decline-button': 'onDecline'
    'click #confirm-button': 'onConfirm'

  constructor: (@renderData={}, options={}) ->
    super(options)

  getRenderData: ->
    context = super()
    context.closeOnConfirm = @closeOnConfirm
    _.extend context, @renderData

  setRenderData: (@renderData) ->

  onDecline: -> @trigger 'decline'

  onConfirm: -> @trigger 'confirm'
