// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let JoinClassModal;
import ModalView from 'views/core/ModalView';
import template from 'app/templates/courses/join-class-modal';
import Classroom from 'models/Classroom';
import User from 'models/User';

export default JoinClassModal = (function() {
  JoinClassModal = class JoinClassModal extends ModalView {
    static initClass() {
      this.prototype.id = 'join-class-modal';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click .join-class-btn': 'onClickJoinClassButton'};
    }

    initialize(param) {
      if (param == null) { param = {}; }
      const { classCode } = param;
      this.classCode = classCode;
      this.classroom = new Classroom();
      this.teacher = new User();
      const jqxhr = this.supermodel.trackRequest(this.classroom.fetchByCode(this.classCode));
      if (!me.get('emailVerified')) {
        this.supermodel.trackRequest($.post(`/db/user/${me.id}/request-verify-email`));
      }
      this.listenTo(this.classroom, 'error', function() {
        return this.trigger('error');
      });
      this.listenTo(this.classroom, 'sync', function() {
        return this.render;
      });
      this.listenTo(this.classroom, 'join:success', function() {
        return this.trigger('join:success', this.classroom);
      });
      return this.listenTo(this.classroom, 'join:error', function() {
        return this.trigger('join:error', this.classroom, jqxhr);
      });
    }
        // @close()

    onClickJoinClassButton() {
      return this.classroom.joinWithCode(this.classCode);
    }
  };
  JoinClassModal.initClass();
  return JoinClassModal;
})();
