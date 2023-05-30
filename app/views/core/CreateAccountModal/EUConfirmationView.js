/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let EUConfirmationView;
require('app/styles/modal/create-account-modal/eu-confirmation-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/core/create-account-modal/eu-confirmation-view');
const forms = require('core/forms');
const Classroom = require('models/Classroom');
const State = require('models/State');

module.exports = (EUConfirmationView = (function() {
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
})());
