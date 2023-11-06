// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RemoveStudentModal;
require('app/styles/courses/remove-student-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/courses/remove-student-modal');

module.exports = (RemoveStudentModal = (function() {
  RemoveStudentModal = class RemoveStudentModal extends ModalView {
    static initClass() {
      this.prototype.id = 'remove-student-modal';
      this.prototype.template = template;

      this.prototype.events =
        {'click #remove-student-btn': 'onClickRemoveStudentButton'};
    }

    constructor (options) {
      super(options)
      this.classroom = options.classroom;
      this.user = options.user;
      this.supermodel.trackRequest(this.user.fetch());
      this.courseInstances = options.courseInstances;
      const request = $.ajax(`/db/classroom/${this.classroom.id}/members/${this.user.id}/is-auto-revokable`);
      this.supermodel.trackRequest(request);
      return request.then(data => {
        return this.willRevokeLicense = data.willRevokeLicense;
      }
      , function(err) {
        return console.error(err, arguments);
      }.bind(this));
    }

    onClickRemoveStudentButton() {
      this.$('#remove-student-buttons').addClass('hide');
      this.$('#remove-student-progress').removeClass('hide');
      const userID = this.user.id;
      this.toRemove = this.courseInstances.filter(courseInstance => _.contains(courseInstance.get('members'), userID));
      this.toRemove.push(this.classroom);
      this.totalJobs = _.size(this.toRemove);
      return this.removeStudent();
    }

    removeStudent() {
      const model = this.toRemove.shift();
      if (!model) {
        this.trigger('remove-student', { user: this.user });
        this.hide();
        return;
      }

      model.removeMember(this.user.id);
      const pct = ((100 * (this.totalJobs - this.toRemove.length)) / this.totalJobs).toFixed(1) + '%';
      this.$('#remove-student-progress .progress-bar').css('width', pct);
      return this.listenToOnce(model, 'sync', function() {
        return this.removeStudent();
      });
    }
  };
  RemoveStudentModal.initClass();
  return RemoveStudentModal;
})());
