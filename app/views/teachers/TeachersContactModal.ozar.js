/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TeachersContactModal;
require('app/styles/teachers/teachers-contact-modal.sass');
const ModalView = require('views/core/ModalView');
const State = require('models/State');
const TrialRequests = require('collections/TrialRequests');
const forms = require('core/forms');
const contact = require('core/contact');
const utils = require('core/utils');

module.exports = (TeachersContactModal = (function() {
  TeachersContactModal = class TeachersContactModal extends ModalView {
    static initClass() {
      this.prototype.id = 'teachers-contact-modal';
      this.prototype.template = require('app/templates/teachers/teachers-contact-modal');
  
      this.prototype.events =
        {'submit form': 'onSubmitForm'};
    }

    initialize(options) {
      if (options == null) { options = {}; }
      this.isCodeCombat = utils.isCodeCombat;
      this.state = new State({
        formValues: {
          name: '',
          email: '',
          licensesNeeded: 0,
          message: ''
        },
        formErrors: {},
        sendingState: 'standby' // 'sending', 'sent', 'error'
      });
      this.trialRequests = new TrialRequests();
      this.supermodel.trackRequest(this.trialRequests.fetchOwn());
      return this.state.on('change', this.render, this);
    }

    onLoaded() {
      let left;
      const trialRequest = this.trialRequests.first();
      const props = (trialRequest != null ? trialRequest.get('properties') : undefined) || {};
      const name = props.firstName && props.lastName ? `${props.firstName} ${props.lastName}` : (left = me.get('name')) != null ? left : '';
      const email = me.get('email') || props.email || '';
      const message = `\
Hi Ozaria! I want to learn more about the Classroom experience and get licenses so that my students can access Chapter 2 and on.

Name of School ${props.nces_name || props.organization || ''}
Name of District: ${props.nces_district || props.district || ''}
Role: ${props.role || ''}
Phone Number: ${props.phoneNumber || ''}\
`;
      this.state.set('formValues', { name, email, message });
      return super.onLoaded();
    }

    onSubmitForm(e) {
      e.preventDefault();
      if (this.state.get('sendingState') === 'sending') { return; }

      const formValues = forms.formToObject(this.$el);
      this.state.set('formValues', formValues);

      const formErrors = {};
      if (!formValues.name) {
        formErrors.name = 'Name required.';
      }
      if (!forms.validateEmail(formValues.email)) {
        formErrors.email = 'Invalid email.';
      }
      if (!(parseInt(formValues.licensesNeeded) > 0)) {
        formErrors.licensesNeeded = 'Licenses needed is required.';
      }
      if (!formValues.message) {
        formErrors.message = 'Message required.';
      }
      this.state.set({ formErrors, formValues, sendingState: 'standby' });
      if (!_.isEmpty(formErrors)) { return; }

      this.state.set('sendingState', 'sending');
      const data = _.extend({ country: me.get('country') }, formValues);
      contact.send({
        data,
        context: this,
        success() {
          if (window.tracker != null) {
            window.tracker.trackEvent('Teacher Contact', {
            category: 'Contact',
            licensesNeeded: formValues.licensesNeeded
          }
          );
          }
          this.state.set({ sendingState: 'sent' });
          return setTimeout(() => {
            return (typeof this.hide === 'function' ? this.hide() : undefined);
          }
          , 3000);
        },
        error() { return this.state.set({ sendingState: 'error' }); }
      });

      return this.trigger('submit');
    }
  };
  TeachersContactModal.initClass();
  return TeachersContactModal;
})());
