// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CoppaDenyView;
import 'app/styles/modal/create-account-modal/coppa-deny-view.sass';
import CocoView from 'views/core/CocoView';
import State from 'models/State';
import template from 'app/templates/core/create-account-modal/coppa-deny-view';
import forms from 'core/forms';
import contact from 'core/contact';

export default CoppaDenyView = (function() {
  CoppaDenyView = class CoppaDenyView extends CocoView {
    static initClass() {
      this.prototype.id = 'coppa-deny-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .send-parent-email-button': 'onClickSendParentEmailButton',
        'change input[name="parentEmail"]': 'onChangeParentEmail',
        'click .back-btn': 'onClickBackButton'
      };
    }

    initialize(param) {
      if (param == null) { param = {}; }
      const { signupState } = param;
      this.signupState = signupState;
      this.state = new State({ parentEmail: '' });
      return this.listenTo(this.state, 'all', _.debounce(this.render));
    }

    onChangeParentEmail(e) {
      const parentEmail = $(e.currentTarget).val();
      this.state.set({ parentEmail }, { silent: true });
      if (/team@codecombat.com/i.test(parentEmail)) {
        return this.state.set({ dontUseOurEmailSilly: true });
      } else {
        return this.state.set({ dontUseOurEmailSilly: false, silent: true });
      }
    }

    onClickSendParentEmailButton(e) {
      e.preventDefault();
      this.state.set({ parentEmailSending: true });
      if (window.tracker != null) {
        window.tracker.trackEvent('CreateAccountModal Student CoppaDenyView Send Clicked', {category: 'Students'});
      }
      return contact.sendParentSignupInstructions(this.state.get('parentEmail'))
        .then(() => {
          return this.state.set({ error: false, parentEmailSent: true, parentEmailSending: false });
      }).catch(() => {
          return this.state.set({ error: true, parentEmailSent: false, parentEmailSending: false });
      });
    }

    onClickBackButton() {
      if (this.signupState.get('path') === 'student') {
        if (window.tracker != null) {
          window.tracker.trackEvent('CreateAccountModal Student CoppaDenyView Back Clicked', {category: 'Students'});
        }
      }
      return this.trigger('nav-back');
    }
  };
  CoppaDenyView.initClass();
  return CoppaDenyView;
})();
