// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CoursesNotAssignedModal;
const ModalView = require('views/core/ModalView');
const State = require('models/State');
const template = require('app/templates/courses/courses-not-assigned-modal');

const { STARTER_LICENSE_COURSE_IDS } = require('core/constants');

module.exports = (CoursesNotAssignedModal = (function() {
  CoursesNotAssignedModal = class CoursesNotAssignedModal extends ModalView {
    static initClass() {
      this.prototype.id = 'courses-not-assigned-modal';
      this.prototype.template = template;
    }

    constructor (options) {
      super(options)
      this.i18nData = _.pick(options, ['selected', 'numStudentsWithoutFullLicenses', 'numFullLicensesAvailable']);
      this.state = new State({
        promoteStarterLicenses: false
      });
      if (Array.from(STARTER_LICENSE_COURSE_IDS).includes(options.courseID)) {
        let needle, needle1;
        this.supermodel.trackRequest(me.getLeadPriority())
          // I think the modification of this commit can go to ozar as well: https://github.com/codecombat/codecombat/commit/dd806564d0b2ca7fa3599b4556800fda715ce42b
          .then(({ priority }) => this.state.set({ promoteStarterLicenses:
            me.useStripe() &&
            (priority === 'low') &&
            ((needle = me.get('preferredLanguage'), !['nl-BE', 'nl-NL'].includes(needle))) &&
            ((needle1 = me.get('country'), !['australia', 'taiwan', 'hong-kong', 'netherlands', 'indonesia', 'singapore', 'malaysia'].includes(needle1))) &&
            !__guard__(me.get('administratedTeachers'), x => x.length)
          }));
      }
      this.listenTo(this.state, 'change', this.render);
    }
  };
  CoursesNotAssignedModal.initClass();
  return CoursesNotAssignedModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}