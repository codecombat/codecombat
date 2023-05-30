/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SingleSignOnAlreadyExistsView;
require('app/styles/modal/create-account-modal/sso-already-exists-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/core/create-account-modal/single-sign-on-already-exists-view');
const forms = require('core/forms');
const User = require('models/User');

module.exports = (SingleSignOnAlreadyExistsView = (function() {
  SingleSignOnAlreadyExistsView = class SingleSignOnAlreadyExistsView extends CocoView {
    static initClass() {
      this.prototype.id = 'single-sign-on-already-exists-view';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click .back-button': 'onClickBackButton'};
    }

    initialize({ signupState }) {
      this.signupState = signupState;
    }

    onClickBackButton() {
      this.signupState.set({
        ssoUsed: undefined,
        ssoAttrs: undefined
      });
      return this.trigger('nav-back');
    }
  };
  SingleSignOnAlreadyExistsView.initClass();
  return SingleSignOnAlreadyExistsView;
})());
