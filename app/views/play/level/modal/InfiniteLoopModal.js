/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let InfiniteLoopModal;
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/level/modal/infinite_loop');

module.exports = (InfiniteLoopModal = (function() {
  InfiniteLoopModal = class InfiniteLoopModal extends ModalView {
    static initClass() {
      this.prototype.id = '#infinite-loop-modal';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click #restart-level-infinite-loop-retry-button'() { return Backbone.Mediator.publish('tome:cast-spell', {}); },
        'click #restart-level-infinite-loop-confirm-button'() { return Backbone.Mediator.publish('tome:reset-my-code', {}); },
        'click #restart-level-infinite-loop-comment-button'() { return Backbone.Mediator.publish('tome:comment-my-code', {}); }
      };
    }
  };
  InfiniteLoopModal.initClass();
  return InfiniteLoopModal;
})());
