/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let EmailVerifiedView;
import 'app/styles/user/email-verified-view.sass';
import RootView from 'views/core/RootView';
import State from 'models/State';
import template from 'app/templates/user/email-verified-view';
import User from 'models/User';

export default EmailVerifiedView = (function() {
  EmailVerifiedView = class EmailVerifiedView extends RootView {
    static initClass() {
      this.prototype.id = 'email-verified-view';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click .login-button': 'onClickLoginButton'};
    }

    initialize(options, userID, verificationCode) {
      this.userID = userID;
      this.verificationCode = verificationCode;
      super.initialize(options);
      this.state = new State(this.getInitialState());
      this.user = new User({ _id: this.userID });
      this.user.sendVerificationCode(this.verificationCode);

      this.listenTo(this.state, 'change', this.render);
      this.listenTo(this.user, 'email-verify-success', function() {
        this.state.set({ verifyStatus: 'success' });
        return me.fetch();
      });
      return this.listenTo(this.user, 'email-verify-error', function() {
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
})();
