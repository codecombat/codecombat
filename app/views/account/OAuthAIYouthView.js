// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let OAuthAIYouthView;
require('app/styles/account/oauth-aiyouth-view');
const RootView = require('views/core/RootView');
const template = require('templates/account/oauth-aiyouth-view');
const utils = require('core/utils');
const User = require('models/User');

module.exports = (OAuthAIYouthView = (function() {
  OAuthAIYouthView = class OAuthAIYouthView extends RootView {
    static initClass() {
      this.prototype.id = 'oauth-aiyouth-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .confirm-btn': 'onClickConfirmAuth',
        'click .change-btn': 'onClickChangeAccount'
      };
    }


    initialize() {
      let left;
      this.logoutRedirectURL = false;
      window.nextURL = window.location.href;  //for login redirect
      this.token = utils.getQueryVariable('token');
      this.provider = utils.getQueryVariable('provider');

      return this.providerIsBound = _.any((left = me.get('oAuthIdentities')) != null ? left : [], oAuthIdentity => {
        return String(oAuthIdentity.provider) === String(this.provider);
      });
    }


    onClickConfirmAuth() {
      const options = {
        success: () => {
          this.succeed = true;
          return this.render();
        },
        error: () => {
          return noty({ text: '绑定失败，请稍后重试或联系大赛技术支持', type: 'error' });
        }
      };

      return me.confirmBindAIYouth(this.provider, this.token, options);
    }

    onClickChangeAccount() {
      return me.logout();
    }
  };
  OAuthAIYouthView.initClass();
  return OAuthAIYouthView;
})());