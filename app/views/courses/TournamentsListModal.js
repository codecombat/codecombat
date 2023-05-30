// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TournamentsListModal;
import 'app/styles/courses/tournaments-list-modal.sass';
import ModalView from 'views/core/ModalView';
import template from 'templates/courses/tournaments-list-modal';
import DOMPurify from 'dompurify';

export default TournamentsListModal = (function() {
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
})();