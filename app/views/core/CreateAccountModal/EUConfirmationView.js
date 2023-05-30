// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let EUConfirmationView;
import 'app/styles/modal/create-account-modal/eu-confirmation-view.sass';
import CocoView from 'views/core/CocoView';
import template from 'app/templates/core/create-account-modal/eu-confirmation-view';
import forms from 'core/forms';
import Classroom from 'models/Classroom';
import State from 'models/State';

export default EUConfirmationView = (function() {
  EUConfirmationView = class EUConfirmationView extends CocoView {
    static initClass() {
      this.prototype.id = 'eu-confirmation-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .back-button'() { return this.trigger('nav-back'); },
        'click .forward-button'() { return this.trigger('nav-forward'); },
        'change #eu-confirmation-checkbox': 'onChangeEUConfirmationCheckbox'
      };
    }

    initialize(param) {
      if (param == null) { param = {}; }
      const { signupState } = param;
      this.signupState = signupState;
      return this.state = new State();
    }

    onChangeEUConfirmationCheckbox(e) {
      this.state.set('euConfirmationGranted', $(e.target).is(':checked'));
      return this.$('.forward-button').attr('disabled', !$(e.target).is(':checked'));
    }
  };
  EUConfirmationView.initClass();
  return EUConfirmationView;
})();
