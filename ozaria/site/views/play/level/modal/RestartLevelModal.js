/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RestartLevelModal;
require('ozaria/site/styles/core/modal-base.scss');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/play/level/modal/restart-level-modal');

module.exports = (RestartLevelModal = (function() {
  RestartLevelModal = class RestartLevelModal extends ModalView {
    static initClass() {
      this.prototype.id = '#restart-level-modal';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click #restart-level-confirm-button': 'onClickRestart'};
    }

    onClickRestart(e) {
      return Backbone.Mediator.publish('level:restart', {});
    }
  };
  RestartLevelModal.initClass();
  return RestartLevelModal;
})());
