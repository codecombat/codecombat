require 'ozaria/site/styles/core/modal-base.scss'
ModalView = require 'views/core/ModalView'
template = require 'ozaria/site/templates/play/level/modal/restart-level-modal'

module.exports = class RestartLevelModal extends ModalView
  id: '#restart-level-modal'
  template: template

  events:
    'click #restart-level-confirm-button': 'onClickRestart'

  onClickRestart: (e) ->
    Backbone.Mediator.publish 'level:restart', {}
