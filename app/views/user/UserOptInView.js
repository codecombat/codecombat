/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let UserOptInView;
import 'app/styles/user/user-opt-in-view.sass';
import RootView from 'views/core/RootView';
import State from 'models/State';
import template from 'app/templates/user/user-opt-in-view';
import User from 'models/User';
import utils from 'core/utils';

export default UserOptInView = (function() {
  UserOptInView = class UserOptInView extends RootView {
    static initClass() {
      this.prototype.id = 'user-opt-in-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .keep-me-updated-btn': 'onClickKeepMeUpdated',
        'click .login-button': 'onClickLoginButton'
      };
    }

    initialize(options, userID, verificationCode) {
      this.userID = userID;
      this.verificationCode = verificationCode;
      super.initialize(options);
      this.noDeleteInactiveEU = utils.getQueryVariable('no_delete_inactive_eu', false);
      this.keepMeUpdated = utils.getQueryVariable('keep_me_updated', false);
      this.promptKeepMeUpdated = utils.getQueryVariable('prompt_keep_me_updated', false);

      this.state = new State({status: 'loading'});
      this.user = new User({ _id: this.userID });

      if (this.noDeleteInactiveEU) { this.user.sendNoDeleteEUVerificationCode(this.verificationCode); }
      if (this.keepMeUpdated) { this.user.sendKeepMeUpdatedVerificationCode(this.verificationCode); }
      if (!this.keepMeUpdated && !this.noDeleteInactiveEU) { this.state.set({status: 'done loading'}); }

      this.listenTo(this.state, 'change', this.render);
      this.listenTo(this.user, 'user-keep-me-updated-success', () => {
        this.state.set({keepMeUpdatedSuccess: true});
        this.state.set({status: 'done loading'});
        return me.fetch();
      });
      this.listenTo(this.user, 'user-keep-me-updated-error', () => {
        this.state.set({keepMeUpdatedError: true});
        return this.state.set({status: 'done loading'});
      });
      this.listenTo(this.user, 'user-no-delete-eu-success', () => {
        this.state.set({noDeleteEUSuccess: true});
        this.state.set({status: 'done loading'});
        return me.fetch();
      });
      return this.listenTo(this.user, 'user-no-delete-eu-error', () => {
        this.state.set({status: 'done loading'});
        return this.state.set({noDeleteEUError: true});
      });
    }

    onClickKeepMeUpdated(e) {
      return this.user.sendKeepMeUpdatedVerificationCode(this.verificationCode);
    }

    onClickLoginButton(e) {
      const AuthModal = require('views/core/AuthModal');
      return this.openModalView(new AuthModal());
    }
  };
  UserOptInView.initClass();
  return UserOptInView;
})();
