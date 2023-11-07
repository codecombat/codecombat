/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let EmailVerifiedView;
require('app/styles/user/email-verified-view.sass');
const RootView = require('views/core/RootView');
const State = require('models/State');
const template = require('app/templates/user/email-verified-view');
const User = require('models/User');

module.exports = (EmailVerifiedView = (function() {
  EmailVerifiedView = class EmailVerifiedView extends RootView {
    static initClass() {
      this.prototype.id = 'email-verified-view';
      this.prototype.template = template;

      this.prototype.events =
        {'click .login-button': 'onClickLoginButton'};
    }

    constructor (options, userID, verificationCode) {
      super(...arguments)
      this.userID = userID;
      this.verificationCode = verificationCode;
      this.state = new State(this.getInitialState());
      this.user = new User({ _id: this.userID });
      this.user.sendVerificationCode(this.verificationCode);

      this.listenTo(this.state, 'change', this.render);
      this.listenTo(this.user, 'email-verify-success', function() {
        this.state.set({ verifyStatus: 'success' });
        return me.fetch();
      });
      this.listenTo(this.user, 'email-verify-error', function() {
        return this.state.set({ verifyStatus: 'error' });
      });
    }

    getInitialState() {
      return {verifyStatus: 'pending'};
    }

    onClickLoginButton(e) {
      const AuthModal = require('views/core/AuthModal');
      return this.openModalView(new AuthModal());
    }
  };
  EmailVerifiedView.initClass();
  return EmailVerifiedView;
})());
