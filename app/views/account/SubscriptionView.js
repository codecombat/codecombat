// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SubscriptionView;
import 'app/styles/account/subscription-view.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/account/subscription-view';
import CocoCollection from 'collections/CocoCollection';
import Products from 'collections/Products';
import Product from 'models/Product';
import payPal from 'core/services/paypal';
import SubscribeModal from 'views/core/SubscribeModal';
import Payment from 'models/Payment';
import stripeHandler from 'core/services/stripe';
import User from 'models/User';
import utils from 'core/utils';
import api from 'core/api';

// TODO: Link to sponsor id /user/userID instead of plain text name
// TODO: Link to sponsor email instead of plain text email
// TODO: Conslidate the multiple class for personal and recipient subscription info into 2 simple server API calls
// TODO: Track purchase amount based on actual users subscribed for a recipient subscribe event
// TODO: Validate email address formatting
// TODO: i18n pluralization for Stripe dialog description
// TODO: Don't prompt for new card if we have one already, just confirm purchase
// TODO: bulk discount isn't applied to personal sub
// TODO: next payment amount incorrect if have an expiring personal sub
// TODO: consider hiding managed subscription body UI while things are updating to avoid brief legacy data
// TODO: Next payment info for personal sub displays most recent payment when resubscribing before trial end
// TODO: PersonalSub and RecipientSubs have similar subscribe APIs
// TODO: Better recovery from trying to reuse a prepaid
// TODO: No way to unsubscribe from prepaid subscription
// TODO: Refactor state machines driving the UI.  They've become a hot mess.

// TODO: Get basic plan price dynamically
const basicPlanPrice = 999;
const basicPlanID = 'basic';

export default SubscriptionView = (function() {
  SubscriptionView = class SubscriptionView extends RootView {
    static initClass() {
      this.prototype.id = "subscription-view";
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .start-subscription-button': 'onClickStartSubscription',
        'click .end-subscription-button': 'onClickEndSubscription',
        'click .cancel-end-subscription-button': 'onClickCancelEndSubscription',
        'click .confirm-end-subscription-button': 'onClickConfirmEndSubscription',
        'click .recipients-subscribe-button': 'onClickRecipientsSubscribe',
        'click .confirm-recipient-unsubscribe-button': 'onClickRecipientConfirmUnsubscribe',
        'click .recipient-unsubscribe-button': 'onClickRecipientUnsubscribe'
      };
  
      this.prototype.subscriptions = {
        'subscribe-modal:subscribed': 'onSubscribed',
        'stripe:received-token': 'onStripeReceivedToken'
      };
    }

    constructor(options) {
      super(options);
      const prepaidCode = utils.getQueryVariable('_ppc');
      this.personalSub = new PersonalSub(this.supermodel, prepaidCode);
      this.recipientSubs = new RecipientSubs(this.supermodel);
      this.emailValidator = new EmailValidator(this.superModel);
      this.personalSub.update(() => (typeof this.render === 'function' ? this.render() : undefined));
      this.recipientSubs.update(() => (typeof this.render === 'function' ? this.render() : undefined));
      this.products = new Products();
      this.supermodel.loadCollection(this.products);
    }

    getMeta() {
      return {title: $.i18n.t('account.subscription_title')};
    }

    // Personal Subscriptions

    onClickStartSubscription(e) {
      if (this.personalSub.prepaidCode) {
        this.personalSub.subscribe(() => (typeof this.render === 'function' ? this.render() : undefined));
      } else {
        this.openModalView(new SubscribeModal());
      }
      return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'account subscription view'}) : undefined);
    }

    onSubscribed() {
      return document.location.reload();
    }

    showNativeCancellationForm() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Unsubscribe Start - Native', {category: 'Subscription'});
      }
      this.$el.find('.end-subscription-button').blur().addClass('disabled', 250);
      return this.$el.find('.unsubscribe-feedback').show(500).find('textarea').focus();
    }

    showProfitwellCancellationForm() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Unsubscribe Start - Profitwell', {category: 'Subscription'});
      }
      const {
        subscriptionID
      } = me.get('stripe');
      return window.profitwell('init_cancellation_flow', {subscription_id: subscriptionID}).then(result => {
        if (window.tracker != null) {
          window.tracker.trackEvent('Unsubscribe Result - Profitwell', {label: result.status, category: 'Subscription'});
        }
        if (['retained', 'aborted'].includes(result.status)) {
          // User either aborted the flow (i.e.they clicked on "never mind, I don't want to cancel"),
          // or accepted a salvage attempt or salvage offer.
          // Thus, do nothing, since they won't cancel.
          return;
        }
        if (result.status === 'error') {
          // The widget oculdn't be shown; fall back to native cancellation form
          this.showNativeCancellationForm();
          return;
        }
        if (result.status !== 'chose_to_cancel') {
          console.error(`Unknown Retain status: ${result.status}. Proceeding to cancellation.`);
        }
        let message = '';
        if (result.cancelReason) { message += `Cancellation reason: ${result.cancelReason}\n`; }
        if (result.satisfactionInsight) { message += `Satisfied with: ${result.satisfactionInsight}\n`; }
        if (result.additionalFeedback) { message += `Feedback: ${result.additionalFeedback}\n`; }
        return this.personalSub.unsubscribe(message, () => (typeof this.render === 'function' ? this.render() : undefined));
      });
    }

    onClickEndSubscription(e) {
      if (window.tracker != null) {
        window.tracker.trackEvent('Unsubscribe Start', {category: 'Subscription'});
      }
      if (window.profitwell && me.get('preferredLanguage', true).startsWith('en') && __guard__(me.get('stripe'), x => x.subscriptionID) && utils.getQueryVariable('retain')) {
        return this.showProfitwellCancellationForm();
      } else {
        return this.showNativeCancellationForm();
      }
    }

    onClickCancelEndSubscription(e) {
      if (window.tracker != null) {
        window.tracker.trackEvent('Unsubscribe Cancel', {category: 'Subscription'});
      }
      this.$el.find('.unsubscribe-feedback').hide(500).find('textarea').blur();
      return this.$el.find('.end-subscription-button').focus().removeClass('disabled', 250);
    }

    onClickConfirmEndSubscription(e) {
      const message = this.$el.find('.unsubscribe-feedback textarea').val().trim();
      return this.personalSub.unsubscribe(message, () => (typeof this.render === 'function' ? this.render() : undefined));
    }

    // Sponsored subscriptions

    onClickRecipientsSubscribe(e) {
      const emails = this.$el.find('.recipient-emails').val().split('\n');
      const valid = this.emailValidator.validateEmails(emails, () => (typeof this.render === 'function' ? this.render() : undefined));
      if (valid) { return this.recipientSubs.startSubscribe(emails); }
    }

    onClickRecipientUnsubscribe(e) {
      $(e.target).addClass('hide');
      return $(e.target).parent().find('.confirm-recipient-unsubscribe-button').removeClass('hide');
    }

    onClickRecipientConfirmUnsubscribe(e) {
      const email = $(e.target).closest('tr').find('td.recipient-email').text();
      const id = $(e.target).closest('tr').data('recipient-id');
      return this.recipientSubs.unsubscribe(email, id, () => (typeof this.render === 'function' ? this.render() : undefined));
    }

    onStripeReceivedToken(e) {
      return this.recipientSubs.finishSubscribe(e.token.id, () => (typeof this.render === 'function' ? this.render() : undefined));
    }
  };
  SubscriptionView.initClass();
  return SubscriptionView;
})();

// Helper classes for managing subscription actions and updating UI state

class EmailValidator {

  validateEmails(emails, render) {
    this.lastEmails = emails.join('\n');
    //taken from http://www.regular-expressions.info/email.html
    const emailRegex = /[A-z0-9._%+-]+@[A-z0-9.-]+\.[A-z]{2,63}/;
    this.validEmails = ((() => {
      const result = [];
      for (var email of Array.from(emails)) {         if (emailRegex.test(email.trim().toLowerCase())) {
          result.push(email);
        }
      }
      return result;
    })());
    if (this.validEmails.length < emails.length) { return this.emailsInvalid(render); }
    return this.emailsValid(render);
  }

  emailString() {
    if (!this.validEmails) { return; }
    return this.validEmails.join('\n');
  }

  emailsInvalid(render) {
    this.state = "invalid";
    render();
    return false;
  }

  emailsValid(render) {
    this.state = "valid";
    render();
    return true;
  }
}


class PersonalSub {
  constructor(supermodel, prepaidCode) {
    this.supermodel = supermodel;
    this.prepaidCode = prepaidCode;
  }

  subscribe(render) {
    let left;
    if (!this.prepaidCode) { return; }

    if (this.prepaidCode === __guard__(me.get('stripe'), x => x.prepaidCode)) {
      delete this.prepaidCode;
      return render();
    }

    this.state = 'subscribing';
    this.stateMessage = '';
    render();

    let stripeInfo = _.clone((left = me.get('stripe')) != null ? left : {});
    stripeInfo.planID = basicPlanID;
    stripeInfo.prepaidCode = this.prepaidCode;
    me.set('stripe', stripeInfo);

    me.once('sync', () => {
      if (application.tracker != null) {
        application.tracker.trackEvent('Finished subscription purchase', {value: 0, category: 'Subscription'});
      }
      delete this.prepaidCode;
      return this.update(render);
    });
    me.once('error', (user, response, options) => {
      let left1;
      console.error('We got an error subscribing with Stripe from our server:', response);
      stripeInfo = (left1 = me.get('stripe')) != null ? left1 : {};
      delete stripeInfo.planID;
      delete stripeInfo.prepaidCode;
      me.set('stripe', stripeInfo);
      const {
        xhr
      } = options;
      if (xhr.status === 402) {
        this.state = 'declined';
        this.stateMessage = '';
      } else {
        if (xhr.status === 403) {
          delete this.prepaidCode;
        }
        this.state = 'unknown_error';
        this.stateMessage = `${xhr.status}: ${xhr.responseText}`;
      }
      return render();
    });
    return me.patch({headers: {'X-Change-Plan': 'true'}});
  }

  unsubscribe(message, render) {
    const payPalInfo = me.get('payPal');
    const stripeInfo = _.clone(me.get('stripe'));
    if (payPalInfo != null ? payPalInfo.billingAgreementID : undefined) {
      api.users.cancelBillingAgreement({userID: me.id, billingAgreementID: (payPalInfo != null ? payPalInfo.billingAgreementID : undefined)})
      .then(response => {
        if (window.tracker != null) {
          window.tracker.trackEvent('Unsubscribe End', {message, category: 'Subscription'});
        }
        return document.location.reload();
    }).catch(jqxhr => {
        return console.error('PayPal unsubscribe', jqxhr);
      });
    } else if (stripeInfo) {
      delete stripeInfo.planID;
      me.set('stripe', stripeInfo);
      me.once('sync', function() {
        if (window.tracker != null) {
          window.tracker.trackEvent('Unsubscribe End', {message, category: 'Subscription'});
        }
        return document.location.reload();
      });
      me.patch({headers: {'X-Change-Plan': 'true'}});

    } else {
      console.error("Tried to unsubscribe without PayPal or Stripe user info.");
      this.state = 'unknown_error';
      this.stateMessage = "You do not appear to be subscribed.";
      render();
    }
    if (message) {
      return $.post('/contact', {message, subject: 'Cancellation'});
    }
  }

  update(render) {
    let payments;
    const stripeInfo = me.get('stripe');
    const payPalInfo = me.get('payPal');
    if (!stripeInfo && !payPalInfo) { return; }

    this.state = 'loading';

    if (stripeInfo) {
      this.free = stripeInfo.free;
      if (stripeInfo.sponsorID) {
        this.sponsor = true;
        const onSubSponsorSuccess = sponsorInfo => {
          this.sponsorEmail = sponsorInfo.email;
          this.sponsorName = sponsorInfo.name;
          this.sponsorID = stripeInfo.sponsorID;
          if (sponsorInfo.subscription.cancel_at_period_end) {
            this.endDate = new Date(sponsorInfo.subscription.current_period_end * 1000);
          }
          delete this.state;
          return render();
        };
        this.supermodel.addRequestResource('sub_sponsor', {
          url: '/db/user/-/sub_sponsor',
          method: 'POST',
          success: onSubSponsorSuccess
        }, 0).load();

      } else if (stripeInfo.prepaidCode) {
        this.usingPrepaidCode = true;
        delete this.state;
        render();

      } else if (stripeInfo.subscriptionID) {
        this.self = true;
        this.active = me.isPremium();
        this.subscribed = (stripeInfo.planID != null);

        const options = { cache: false, url: `/db/user/${me.id}/stripe` };
        options.success = info => {
          let card, sub;
          if (card = info.card) {
            this.card = `${card.brand}: x${card.last4}`;
          }
          if (sub = info.subscription) {
            const periodEnd = new Date((sub.trial_end || sub.current_period_end) * 1000);
            if (sub.cancel_at_period_end) {
              this.activeUntil = periodEnd;
              if (this.free && (typeof this.free === 'string') && (new Date(this.free) > this.activeUntil)) {
                // stripe.free trumps end of period cancellation date, switch to that state
                delete this.self;
                delete this.active;
                delete this.subscribed;
              }
            } else if (__guard__(sub.discount != null ? sub.discount.coupon : undefined, x => x.id) !== 'free') {
              let productName;
              this.nextPaymentDate = periodEnd;
              // NOTE: This checks the product list for one that corresponds to their
              //   country. This will not work for "free" or "halfsies" because there
              //   are not products that correspond to those.
              // NOTE: This does NOT use the "amount" of the coupon in this client side calculation
              //   (those should be kept up to date on the server)
              // TODO: Calculate and return the true price on the server side, and use that as a source of truth
              if (__guard__(sub.discount != null ? sub.discount.coupon : undefined, x1 => x1.id)) {
                productName = `${__guard__(sub.discount != null ? sub.discount.coupon : undefined, x2 => x2.id)}_basic_subscription`;
              } else {
                productName = "basic_subscription";
              }
              const product = _.findWhere(this.supermodel.getModels(Product), m => m.get('name') === productName);
              if ((sub.metadata != null ? sub.metadata.type : undefined) === 'homeSubscriptions') {
                this.cost = `$${(sub.plan.amount / 100).toFixed(2)}`;
              } else if (product) {
                this.cost = `$${(product.get('amount')/100).toFixed(2)}`;
              } else {
                this.cost = `$${(sub.plan.amount/100).toFixed(2)}`;
              }

              // For the new annual plan, use the stripe information as source of truth.
              if (__guard__(me.get('stripe'), x3 => x3.planID) === "price_1Hja49KaReE7xLUdlPuATOvQ") {
                let discount;
                if (__guard__(sub.discount != null ? sub.discount.coupon : undefined, x4 => x4.percent_off_precise)) {
                  // Get percentage off from stripe data.
                  discount = sub.plan.amount * (sub.discount.coupon.percent_off_precise / 100);
                  this.cost = `$${((sub.plan.amount - discount)/100).toFixed(2)}`;
                } else if (__guard__(sub.discount != null ? sub.discount.coupon : undefined, x5 => x5.amount_off)) {
                  discount = __guard__(sub.discount != null ? sub.discount.coupon : undefined, x6 => x6.amount_off);
                  this.cost = `$${((sub.plan.amount - discount)/100).toFixed(2)}`;
                } else {
                  this.cost = `$${(sub.plan.amount/100).toFixed(2)}`;
                }
              }
            }

          } else {
            console.error(`Could not find personal subscription ${__guard__(me.get('stripe'), x7 => x7.customerID)} ${__guard__(me.get('stripe'), x8 => x8.subscriptionID)}`);
          }
          delete this.state;
          return render();
        };
        this.supermodel.addRequestResource('personal_payment_info', options).load();

        payments = new CocoCollection([], { url: '/db/payment', model: Payment, comparator:'_id' });
        payments.once('sync', function() {
          this.monthsSubscribed = ((() => {
            const result = [];
            for (var x of Array.from(payments.models)) {               if (!x.get('productID')) {
                result.push(x);
              }
            }
            return result;
          })()).length;
          return render();
        });
        this.supermodel.loadCollection(payments, 'payments', {cache: false});

      } else if (this.free) {
        delete this.state;
        render();
      }
    }

    if (!this.subscribed && (payPalInfo != null ? payPalInfo.billingAgreementID : undefined)) {
      this.self = true;
      this.active = true;
      this.subscribed = true;
      this.service = "PayPal";
      delete this.state;
      render();
      payments = new CocoCollection([], { url: '/db/payment', model: Payment, comparator:'_id' });
      payments.once('sync', () => {
        try {
          this.monthsSubscribed = ((() => {
            const result = [];
            for (var x of Array.from(payments.models)) {               if (!x.get('productID')) {
                result.push(x);
              }
            }
            return result;
          })()).length;
          const lastPayment = _.last(_.sortBy(_.filter(payments.models, p => /basic_subscription/ig.test(p.get('productID'))), p => p.get('created')));
          if (lastPayment) {
            this.nextPaymentDate = new Date(lastPayment.get('created'));
            this.nextPaymentDate.setUTCMonth(this.nextPaymentDate.getUTCMonth() + 1);
            this.cost = `$${(lastPayment.get('amount')/100).toFixed(2)}`;
            this.subscribed = this.nextPaymentDate > Date.now();
            return render();
          } else {
            return console.error("No subscription payments found!");
          }
        } catch (err) {
          return console.error(JSON.stringify(err));
        }
      });
      return this.supermodel.loadCollection(payments, 'payments', {cache: false});
    } else {
      delete this.state;
      return render();
    }
  }
}

class RecipientSubs {
  constructor(supermodel) {
    this.supermodel = supermodel;
    this.recipients = {};
    this.unsubscribingRecipients = [];
  }

  addSubscribing(email) {
    return this.unsubscribingRecipients.push(email);
  }

  removeSubscribing(email) {
    return _.remove(this.unsubscribingRecipients, recipientEmail => recipientEmail === email);
  }

  startSubscribe(emails) {
    let left;
    let email;
    this.recipientEmails = ((() => {
      const result = [];
      for (email of Array.from(emails)) {         result.push(email.trim().toLowerCase());
      }
      return result;
    })());
    _.remove(this.recipientEmails, email => _.isEmpty(email));
    if (this.recipientEmails.length < 1) { return; }

    if (window.tracker != null) {
      window.tracker.trackEvent('Start sponsored subscription', {category: 'Subscription'});
    }

    // TODO: this sometimes shows a rounded amount (e.g. $8.00)
    const currentSubCount = (left = __guard__(__guard__(me.get('stripe'), x1 => x1.recipients), x => x.length)) != null ? left : 0;
    const newSubCount = this.recipientEmails.length + currentSubCount;
    const amount = utils.getSponsoredSubsAmount(basicPlanPrice, newSubCount, (__guard__(me.get('stripe'), x2 => x2.subscriptionID) != null)) - utils.getSponsoredSubsAmount(basicPlanPrice, currentSubCount, (__guard__(me.get('stripe'), x3 => x3.subscriptionID) != null));
    const options = {
      description: `${this.recipientEmails.length} ` + $.i18n.t('subscribe.stripe_description', {defaultValue: 'Monthly Subscriptions'}),
      amount,
      alipay: me.get('chinaVersion') || ((me.get('preferredLanguage') || 'en-US').slice(0, 2) === 'zh') ? true : 'auto',
      alipayReusable: true
    };
    this.state = 'start subscribe';
    this.stateMessage = '';
    return stripeHandler.open(options);
  }

  finishSubscribe(tokenID, render) {
    let left;
    if (this.state !== 'start subscribe') { return; } // Don't intercept personal subcribe process

    this.state = 'subscribing';
    this.stateMessage = '';
    this.justSubscribed = [];
    render();

    let stripeInfo = _.clone((left = me.get('stripe')) != null ? left : {});
    stripeInfo.token = tokenID;
    stripeInfo.subscribeEmails = this.recipientEmails;
    me.set('stripe', stripeInfo);

    me.once('sync', () => {
      if (application.tracker != null) {
        application.tracker.trackEvent('Finished sponsored subscription purchase', {category: 'Subscription'});
      }
      return this.update(render);
    });
    me.once('error', (user, response, options) => {
      let left1;
      console.error('We got an error subscribing with Stripe from our server:', response);
      stripeInfo = (left1 = me.get('stripe')) != null ? left1 : {};
      delete stripeInfo.token;
      const {
        xhr
      } = options;
      if (xhr.status === 402) {
        this.state = 'declined';
        this.stateMessage = '';
      } else {
        this.state = 'unknown_error';
        this.stateMessage = `${xhr.status}: ${xhr.responseText}`;
      }
      return render();
    });
    return me.patch({headers: {'X-Change-Plan': 'true'}});
  }

  unsubscribe(email, id, render) {
    delete this.state;
    this.stateMessage = '';
    delete this.justSubscribed;
    this.addSubscribing(email);
    render();
    return me.unsubscribeRecipient(id).then(() => {
      this.removeSubscribing(email);
      return this.update(render);
    });
  }

  update(render) {
    delete this.state;
    delete this.stateMessage;
    if (!__guard__(me.get('stripe'), x => x.recipients)) { return; }
    this.unsubscribingRecipients = [];

    const options = { cache: false, url: `/db/user/${me.id}/stripe` };
    options.success = info => {
      let card;
      this.sponsorSub = info.sponsorSubscription;
      if (card = info.card) {
        this.card = `${card.brand}: x${card.last4}`;
      }
      return render();
    };
    this.supermodel.addRequestResource('recipients_payment_info', options).load();

    const onSubRecipientsSuccess = recipientsMap => {
      this.recipients = recipientsMap;
      let count = 0;
      for (var userID in this.recipients) {
        var recipient = this.recipients[userID];
        if (!recipient.cancel_at_period_end) { count++; }
        if ((this.recipientEmails != null) && (this.justSubscribed != null) && Array.from(this.recipientEmails).includes(recipient.emailLower)) {
          this.justSubscribed.push(recipient.emailLower);
        }
      }
      this.nextPaymentAmount = utils.getSponsoredSubsAmount(basicPlanPrice, count, (__guard__(me.get('stripe'), x1 => x1.subscriptionID) != null));
      this.recipientEmails = [];
      return render();
    };
    return this.supermodel.addRequestResource('sub_recipients', {
      url: '/db/user/-/sub_recipients',
      method: 'POST',
      success: onSubRecipientsSuccess
    }, 0).load();
  }
}

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}