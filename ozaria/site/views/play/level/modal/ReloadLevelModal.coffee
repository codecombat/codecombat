ModalView = require 'views/core/ModalView'
template = require 'ozaria/site/templates/play/level/modal/reload-level-modal'

module.exports = class ReloadLevelModal extends ModalView
  id: '#reload-level-modal'
  template: template

  events:
    'click #restart-level-confirm-button': 'onClickRestart'

  onClickRestart: (e) ->
    Backbone.Mediator.publish 'level:restart', {}
