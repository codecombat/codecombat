ModalView = require '../../core/ModalView'
template = require 'templates/editor/modal/confirm-modal'

module.exports = class ConfirmModal extends ModalView
  id: 'confirm-modal'
  template: template
  closeButton: true
  closeOnConfirm: true

  events:
    'click #decline-button': 'onClickDecline'
    'click #confirm-button': 'onClickConfirm'

  initialize: (options) ->
    _.assign @, _.pick(options, 'title', 'body', 'decline', 'confirm', 'closeOnConfirm', 'closeButton')

  onClickDecline: -> @trigger 'decline'

  onClickConfirm: -> @trigger 'confirm'
