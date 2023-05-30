// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AuthModal;
import 'app/styles/modal/auth-modal.sass';
import ModalView from 'views/core/ModalView';
import template from 'app/templates/core/auth-modal';
import forms from 'core/forms';
import User from 'models/User';
import errors from 'core/errors';
import RecoverModal from 'views/core/RecoverModal';
import storage from 'core/storage';
import globalVar from 'core/globalVar';
import userUtils from '../../lib/user-utils';

export default AuthModal = (function() {
  AuthModal = class AuthModal extends ModalView {
    constructor(...args) {
      this.onGPlusLoginError = this.onGPlusLoginError.bind(this);
      this.onFacebookLoginError = this.onFacebookLoginError.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.id = 'auth-modal';
      this.prototype.template = template;
      this.prototype.trapsFocus = false;  // TODO: re-enable this in a way that doesn't break Google login Noty
  
      this.prototype.events = {
        'click #switch-to-signup-btn': 'onSignupInstead',
        'submit form': 'onSubmitForm',
        'keyup #name': 'onNameChange',
        'click #google-login-button': 'onClickGPlusLoginButton',
        'click #facebook-login-btn': 'onClickFacebookLoginButton',
        'click #clever-signup-btn': 'onClickCleverSignupButton',
        'click #close-modal': 'hide',
        'click [data-toggle="coco-modal"][data-target="core/RecoverModal"]': 'openRecoverModal'
      };
    }

    // Initialization

    initialize(options) {
      if (options == null) { options = {}; }
      this.previousFormInputs = options.initialValues || {};
      if (this.previousFormInputs.emailOrUsername == null) { this.previousFormInputs.emailOrUsername = this.previousFormInputs.email || this.previousFormInputs.username; }

      if (me.useSocialSignOn()) {
        // TODO: Switch to promises and state, rather than using defer to hackily enable buttons after render
        application.gplusHandler.loadAPI({ success: () => _.defer(() => {
          this.$('#google-login-button').attr('disabled', false);
          return this.onClickGPlusLoginButton();
        })
        });
        application.facebookHandler.loadAPI({ success: () => _.defer(() => this.$('#facebook-login-btn').attr('disabled', false)) });
      }
      this.subModalContinue = options.subModalContinue;
      return this.showLibraryModal = userUtils.shouldShowLibraryLoginModal();
    }

    afterRender() {
      super.afterRender();
      return this.playSound('game-menu-open');
    }

    afterInsert() {
      super.afterInsert();
      return _.delay((() => $('input:visible:first', this.$el).focus()), 500);
    }

    onSignupInstead(e) {
      const CreateAccountModal = require('./CreateAccountModal');
      const modal = new CreateAccountModal({initialValues: forms.formToObject(this.$el, this.subModalContinue)});
      return globalVar.currentView.openModalView(modal);
    }

    onSubmitForm(e) {
      this.playSound('menu-button-click');
      e.preventDefault();
      forms.clearFormAlerts(this.$el);
      this.$('#unknown-error-alert').addClass('hide');
      const userObject = forms.formToObject(this.$el);
      const res = tv4.validateMultiple(userObject, formSchema);
      if (!res.valid) { return forms.applyErrorsToForm(this.$el, res.errors); }
      let showingError = false;
      return new Promise(me.loginPasswordUser(userObject.emailOrUsername, userObject.password).then)
      .catch(jqxhr => {
        if (jqxhr.status === 401) {
          const {
            errorID
          } = jqxhr.responseJSON;
          if (errorID === 'not-found') {
            forms.setErrorToProperty(this.$el, 'emailOrUsername', $.i18n.t('loading_error.user_not_found'));
            showingError = true;
          }
          if (errorID === 'wrong-password') {
            forms.setErrorToProperty(this.$el, 'password', $.i18n.t('account_settings.wrong_password'));
            showingError = true;
          }
          if (errorID === 'temp-password-expired') {
            forms.setErrorToProperty(this.$el, 'password', $.i18n.t('account_settings.temp_password_expired'));
            showingError = true;
          }
        } else if (jqxhr.status === 429) {
          showingError = true;
          forms.setErrorToProperty(this.$el, 'emailOrUsername', $.i18n.t('loading_error.too_many_login_failures'));
        }

        if (!showingError) {
          return this.$('#unknown-error-alert').removeClass('hide');
        }
      })
      .then(() => {
        application.tracker.identifyAfterNextPageLoad();
        return application.tracker.identify();
      })
      .finally(() => {
        if (!showingError) {
          if (window.nextURL) {
            return window.location.href = window.nextURL;
          } else {
            return loginNavigate(this.subModalContinue);
          }
        }
      });
    }


    // Google Plus

    onClickGPlusLoginButton() {
      const btn = this.$('#google-login-button');
      return application.gplusHandler.connect({
        context: this,
        success(resp) {
          if (resp == null) { resp = {}; }
          btn.find('.sign-in-blurb').text($.i18n.t('login.logging_in'));
          btn.attr('disabled', true);
          return application.gplusHandler.loadPerson({
            resp,
            context: this,
            success(gplusAttrs) {
              const existingUser = new User();
              return existingUser.fetchGPlusUser(gplusAttrs.gplusID, gplusAttrs.email, {
                success: () => {
                  return me.loginGPlusUser(gplusAttrs.gplusID, {
                    success: () => {
                      application.tracker.identifyAfterNextPageLoad();
                      return application.tracker.identify().finally(() => {
                        return loginNavigate(this.subModalContinue);
                      });
                    },
                    error: this.onGPlusLoginError
                  });
                },
                error: (res, jqxhr) => {
                  if ((jqxhr.status === 409) && jqxhr.responseJSON.errorID && (jqxhr.responseJSON.errorID === 'account-with-email-exists')) {
                    return noty({ text: $.i18n.t('login.accounts_merge_confirmation'), layout: 'topCenter', type: 'info', buttons: [
                      { text: 'Yes', onClick($noty) {
                        $noty.close();
                        return me.loginGPlusUser(gplusAttrs.gplusID, {
                          data: { merge: true, email: gplusAttrs.email },
                          success: () => {
                            application.tracker.identifyAfterNextPageLoad();
                            return application.tracker.identify().finally(() => {
                              return loginNavigate(this.subModalContinue);
                            });
                          },
                          error: this.onGPlusLoginError
                        });
                      }
                      }, { text: 'No', onClick($noty) { return $noty.close(); } }]
                    });
                  } else {
                    return this.onGPlusLoginError(res, jqxhr);
                  }
                }
              });
            }
          });
        },
        error(e) {
          this.onGPlusLoginError();
          if ((e != null ? e.error : undefined) && (e != null ? e.details : undefined)) { if (!e.message) { e.message = `Google login failed: ${e.error} - ${e.details}`; } }
          return noty({text: (e != null ? e.message : undefined) || (e != null ? e.details : undefined) || __guardMethod__(e, 'toString', o => o.toString()) || 'Unknown Google login error', layout: 'topCenter', type: 'error', timeout: 5000, killer: false, dismissQueue: true});
        }
      });
    }

    onGPlusLoginError() {
      const btn = this.$('#google-login-button');
      btn.find('.sign-in-blurb').text($.i18n.t('login.sign_in_with_gplus'));
      btn.attr('disabled', false);
      if (arguments.length) { return errors.showNotyNetworkError(...arguments); }
    }


    // Facebook

    onClickFacebookLoginButton() {
      const btn = this.$('#facebook-login-btn');
      return application.facebookHandler.connect({
        context: this,
        success() {
          btn.find('.sign-in-blurb').text($.i18n.t('login.logging_in'));
          btn.attr('disabled', true);
          return application.facebookHandler.loadPerson({
            context: this,
            success(facebookAttrs) {
              const existingUser = new User();
              return existingUser.fetchFacebookUser(facebookAttrs.facebookID, {
                success: () => {
                  return me.loginFacebookUser(facebookAttrs.facebookID, {
                    success: () => {
                      application.tracker.identifyAfterNextPageLoad();
                      return application.tracker.identify().then(() => {
                        return loginNavigate(this.subModalContinue);
                      });
                    },
                    error: this.onFacebookLoginError
                  });
                },
                error: this.onFacebookLoginError
              });
            }
          });
        }
      });
    }

    onFacebookLoginError() {
      const btn = this.$('#facebook-login-btn');
      btn.find('.sign-in-blurb').text($.i18n.t('login.sign_in_with_facebook'));
      btn.attr('disabled', false);
      return errors.showNotyNetworkError(...arguments);
    }


    // Clever

    onClickCleverSignupButton() {
      let cleverClientId, districtId, redirectTo;
      if (['next.codecombat.com', 'localhost'].includes(window.location.hostname)) {
        cleverClientId = '943ece596555cac13fcc';
        redirectTo = 'https://next.codecombat.com/auth/login-clever';
        districtId = '5b2ad81a709e300001e2cd7a';  // Clever Library test district
      } else {  // prod
        cleverClientId = 'ffce544a7e02c0daabf2';
        redirectTo = 'https://codecombat.com/auth/login-clever';
      }
      let url = `https://clever.com/oauth/authorize?response_type=code&redirect_uri=${encodeURIComponent(redirectTo)}&client_id=${cleverClientId}`;
      if (districtId) {
        url += '&district_id=' + districtId;
      }
      return window.open(url, '_blank');
    }


    openRecoverModal(e) {
      e.stopPropagation();
      return this.openModalView(new RecoverModal());
    }

    onHidden() {
      super.onHidden();
      return this.playSound('game-menu-close');
    }
  };
  AuthModal.initClass();
  return AuthModal;
})();

var formSchema = {
  type: 'object',
  properties: {
    emailOrUsername: {
      $or: [
        User.schema.properties.name,
        User.schema.properties.email
      ]
    }
  },
  required: ['emailOrUsername', 'password']
};

var loginNavigate = function(subModalContinue) {
  if (window.nextURL) {
    window.location.href = window.nextURL;
    return;
  }

  if (!me.isAdmin()) {
    if (me.isAPIClient()) {
        application.router.navigate('/api-dashboard', { trigger: true });
    } else if (me.isStudent()) {
      application.router.navigate('/students', { trigger: true });
    } else if (me.isTeacher()) {
      if (me.isSchoolAdmin()) {
        application.router.navigate('/teachers/licenses', { trigger: true });
      } else {
        application.router.navigate('/teachers/classes', { trigger: true });
      }
    } else if (me.isParentHome()) {
      const routeStr = me.hasNoVerifiedChild() ? '/parents/add-another-child' : '/parents/dashboard';
      application.router.navigate(routeStr, { trigger: true });
    }
  } else if (subModalContinue) {
    storage.save('sub-modal-continue', subModalContinue);
  }

  return window.location.reload();
};

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}