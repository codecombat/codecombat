ModalView = require 'views/core/ModalView'
template = require 'templates/play/level/modal/infinite_loop'

module.exports = class InfiniteLoopModal extends ModalView
  id: '#infinite-loop-modal'
  template: template

  events:
    'click #restart-level-infinite-loop-retry-button': -> Backbone.Mediator.publish 'tome:cast-spell', {}
    'click #restart-level-infinite-loop-confirm-button': -> Backbone.Mediator.publish 'level:restart', {}
    'click #restart-level-infinite-loop-comment-button': -> Backbone.Mediator.publish 'tome:comment-my-code', {}
