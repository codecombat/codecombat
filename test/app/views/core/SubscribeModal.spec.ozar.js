/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const SubscribeModal = require('views/core/SubscribeModal');
const Products = require('collections/Products');
const stripeHandler = require('core/services/stripe');
const payPal = require('core/services/paypal');
const { wrapJasmine } = require('test/app/utils');

const productList = [
  {
    _id: '1',
    name: 'basic_subscription',
    amount: 100,
    gems: 3500,
    planID: 'basic'
  },

  {
    _id: '3',
    name: 'lifetime_subscription',
    amount: 1000,
    gems: 42000
  }
];

const productListInternational = _.map(productList, p => _.assign({}, p, {name: 'brazil_' + p.name}));

// Make a fake button for testing, used by calling ".click()"
const makeFakePayPalButton = function(options) {
  const { buttonContainerID, product, onPaymentStarted, onPaymentComplete, description } = options;
  const paymentData = {
    payment: {
      transactions: [
        {
          amount: { total: product.adjustedPriceStringNoSymbol(), currency: 'USD' },
          item_list: {
            items: [{
              name: product.translateName(),
              quantity: 1,
              price: product.adjustedPriceStringNoSymbol(),
              currency: 'USD'
            }]
          },
          description // Is this what shows up on their credit card, or so? TODO: Translate?
        }
      ]
    }
  };
  return {
    click(options) {
      return new Promise(function(accept, reject) {
        onPaymentStarted();
        return _.defer(function() {
          const {
            payment
          } = paymentData;
          // Add (partial) stub info that PayPal would attach to a payment object
          _.merge(payment, {
            cart: 'fake_cart_id',
            id: 'fake_payment_id',
            payer: {
              payer_info: {
                payer_id: 'fake_payer_id',
                email: 'fake_email@example.com'
              },
              payment_method: 'paypal',
              status: 'VERIFIED'
            },
            intent: 'sale',
            state: 'approved'
          }, options);
          return onPaymentComplete(payment).then(() => accept());
        });
      });
    }
  };
};


xdescribe('SubscribeModal', function() {

  const tokenSuccess = Promise.resolve({token: {id:'1234'}});
  const tokenError = Promise.reject(new Error('Stripe is upset'));
  tokenError.catch(_.noop); // shush, Chrome

  beforeEach(function() {
    this.openAsync = jasmine.createSpy();
    spyOn(stripeHandler, 'makeNewInstance').and.returnValue({ openAsync: this.openAsync });
    spyOn(payPal, 'loadPayPal').and.returnValue(Promise.resolve());
    // Make the PayPal button even if we don't click it
    spyOn(payPal, 'makeButton').and.callFake(options => {
      return this.payPalButton = makeFakePayPalButton(options);
    });
    return this.getTrackerEventNames = () => _.without(tracker.trackEvent.calls.all().map(c => c.args[0]), 'View Load');
  });

  afterEach(function() {
    if (this.openAsync.calls != null ? this.openAsync.calls.any() : undefined) {
      const options = this.openAsync.calls.argsFor(0)[0];
      expect(options.alipayReusable).toBeDefined();
      return expect(options.alipay).toBeDefined();
    }
  });

  describe('onClickPurchaseButton()', function() {
    beforeEach(function() {
      me.set({_id: '1234'});
      this.subscribeRequest = jasmine.Ajax.stubRequest('/db/user/1234');
      this.modal = new SubscribeModal({products: new Products(productList)});
      this.modal.render();
      return jasmine.demoModal(this.modal);
    });

    describe('when the subscription succeeds', function() {
      beforeEach(function() {
        this.subscribeRequest.andReturn({status: 200, responseText: '{}'});
        return this.openAsync.and.returnValue(tokenSuccess);
      });

      return it('calls hide()', wrapJasmine(function*() {
        spyOn(this.modal, 'hide');
        yield this.modal.onClickPurchaseButton();
        expect(this.modal.hide).toHaveBeenCalled();
        return expect(this.getTrackerEventNames()).toDeepEqual(
          [ "Started subscription purchase", "Finished subscription purchase" ] );
      })
      );
    });

    describe('when the subscription response is 402', function() {
      beforeEach(function() {
        this.subscribeRequest.andReturn({status: 402, responseText: '{}'});
        return this.openAsync.and.returnValue(tokenSuccess);
      });

      return it('shows state "declined"', wrapJasmine(function*() {
        yield this.modal.onClickPurchaseButton();
        expect(this.modal.state).toBe('declined');
        return expect(this.getTrackerEventNames()).toDeepEqual(
          ["Started subscription purchase", "Failed to finish subscription purchase"]);
      })
      );
    });

    describe('when the subscription response is any other error', function() {
      beforeEach(function() {
        this.subscribeRequest.andReturn({status: 500, responseText: '{}'});
        return this.openAsync.and.returnValue(tokenSuccess);
      });

      return it('shows state "unknown_error"', wrapJasmine(function*() {
        yield this.modal.onClickPurchaseButton();
        expect(this.modal.state).toBe('unknown_error');
        return expect(this.getTrackerEventNames()).toDeepEqual(
          ["Started subscription purchase", "Failed to finish subscription purchase"]);
      })
      );
    });

    return describe('when stripe errors out, or some other runtime error happens', function() {
      beforeEach(function() {
        this.openAsync.and.returnValue(tokenError);
        return spyOn(console, 'error');
      });

      return it('shows state "unknown_error"', wrapJasmine(function*() {
        yield this.modal.onClickPurchaseButton();
        expect(this.modal.state).toBe('unknown_error');
        expect(this.modal.stateMessage).toBe('Unknown Error');

        expect(this.getTrackerEventNames()).toDeepEqual(
          ["Started subscription purchase", "Failed to finish subscription purchase"]);
        return expect(console.error).toHaveBeenCalled();
      })
      );
    });
  });

  return describe('onClickStripeLifetimeButton()', function() {
    describe("when user's country does not have regional pricing", function() {
      beforeEach(function() {
        me.set({_id: '1234', country: undefined});
        this.purchaseRequest = jasmine.Ajax.stubRequest('/db/products/3/purchase');
        this.modal = new SubscribeModal({products: new Products(productList)});
        this.modal.render();
        jasmine.demoModal(this.modal);
        return this.openAsync.and.returnValue(tokenSuccess);
      });

      it('uses Stripe', function() {
        expect(this.modal.$('.stripe-lifetime-button').length).toBe(1);
        expect(this.modal.$('#paypal-button-container').length).toBe(0);
        return expect(this.payPalButton).toBeUndefined();
      });

      describe('when the purchase succeeds', function() {
        beforeEach(function() {
          return this.purchaseRequest.andReturn({status: 200, responseText: '{}'});
        });

        return it('calls hide()', wrapJasmine(function*() {
          spyOn(this.modal, 'hide');
          spyOn(me, 'fetch').and.returnValue(Promise.resolve());
          yield this.modal.onClickStripeLifetimeButton();
          expect(this.modal.hide).toHaveBeenCalled();
          return expect(this.getTrackerEventNames()).toDeepEqual(
            [ "Start Lifetime Purchase", "Finish Lifetime Purchase" ]);
        })
        );
      });

      return describe('when the Stripe purchase response is 402', function() {
        beforeEach(function() {
          return this.purchaseRequest.andReturn({status: 402, responseText: '{}'});
        });

        return it('shows state "declined"', wrapJasmine(function*() {
          yield this.modal.onClickStripeLifetimeButton();
          expect(this.modal.state).toBe('declined');
          return expect(this.getTrackerEventNames()).toDeepEqual(
            [ "Start Lifetime Purchase", "Fail Lifetime Purchase" ]);
        })
        );
      });
    });

    return describe("when user's country has regional pricing", function() {
      beforeEach(function() {
        me.set({_id: '1234', country: 'brazil'});
        this.purchaseRequest = jasmine.Ajax.stubRequest('/db/products/3/purchase');
        this.modal = new SubscribeModal({products: new Products(productListInternational)});
        this.modal.render();
        jasmine.demoModal(this.modal);
        return this.openAsync.and.returnValue(tokenSuccess);
      });
      afterEach(() => me.set({country: undefined}));

      return it('uses Stripe', function() {
        expect(this.modal.$('.stripe-lifetime-button').length).toBe(1);
        expect(this.modal.$('#paypal-button-container').length).toBe(0);
        return expect(this.payPalButton).toBeUndefined();
      });
    });
  });
});
