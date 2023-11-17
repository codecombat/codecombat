// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PrepaidView;
require('app/styles/account/account-prepaid-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/account/prepaid-view');
const {getPrepaidCodeAmount} = require('../../core/utils');
const SubscribeModal = require('views/core/SubscribeModal');
const CocoCollection = require('collections/CocoCollection');
const Prepaid = require('../../models/Prepaid');
const utils = require('core/utils');
const Products = require('collections/Products');
const CreateAccountModal = require('views/core/CreateAccountModal/CreateAccountModal');

module.exports = (PrepaidView = (function() {
  PrepaidView = class PrepaidView extends RootView {
    constructor(...args) {
      this.dashedPPC = this.dashedPPC.bind(this);
      this.onClickStartSubscription = this.onClickStartSubscription.bind(this);
      this.confirmRedeem = this.confirmRedeem.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.id = 'prepaid-view';
      this.prototype.template = template;
      this.prototype.className = 'container-fluid';
  
      this.prototype.events = {
        'click #lookup-code-btn': 'onClickLookupCodeButton',
        'click #redeem-code-btn': 'onClickRedeemCodeButton',
        'click .start-subscription-button': 'onClickStartSubscription'
      };
    }

    initialize() {
      let left;
      super.initialize();

      // HACK: Make this one specific page responsive on mobile.
      $('head').append('<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;">');

      this.codes = new CocoCollection([], { url: '/db/user/'+me.id+'/prepaid_codes', model: Prepaid });
      this.codes.on('sync', code => (typeof this.render === 'function' ? this.render() : undefined));
      this.supermodel.loadCollection(this.codes, {cache: false});

      this.ppc = (left = utils.getQueryVariable('_ppc')) != null ? left : '';
      if (!_.isEmpty(this.ppc)) {
        this.ppcQuery = true;
        return this.loadPrepaid(this.dashedPPC());
      }
    }

    getMeta() {
      return {title: $.i18n.t('account.prepaids_title')};
    }

    afterRender() {
      super.afterRender();
      this.$el.find("span[title]").tooltip();
      if (me.isAnonymous() && this.ppc) {
        _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({startOnPath: 'individual'})); } });
        return window.nextURL = location.href;
      }
    }


    statusMessage(message, type) {
      if (type == null) { type = 'alert'; }
      return noty({text: message, layout: 'topCenter', type, killer: false, timeout: 5000, dismissQueue: true, maxVisible: 3});
    }

    dashedPPC() {
      if (this.ppc.length === 12) {
        return `${this.ppc.slice(0,4)}-${this.ppc.slice(4,8)}-${this.ppc.slice(8)}`;
      }
      return this.ppc;
    }

    onClickStartSubscription() {
      return this.openModalView(new SubscribeModal());
    }

    confirmRedeem() {

      const options = {
        url: '/db/subscription/-/subscribe_prepaid',
        method: 'POST',
        data: { ppc: this.dashedPPC() }
      };

      options.error = (model, res, options, foo) => {
        // console.error 'FAILED redeeming prepaid code'
        const msg = model.responseText != null ? model.responseText : '';
        return this.statusMessage(`Error: Could not redeem prepaid code. ${msg}`, "error");
      };

      options.success = (model, res, options) => {
        // console.log 'SUCCESS redeeming prepaid code'
        this.statusMessage("Prepaid Code Redeemed!", "success");
        this.supermodel.loadCollection(this.codes, 'prepaid', {cache: false});
        this.codes.fetch();
        return me.fetch({cache: false});
      };

      return this.supermodel.addRequestResource('subscribe_prepaid', options, 0).load();
    }


    loadPrepaid(ppc) {
      if (!ppc) { return; }
      const options = {
        cache: false,
        method: 'GET',
        url: `/db/prepaid/-/code/${ppc}`
      };

      options.success = (model, res, options) => {
        this.ppcInfo = [];
        if (model.get('type') === 'terminal_subscription') {
          let left, left1, left2, left3, unlocksLeft;
          const months = (left = __guard__(model.get('properties'), x => x.months)) != null ? left : 0;
          const days = (left1 = __guard__(model.get('properties'), x1 => x1.days)) != null ? left1 : 0;
          const maxRedeemers = (left2 = model.get('maxRedeemers')) != null ? left2 : 0;
          const redeemers = (left3 = model.get('redeemers')) != null ? left3 : [];
          if (ppc.length === 14) {
            unlocksLeft = 1;
          } else {
            unlocksLeft = maxRedeemers - redeemers.length;
          }
          this.ppcInfo.push($.t('account_prepaid.prepaid_add_months', {months}));
          this.ppcInfo.push($.t('account_prepaid.can_use_times', {unlocksLeft}));
          // TODO: user needs to know they can't apply it more than once to their account
        } else {
          this.ppcInfo.push(`Type: ${model.get('type')}`);
        }
        return (typeof this.render === 'function' ? this.render() : undefined);
      };
      options.error = (model, res, options) => {
        if (res.status === 404) {
          if (res.responseText === 'Activation code has been used') {
            this.ppcInfo.push($.i18n.t('account_prepaid.activation_code_used'));
            if (typeof this.render === 'function') {
              this.render();
            }
            return;
          }
        }
        return this.statusMessage("Unable to retrieve code.", "error");
      };

      this.prepaid = new Prepaid();
      return this.prepaid.fetch(options);
    }

    onClickLookupCodeButton(e) {
      this.ppc = $('.input-ppc').val();
      if (!this.ppc) {
        this.statusMessage("You must enter a code.", "error");
        return;
      }
      this.ppcInfo = [];
      if (typeof this.render === 'function') {
        this.render();
      }
      return this.loadPrepaid(this.dashedPPC());
    }

    onClickRedeemCodeButton(e) {
      this.ppc = $('.input-ppc').val();
      const options = {
        url: '/db/subscription/-/subscribe_prepaid',
        method: 'POST',
        data: { ppc: this.dashedPPC()}
      };
      options.error = (model, res, options, foo) => {
        let msg = model.responseText != null ? model.responseText : '';
        if (model.status === 403) {
          if (model.responseJSON.message === 'Activation Code has been used') {
            msg = $.i18n.t('account_prepaid.activation_code_used');
          }
        }
        return this.statusMessage($.i18n.t('account_prepaid.redeem_code_error') + msg, "error");
      };
      options.success = (model, res, options) => {
        this.statusMessage($.i18n.t('account_prepaid.prepaid_applied_success'), "success");
        this.codes.fetch({cache: false});
        me.fetch({cache: false});
        return this.loadPrepaid(this.dashedPPC());
      };
      return this.supermodel.addRequestResource('subscribe_prepaid', options, 0).load();
    }

    destroy() {
      super.destroy();
      return window.nextURL = null;
    }
  };
  PrepaidView.initClass();
  return PrepaidView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}