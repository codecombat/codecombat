ModalView = require 'views/core/ModalView'
template = require 'templates/play/level/modal/reload-level-modal'

module.exports = class ReloadLevelModal extends ModalView
  id: '#reload-level-modal'
  template: template

  events:
    'click #restart-level-confirm-button': 'onClickRestart'

  onClickRestart: (e) ->
    @playSound 'menu-button-click'
    Backbone.Mediator.publish 'level:restart', {}
