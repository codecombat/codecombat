/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TournamentsListModal;
require('app/styles/courses/tournaments-list-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('templates/courses/tournaments-list-modal');
const DOMPurify = require('dompurify');

module.exports = (TournamentsListModal = (function() {
  TournamentsListModal = class TournamentsListModal extends ModalView {
    static initClass() {
      this.prototype.id = 'tournaments-list-modal';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click #close-modal': 'hide'};
    }

    constructor(options) {
      super(options);
      this.tournamentsByState = options.tournamentsByState;
      this.ladderImageMap = options.ladderImageMap;
    }
  };
  TournamentsListModal.initClass();
  return TournamentsListModal;
})());