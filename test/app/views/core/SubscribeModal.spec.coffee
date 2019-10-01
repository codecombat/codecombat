SubscribeModal = require 'views/core/SubscribeModal'
Products = require 'collections/Products'
stripeHandler = require 'core/services/stripe'
payPal = require 'core/services/paypal'
{ wrapJasmine } = require('test/app/utils')

productList = [
  {
    _id: '1'
    name: 'basic_subscription'
    amount: 100
    gems: 3500
    planID: 'basic'
  }

  {
    _id: '3'
    name: 'lifetime_subscription'
    amount: 1000
    gems: 42000
  }
]

productListInternational = _.map(productList, (p) -> _.assign({}, p, {name: 'brazil_' + p.name}))

# Make a fake button for testing, used by calling ".click()"
makeFakePayPalButton = (options) ->
  { buttonContainerID, product, onPaymentStarted, onPaymentComplete, description } = options
  paymentData = {
    payment:
      transactions: [
        {
          amount: { total: product.adjustedPriceStringNoSymbol(), currency: 'USD' }
          item_list: {
            items: [{
              name: product.translateName()
              quantity: 1
              price: product.adjustedPriceStringNoSymbol()
              currency: 'USD'
            }]
          }
          description: description # Is this what shows up on their credit card, or so? TODO: Translate?
        }
      ]
  }
  return {
    click: (options) ->
      return new Promise (accept, reject) ->
        onPaymentStarted()
        _.defer ->
          payment = paymentData.payment
          # Add (partial) stub info that PayPal would attach to a payment object
          _.merge(payment, {
            cart: 'fake_cart_id'
            id: 'fake_payment_id'
            payer:
              payer_info:
                payer_id: 'fake_payer_id'
                email: 'fake_email@example.com'
              payment_method: 'paypal'
              status: 'VERIFIED'
            intent: 'sale'
            state: 'approved'
          }, options)
          onPaymentComplete(payment).then ->
            accept()
  }


describe 'SubscribeModal', ->

  tokenSuccess = Promise.resolve({token: {id:'1234'}})
  tokenError = Promise.reject(new Error('Stripe is upset'))
  tokenError.catch(_.noop) # shush, Chrome

  beforeEach ->
    @openAsync = jasmine.createSpy()
    spyOn(stripeHandler, 'makeNewInstance').and.returnValue({ @openAsync })
    spyOn(payPal, 'loadPayPal').and.returnValue(Promise.resolve())
    # Make the PayPal button even if we don't click it
    spyOn(payPal, 'makeButton').and.callFake (options) =>
      @payPalButton = makeFakePayPalButton(options)
    @getTrackerEventNames = -> _.without(tracker.trackEvent.calls.all().map((c) -> c.args[0]), 'View Load')

  afterEach ->
    if @openAsync.calls?.any()
      options = @openAsync.calls.argsFor(0)[0]
      expect(options.alipayReusable).toBeDefined()
      expect(options.alipay).toBeDefined()

  describe 'onClickPurchaseButton()', ->
    beforeEach ->
      me.set({_id: '1234'})
      @subscribeRequest = jasmine.Ajax.stubRequest('/db/user/1234')
      @modal = new SubscribeModal({products: new Products(productList)})
      @modal.render()
      jasmine.demoModal(@modal)

    describe 'when the subscription succeeds', ->
      beforeEach ->
        @subscribeRequest.andReturn({status: 200, responseText: '{}'})
        @openAsync.and.returnValue(tokenSuccess)

      it 'calls hide()', wrapJasmine ->
        spyOn(@modal, 'hide')
        yield @modal.onClickPurchaseButton()
        expect(@modal.hide).toHaveBeenCalled()
        expect(@getTrackerEventNames()).toDeepEqual(
          [ "Started subscription purchase", "Finished subscription purchase" ] )

    describe 'when the subscription response is 402', ->
      beforeEach ->
        @subscribeRequest.andReturn({status: 402, responseText: '{}'})
        @openAsync.and.returnValue(tokenSuccess)

      it 'shows state "declined"', wrapJasmine ->
        yield @modal.onClickPurchaseButton()
        expect(@modal.state).toBe('declined')
        expect(@getTrackerEventNames()).toDeepEqual(
          ["Started subscription purchase", "Failed to finish subscription purchase"])

    describe 'when the subscription response is any other error', ->
      beforeEach ->
        @subscribeRequest.andReturn({status: 500, responseText: '{}'})
        @openAsync.and.returnValue(tokenSuccess)

      it 'shows state "unknown_error"', wrapJasmine ->
        yield @modal.onClickPurchaseButton()
        expect(@modal.state).toBe('unknown_error')
        expect(@getTrackerEventNames()).toDeepEqual(
          ["Started subscription purchase", "Failed to finish subscription purchase"])

    describe 'when stripe errors out, or some other runtime error happens', ->
      beforeEach ->
        @openAsync.and.returnValue(tokenError)
        spyOn(console, 'error')

      it 'shows state "unknown_error"', wrapJasmine ->
        yield @modal.onClickPurchaseButton()
        expect(@modal.state).toBe('unknown_error')
        expect(@modal.stateMessage).toBe('Unknown Error')

        expect(@getTrackerEventNames()).toDeepEqual(
          ["Started subscription purchase", "Failed to finish subscription purchase"])
        expect(console.error).toHaveBeenCalled()

  describe 'onClickStripeLifetimeButton()', ->
    describe "when user's country does not have regional pricing", ->
      beforeEach ->
        me.set({_id: '1234', country: undefined})
        @purchaseRequest = jasmine.Ajax.stubRequest('/db/products/3/purchase')
        @modal = new SubscribeModal({products: new Products(productList)})
        @modal.render()
        jasmine.demoModal(@modal)
        @openAsync.and.returnValue(tokenSuccess)

      it 'uses Stripe', ->
        expect(@modal.$('.stripe-lifetime-button').length).toBe(1)
        expect(@modal.$('#paypal-button-container').length).toBe(0)
        expect(@payPalButton).toBeUndefined()

      describe 'when the purchase succeeds', ->
        beforeEach ->
          @purchaseRequest.andReturn({status: 200, responseText: '{}'})

        it 'calls hide()', wrapJasmine ->
          spyOn(@modal, 'hide')
          spyOn(me, 'fetch').and.returnValue(Promise.resolve())
          yield @modal.onClickStripeLifetimeButton()
          expect(@modal.hide).toHaveBeenCalled()
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "Start Lifetime Purchase", "Finish Lifetime Purchase" ])

      describe 'when the Stripe purchase response is 402', ->
        beforeEach ->
          @purchaseRequest.andReturn({status: 402, responseText: '{}'})

        it 'shows state "declined"', wrapJasmine ->
          yield @modal.onClickStripeLifetimeButton()
          expect(@modal.state).toBe('declined')
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "Start Lifetime Purchase", "Fail Lifetime Purchase" ])

    describe "when user's country has regional pricing", ->
      beforeEach ->
        me.set({_id: '1234', country: 'brazil'})
        @purchaseRequest = jasmine.Ajax.stubRequest('/db/products/3/purchase')
        @modal = new SubscribeModal({products: new Products(productListInternational)})
        @modal.render()
        jasmine.demoModal(@modal)
        @openAsync.and.returnValue(tokenSuccess)
      afterEach ->
        me.set({country: undefined})

      it 'uses Stripe', ->
        expect(@modal.$('.stripe-lifetime-button').length).toBe(1)
        expect(@modal.$('#paypal-button-container').length).toBe(0)
        expect(@payPalButton).toBeUndefined()
