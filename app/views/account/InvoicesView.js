/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let InvoicesView;
require('app/styles/account/invoices-view.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/account/invoices-view');
const stripeHandler = require('core/services/stripe');
const utils = require('core/utils');

// Internal amount and query params are in cents, display and web form input amount is in USD

module.exports = (InvoicesView = (function() {
  InvoicesView = class InvoicesView extends RootView {
    static initClass() {
      this.prototype.id = "invoices-view";
      this.prototype.template = template;
  
      this.prototype.events =
        {'click #pay-button': 'onPayButton'};
  
      this.prototype.subscriptions =
        {'stripe:received-token': 'onStripeReceivedToken'};
    }

    constructor(options) {
      super(options);
      this.amount = utils.getQueryVariable('a', 0);
      this.description = utils.getQueryVariable('d', '');
    }

    getMeta() {
      return {title: $.i18n.t('account.invoices_title')};
    }

    onPayButton() {
      this.description = $('#description').val();

      // Validate input
      const amount = parseFloat($('#amount').val());
      if (isNaN(amount) || (amount <= 0)) {
        this.state = 'validation_error';
        this.stateMessage = $.i18n.t('account_invoices.invalid_amount');
        this.amount = 0;
        this.render();
        return;
      }

      this.state = undefined;
      this.stateMessage = undefined;
      this.amount = parseInt(amount * 100);

      // Show Stripe handler
      if (application.tracker != null) {
        application.tracker.trackEvent('Started invoice payment');
      }
      this.timestampForPurchase = new Date().getTime();
      return stripeHandler.open({
        amount: this.amount,
        description: this.description,
        bitcoin: true,
        alipay: (me.get('country') === 'china') || ((me.get('preferredLanguage') || 'en-US').slice(0, 2) === 'zh') ? true : 'auto'
      });
    }

    onStripeReceivedToken(e) {
      const data = {
        amount: this.amount,
        description: this.description,
        stripe: {
          token: e.token.id,
          timestamp: this.timestampForPurchase
        }
      };

      this.state = 'purchasing';
      this.render();
      const jqxhr = $.post('/db/payment/custom', data);

      jqxhr.done(() => {
        if (application.tracker != null) {
          application.tracker.trackEvent('Finished invoice payment', {
          amount: this.amount,
          description: this.description
        }
        );
        }

        // Show success UI
        this.state = 'invoice_paid';
        this.stateMessage = `$${(this.amount / 100).toFixed(2)} ` + $.i18n.t('account_invoices.success');
        this.amount = 0;
        this.description = '';
        return this.render();
      });

      return jqxhr.fail(function() {
        if (jqxhr.status === 402) {
          this.state = 'declined';
          this.stateMessage = arguments[2];
        } else if (jqxhr.status === 500) {
          this.state = 'retrying';
          const f = _.bind(this.onStripeReceivedToken, this, e);
          _.delay(f, 2000);
        } else {
          this.state = 'unknown_error';
          this.stateMessage = `${jqxhr.status}: ${jqxhr.responseText}`;
        }
        return this.render();
      }.bind(this));
    }
  };
  InvoicesView.initClass();
  return InvoicesView;
})());
