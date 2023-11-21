// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AccountSettingsView;
require('app/styles/account/account-settings-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/account/account-settings-view');
const forms = require('core/forms');
const User = require('models/User');
const ConfirmModal = require('views/core/ConfirmModal');
const {logoutUser, me} = require('core/auth');
const RootView = require('views/core/RootView');
const CreateAccountModal = require('views/core/CreateAccountModal');
const globalVar = require('core/globalVar');
const utils = require('core/utils');
const RobloxButton = require('./robloxButton.vue').default;

module.exports = (AccountSettingsView = (function() {
  AccountSettingsView = class AccountSettingsView extends RootView {
    static initClass() {
      this.prototype.id = 'account-settings-view';
      this.prototype.template = template;
      this.prototype.className = 'countainer-fluid';

      this.prototype.events = {
        'change .panel input': 'onChangePanelInput',
        'change #name-input': 'onChangeNameInput',
        'click #toggle-all-btn': 'onClickToggleAllButton',
        'click #delete-account-btn': 'onClickDeleteAccountButton',
        'click #reset-progress-btn': 'onClickResetProgressButton',
        'click .resend-verification-email': 'onClickResendVerificationEmail',
        'click #save-button': 'save'
      };

      // TODO: After Ozaria launch, when redoing this page - do we still need this weird shortcut?
      this.prototype.shortcuts =
        {'enter'() { return this; }};
    }

    getMeta() {
      return {title: $.i18n.t('account.settings_title')};
    }

    afterRender() {
      super.afterRender();
      this.listenTo(this, 'input-changed', this.onInputChanged);
      this.listenTo(this, 'save-user-began', this.onUserSaveBegan);
      this.listenTo(this, 'save-user-success', this.onUserSaveSuccess);
      this.listenTo(this, 'save-user-error', this.onUserSaveError);

      return this.robloxButton = new RobloxButton({ propsData: { size: 'small' }, el: this.$el.find('#roblox-button')[0] });
    }

    afterInsert() {
      if (me.get('anonymous')) { return this.openModalView(new CreateAccountModal()); }
    }

    onInputChanged() {
      return this.$el.find('#save-button')
        .text($.i18n.t('common.save', {defaultValue: 'Save'}))
        .addClass('btn-info')
        .removeClass('disabled btn-danger')
        .removeAttr('disabled');
    }

    onUserSaveBegan() {
      return this.$el.find('#save-button')
        .text($.i18n.t('common.saving', {defaultValue: 'Saving...'}))
        .removeClass('btn-danger')
        .addClass('btn-success').show();
    }

    onUserSaveSuccess() {
      return this.$el.find('#save-button')
        .text($.i18n.t('account_settings.saved', {defaultValue: 'Changes Saved'}))
        .removeClass('btn-success btn-info', 1000)
        .attr('disabled', 'true');
    }

    onUserSaveError() {
      return this.$el.find('#save-button')
        .text($.i18n.t('account_settings.error_saving', {defaultValue: 'Error Saving'}))
        .removeClass('btn-success')
        .addClass('btn-danger', 500);
    }

    constructor () {
      super(...arguments)
      this.uploadFilePath = `db/user/${me.id}`;
      this.user = new User({_id: me.id});
      this.supermodel.trackRequest(this.user.fetch()); // use separate, fresh User object instead of `me`
      this.utils = utils
    }

    getEmailSubsDict() {
      const subs = {};
      for (var sub of Array.from(this.user.getEnabledEmails())) { subs[sub] = 1; }
      return subs;
    }

    //- Form input callbacks
    onChangePanelInput(e) {
      let needle;
      if ((needle = $(e.target).closest('.form').attr('id'), ['reset-progress-form', 'delete-account-form'].includes(needle))) { return; }
      $(e.target).addClass('changed');
      return this.trigger('input-changed');
    }

    onClickToggleAllButton() {
      const subs = this.getSubscriptions();
      $('#email-panel input[type="checkbox"]', this.$el).prop('checked', !_.any(_.values(subs))).addClass('changed');
      return this.trigger('input-changed');
    }

    onChangeNameInput() {
      const name = $('#name-input', this.$el).val();
      if (name === this.user.get('name')) { return; }
      return User.getUnconflictedName(name, newName => {
        forms.clearFormAlerts(this.$el);
        if (name === newName) {
          return this.suggestedName = undefined;
        } else {
          this.suggestedName = newName;
          return forms.setErrorToProperty(this.$el, 'name', `That name is taken! How about ${newName}?`, true);
        }
      });
    }

    onClickDeleteAccountButton(e) {
      return this.validateCredentialsForDestruction(this.$el.find('#delete-account-form'), () => {
        const renderData = {
          title: 'Are you really sure?',
          body: 'This will completely delete your account. This action CANNOT be undone. Are you entirely sure?',
          decline: 'Cancel',
          confirm: 'DELETE Your Account'
        };
        const confirmModal = new ConfirmModal(renderData);
        confirmModal.on('confirm', this.deleteAccount, this);
        return this.openModalView(confirmModal);
      });
    }

    onClickResetProgressButton() {
      return this.validateCredentialsForDestruction(this.$el.find('#reset-progress-form'), () => {
        const renderData = {
          title: 'Are you really sure?',
          body: 'This will completely erase your progress: code, levels, achievements, earned gems, and course work. This action CANNOT be undone. Are you entirely sure?',
          decline: 'Cancel',
          confirm: 'Erase ALL Progress'
        };
        const confirmModal = new ConfirmModal(renderData);
        confirmModal.on('confirm', this.resetProgress, this);
        return this.openModalView(confirmModal);
      });
    }

    onClickResendVerificationEmail(e) {
      return $.post(this.user.getRequestVerificationEmailURL(), function() {
        const link = $(e.currentTarget);
        link.find('.resend-text').addClass('hide');
        return link.find('.sent-text').removeClass('hide');
      });
    }

    validateCredentialsForDestruction($form, onSuccess) {
      let needle;
      forms.clearFormAlerts($form);
      const enteredEmailOrUsername = $form.find('input[name="emailOrUsername"]').val();
      const enteredPassword = $form.find('input[name="password"]').val();
      if (enteredEmailOrUsername && (needle = enteredEmailOrUsername, [this.user.get('email'), this.user.get('name')].includes(needle))) {
        let isPasswordCorrect = false;
        let toBeDelayed = true;
        $.ajax({
          url: '/auth/login',
          type: 'POST',
          data: {
            username: enteredEmailOrUsername,
            password: enteredPassword
          },
          parse: true,
          error(error) {
            toBeDelayed = false;
            return 'Bad Error. Can\'t connect to server or something. ' + error;
          },
          success(response, textStatus, jqXHR) {
            toBeDelayed = false;
            if (jqXHR.status !== 200) { return; }
            return isPasswordCorrect = true;
          }
        });
        var callback = () => {
          if (toBeDelayed) {
            return setTimeout(callback, 100);
          } else {
            if (isPasswordCorrect) {
              return onSuccess();
            } else {
              const message = $.i18n.t('account_settings.wrong_password', {defaultValue: 'Wrong Password.'});
              const err = [{message, property: 'password', formatted: true}];
              forms.applyErrorsToForm($form, err);
              return $('.nano').nanoScroller({scrollTo: this.$el.find('.has-error')});
            }
          }
        };
        return setTimeout(callback, 100);
      } else {
        const message = $.i18n.t('account_settings.wrong_email', {defaultValue: 'Wrong Email or Username.'});
        const err = [{message, property: 'emailOrUsername', formatted: true}];
        forms.applyErrorsToForm($form, err);
        return $('.nano').nanoScroller({scrollTo: this.$el.find('.has-error')});
      }
    }

    deleteAccount() {
      return $.ajax({
        type: 'DELETE',
        success() {
          noty({
            timeout: 5000,
            text: 'Your account is gone.',
            type: 'success',
            layout: 'topCenter'
          });
          return _.delay(function() {
            if (globalVar.application.isIPadApp) { __guard__(__guard__(__guard__(typeof window !== 'undefined' && window !== null ? window.webkit : undefined, x2 => x2.messageHandlers), x1 => x1.notification), x => x.postMessage({name: "signOut"})); }
            Backbone.Mediator.publish("auth:logging-out", {});
            if (utils.isCodeCombat) { // maybe ozaria also want it?
              if (this.id === 'home-view') { if (window.tracker != null) {
                window.tracker.trackEvent('Log Out', {category:'Homepage'});
              } }
            }
            return logoutUser();
          }
          , 500);
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return noty({
            timeout: 5000,
            text: `Deleting account failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          });
        },
        url: `/db/user/${this.user.id}`
      });
    }

    resetProgress() {
      return $.ajax({
        type: 'POST',
        success: () => {
          noty({
            timeout: 5000,
            text: 'Your progress is gone.',
            type: 'success',
            layout: 'topCenter'
          });
          localStorage.clear();
          this.user.fetch({cache: false});
          return _.delay((() => window.location.reload()), 1000);
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return noty({
            timeout: 5000,
            text: `Resetting progress failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          });
        },
        url: `/db/user/${this.user.id}/reset_progress`
      });
    }


    //- Misc

    getSubscriptions() {
      let i;
      const inputs = ((() => {
        const result = [];
        for (i of Array.from($('#email-panel input[type="checkbox"].changed', this.$el))) {           result.push($(i));
        }
        return result;
      })());
      const emailNames = ((() => {
        const result1 = [];
        for (i of Array.from(inputs)) {           result1.push(i.attr('name').replace('email_', ''));
        }
        return result1;
      })());
      const enableds = ((() => {
        const result2 = [];
        for (i of Array.from(inputs)) {           result2.push(i.prop('checked'));
        }
        return result2;
      })());
      return _.zipObject(emailNames, enableds);
    }


    //- Saving changes

    save() {
      $('#settings-tabs input').removeClass('changed');
      forms.clearFormAlerts(this.$el);
      this.grabData();
      let res = this.user.validate();
      if (res != null) {
        console.error('Couldn\'t save because of validation errors:', res);
        forms.applyErrorsToForm(this.$el, res);
        $('.nano').nanoScroller({scrollTo: this.$el.find('.has-error')});
        return;
      }

      if (!this.user.hasLocalChanges()) { return; }

      res = this.user.patch();
      if (!res) { return; }

      res.error(() => {
        if (res.responseJSON != null ? res.responseJSON.property : undefined) {
          const errors = res.responseJSON;
          forms.applyErrorsToForm(this.$el, errors);
          $('.nano').nanoScroller({scrollTo: this.$el.find('.has-error')});
        } else {
          noty({
            text: (res.responseJSON != null ? res.responseJSON.message : undefined) || res.responseText,
            type: 'error',
            layout: 'topCenter',
            timeout: 5000
          });
        }
        return this.trigger('save-user-error');
      });
      res.success((model, response, options) => {
        me.set(model); // save changes to me
        return this.trigger('save-user-success');
      });

      return this.trigger('save-user-began');
    }

    grabData() {
      this.grabPasswordData();
      return this.grabOtherData();
    }

    grabPasswordData() {
      let err, message;
      const currentPassword = $('#current-password', this.$el).val();
      const password1 = $('#password', this.$el).val();
      const password2 = $('#password2', this.$el).val();
      const bothThere = Boolean(password1) && Boolean(password2);
      if (bothThere && (password1 !== password2)) {
        message = $.i18n.t('account_settings.password_mismatch', {defaultValue: 'Password does not match.'});
        err = [{message, property: 'password2', formatted: true}];
        forms.applyErrorsToForm(this.$el, err);
        $('.nano').nanoScroller({scrollTo: this.$el.find('.has-error')});
        return;
      }
      if (bothThere) {
        return this.user.updatePassword(currentPassword, password1, (() => {
          return this.trigger('save-user-success');
        }
        ), (res => {
          if (res.responseJSON != null ? res.responseJSON.property : undefined) {
            const errors = res.responseJSON;
            forms.applyErrorsToForm(this.$el, errors);
            $('.nano').nanoScroller({scrollTo: this.$el.find('.has-error')});
          } else {
            noty({
              text: (res.responseJSON != null ? res.responseJSON.message : undefined) || res.responseText,
              type: 'error',
              layout: 'topCenter',
              timeout: 5000
            });
          }
          return this.trigger('save-user-error');
        })
        );
      } else if (password1) {
        message = $.i18n.t('account_settings.password_repeat', {defaultValue: 'Please repeat your password.'});
        err = [{message, property: 'password2', formatted: true}];
        forms.applyErrorsToForm(this.$el, err);
        return $('.nano').nanoScroller({scrollTo: this.$el.find('.has-error')});
      }
    }

    grabOtherData() {
      if (this.suggestedName) { this.$el.find('#name-input').val(this.suggestedName); }
      this.user.set('name', this.$el.find('#name-input').val());
      this.user.set('firstName', this.$el.find('#first-name-input').val());
      this.user.set('lastName', this.$el.find('#last-name-input').val());
      this.user.set('email', this.$el.find('#email').val());
      const object = this.getSubscriptions();
      for (var emailName in object) {
        var enabled = object[emailName];
        this.user.setEmailSubscription(emailName, enabled);
      }

      const permissions = [];

      if (!application.isProduction()) {
        const adminCheckbox = this.$el.find('#admin');
        if (adminCheckbox.length) {
          if (adminCheckbox.prop('checked')) { permissions.push('admin'); }
        }
        const godmodeCheckbox = this.$el.find('#godmode');
        if (godmodeCheckbox.length) {
          if (godmodeCheckbox.prop('checked')) { permissions.push('godmode'); }
        }
        return this.user.set('permissions', permissions);
      }
    }

    destroy() {
      if (this.robloxButton != null) {
        this.robloxButton.$destroy();
      }
      return super.destroy();
    }
  };
  AccountSettingsView.initClass();
  return AccountSettingsView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}