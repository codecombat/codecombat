// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PaymentsView;
const RootView = require('views/core/RootView');
const template = require('app/templates/account/payments-view');
const CocoCollection = require('collections/CocoCollection');
const Payments = require('collections/Payments');
const Prepaids = require('collections/Prepaids');

module.exports = (PaymentsView = (function() {
  PaymentsView = class PaymentsView extends RootView {
    static initClass() {
      this.prototype.id = "payments-view";
      this.prototype.template = template;
    }

    initialize() {
      super.initialize();
    }

    constructor () {
      super()
      this.payments = new Payments();
      this.supermodel.trackRequest(this.payments.fetchByRecipient(me.id));
      this.prepaids = new Prepaids();
      this.supermodel.trackRequest(this.prepaids.fetchByCreator(me.id, {data: {allTypes: true}}));
      this.paymentDescription = {};
    }

    getMeta() {
      return {title: $.i18n.t('account.payments_title')};
    }

    onLoaded() {
      this.prepaidMap = _.zipObject(_.map(this.prepaids.models, m => m.id), this.prepaids.models);
      if (typeof this.reload === 'function') {
        this.reload();
      }

      // for administration
      for (var payment of Array.from(this.payments.models)) {
        var payPal = payment.get('payPal');
        var transactionId = __guard__(__guard__(__guard__(__guard__(__guard__(payPal != null ? payPal.transactions : undefined, x4 => x4[0]), x3 => x3.related_resources), x2 => x2[0]), x1 => x1.sale), x => x.id);
        if (transactionId) {
          console.log('PayPal Payment', transactionId, payment.get('amount'));
        }

        var payPalSale = payment.get('payPalSale');
        transactionId = payPalSale != null ? payPalSale.id : undefined;
        if (transactionId) {
          console.log('PayPal Subscription Payment', transactionId);
        }

        var description = payment.get('description');
        if (payment.get('productID') === 'online-classes') {
          this.paymentDescription[payment.id] = description.slice(0, 22);
        } else {
          this.paymentDescription[payment.id] = description;
        }
      }

      return super.onLoaded();
    }
  };
  PaymentsView.initClass();
  return PaymentsView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}