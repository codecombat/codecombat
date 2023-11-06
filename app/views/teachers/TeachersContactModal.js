/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
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
const {sendSlackMessage} = require('core/contact');

module.exports = (TeachersContactModal = (function() {
  TeachersContactModal = class TeachersContactModal extends ModalView {
    static initClass() {
      this.prototype.id = 'teachers-contact-modal';
      this.prototype.template = require('app/templates/teachers/teachers-contact-modal');

      this.prototype.events = {
        'submit form': 'onSubmitForm',
        'change #form-licensesNeeded': 'onLicenseNeededChange'
      };
    }

    constructor (options) {
      if (options == null) { options = {}; }
      super(options)
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
      this.shouldUpsell = options.shouldUpsell;
      this.shouldUpsellParent = options.shouldUpsellParent;
      this.trialRequests = new TrialRequests();
      this.supermodel.trackRequest(this.trialRequests.fetchOwn());
      this.state.on('change', this.render, this);
    }

    onLoaded() {
      try {
        const defaultData = this.getDefaultData();
        this.state.set('formValues', defaultData);
        this.logContactFlowToSlack({
          event: 'Done loading',
          message: `name: ${defaultData.name}, email: ${defaultData.email}`
        });
      } catch (e) {
        this.logContactFlowToSlack({
          event: 'Done loading',
          error: e
        });
        console.error(e);
      }

      return super.onLoaded();
    }

    onSubmitForm(e) {
      try {
        this.logContactFlowToSlack({
          event: 'Submitting',
          message: `Beginning. sendingState: ${this.state.get('sendingState')}`
        });
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

        this.logContactFlowToSlack({
          event: 'Submitting',
          message: `Validating. name: ${formErrors.name || formValues.name}, email: ${formErrors.email || formValues.email}, licensesNeeded: ${formErrors.licensesNeeded || formValues.licensesNeeded}, message: ${formErrors.message || formValues.message}`
        });

        if (!_.isEmpty(formErrors)) { return; }

        this.state.set('sendingState', 'sending');
        const data = _.extend({ country: me.get('country') }, formValues);
        this.logContactFlowToSlack({
          event: 'Submitting',
          message: `Sending. email: ${formValues.email}`
        });
        contact.send({
          data,
          context: this,
          success() {
            this.logContactFlowToSlack({
              event: 'Submitting',
              message: `Successfully sent. email: ${formValues.email}`
            });
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
          error() {
            this.logContactFlowToSlack({
              event: 'Submitting',
              message: `Error sending! email: ${formValues.email}`
            });
            return this.state.set({ sendingState: 'error' });
          }
        });

        return this.trigger('submit');
      } catch (error) {
        e = error;
        return this.logContactFlowToSlack({
          event: 'Submitting',
          message: `General error! error: ${e}`
        });
      }
    }

    logContactFlowToSlack(data) {
      data.channel = 'contact-feed';
      // /teachers/licenses, /teachers/licenses/v0, /teachers/starter-licenses, etc.
      if (/licenses/.test(__guard__(typeof window !== 'undefined' && window !== null ? window.location : undefined, x => x.pathname))) {
        data.channel = 'sales-feed';
      }
      return sendSlackMessage(data);
    }

    getDefaultData(override) {
      let left;
      if (override == null) { override = {}; }
      const trialRequest = this.trialRequests.first();
      const props = (trialRequest != null ? trialRequest.get('properties') : undefined) || {};
      const name = props.firstName && props.lastName ? `${props.firstName} ${props.lastName}` : (left = me.get('name')) != null ? left : '';
      const email = me.get('email') || props.email || '';
      const message = `\
Hi CodeCombat! I want to learn more about the Classroom experience and get licenses so that my students can access Computer Science 2 and on.

Name of School ${props.nces_name || props.organization || ''}
Name of District: ${props.nces_district || props.district || ''}
Role: ${props.role || ''}
Phone Number: ${props.phoneNumber || ''}\
`;
      let licensesNeeded = 0;
      if (override.licensesNeeded) {
        ({
          licensesNeeded
        } = override);
      }
      return { name, email, message, licensesNeeded };
    }

    onLicenseNeededChange(e) {
      const licensesNeeded = parseInt(e.target.value);
      if (isNaN(licensesNeeded) || (licensesNeeded <= 0)) {
        return;
      }
      if (this.shouldUpsellParent && (licensesNeeded < 6)) {
        this.state.set('showParentsUpsell', true);
      } else if (this.shouldUpsell && (licensesNeeded < 10)) {
        this.state.set('showUpsell', true);
      } else {
        this.state.set('showParentsUpsell', false);
        this.state.set('showUpsell', false);
      }
      return this.state.set('formValues', this.getDefaultData({ licensesNeeded }));
    }
  };
  TeachersContactModal.initClass();
  return TeachersContactModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}