/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let UserOptInView;
require('app/styles/user/user-opt-in-view.sass');
const RootView = require('views/core/RootView');
const State = require('models/State');
const template = require('app/templates/user/user-opt-in-view');
const User = require('models/User');
const utils = require('core/utils');

module.exports = (UserOptInView = (function() {
  UserOptInView = class UserOptInView extends RootView {
    static initClass() {
      this.prototype.id = 'user-opt-in-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click .keep-me-updated-btn': 'onClickKeepMeUpdated',
        'click .login-button': 'onClickLoginButton'
      };
    }

    constructor (options, userID, verificationCode) {
      super(options)
      this.userID = userID;
      this.verificationCode = verificationCode;
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
      this.listenTo(this.user, 'user-no-delete-eu-error', () => {
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
})());
