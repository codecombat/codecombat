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
    _id: '2'
    name: 'year_subscription'
    amount: 1000
    gems: 42000
  }

  {
    _id: '3'
    name: 'lifetime_subscription'
    amount: 1000
    gems: 42000
  }
]

productListNoYear = _.filter(productList, (p) -> p.name isnt 'year_subscription')
productListNoLifetime = _.filter(productList, (p) -> p.name isnt 'lifetime_subscription')

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
  
  it 'lifetime demo', ->
    modal = new SubscribeModal({products: new Products(productListNoYear)})
    modal.render()
    jasmine.demoModal(modal)
    modal.stopListening()

  it 'year sub demo', ->
    modal = new SubscribeModal({products: new Products(productListNoLifetime)})
    modal.render()
    jasmine.demoModal(modal)
    modal.stopListening()
  
  it 'payment processor selection demo', ->
    modal = new SubscribeModal({products: new Products(productListNoYear)})
    modal.state = 'choosing-payment-method'
    modal.selectedProduct = modal.lifetimeProduct
    modal.render()
    jasmine.demoModal(modal)
    modal.stopListening()

  describe 'onClickPurchaseButton()', ->
    beforeEach ->
      me.set({_id: '1234'})
      @subscribeRequest = jasmine.Ajax.stubRequest('/db/user/1234')
      @modal = new SubscribeModal({products: new Products(productListNoLifetime)})
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
        
  describe 'onClickSaleButton()', ->
    beforeEach ->
      me.set({_id: '1234'})
      @purchaseRequest = jasmine.Ajax.stubRequest('/db/products/2/purchase')
      @modal = new SubscribeModal({products: new Products(productListNoLifetime)})
      @modal.render()
      jasmine.demoModal(@modal)
      @openAsync.and.returnValue(tokenSuccess)
    
    describe 'when the purchase succeeds', ->
      beforeEach ->
        @purchaseRequest.andReturn({status: 200, responseText: '{}'})

      describe 'when using PayPal', ->
        it 'calls hide()', wrapJasmine ->
          spyOn(@modal, 'hide')
          @modal.onClickSaleButton()
          yield @payPalButton.click()
          expect(@modal.hide).toHaveBeenCalled()
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "Started 1 year subscription purchase", "Finished 1 year subscription purchase" ])

      describe 'when using Stripe', ->
        it 'calls hide()', wrapJasmine ->
          spyOn(@modal, 'hide')
          @modal.onClickSaleButton()
          yield @modal.onClickStripeButton()
          expect(@modal.hide).toHaveBeenCalled()
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "Started 1 year subscription purchase", "Finished 1 year subscription purchase" ])

    describe 'when the purchase response is 402', ->
      beforeEach ->
        @purchaseRequest.andReturn({status: 402, responseText: '{}'})
      
      describe 'when using Stripe', ->
        it 'shows state "declined"', wrapJasmine ->
          @modal.onClickSaleButton()
          yield @modal.onClickStripeButton()
          expect(@modal.state).toBe('declined')
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "Started 1 year subscription purchase", "Failed to finish 1 year subscription purchase" ])

    describe 'when the purchase response is 422', ->
      beforeEach ->
        @purchaseRequest.andReturn({status: 422, responseText: '{"i18n": "subscribe.paypal_payment_error"}'})
      
      describe 'when using PayPal', ->
        it 'shows state "error"', wrapJasmine ->
          @modal.onClickSaleButton()
          yield @payPalButton.click()
          expect(@modal.state).toBe('error')
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "Started 1 year subscription purchase", "Failed to finish 1 year subscription purchase" ])

  describe 'onClickLifetimeButton()', ->
    beforeEach ->
      me.set({_id: '1234'})
      @purchaseRequest = jasmine.Ajax.stubRequest('/db/products/3/purchase')
      @modal = new SubscribeModal({products: new Products(productListNoYear)})
      @modal.render()
      jasmine.demoModal(@modal)
      @openAsync.and.returnValue(tokenSuccess)

    describe 'when the purchase succeeds', ->
      beforeEach ->
        @purchaseRequest.andReturn({status: 200, responseText: '{}'})
      
      describe 'when using PayPal', ->
        it 'calls hide()', wrapJasmine ->
          spyOn(@modal, 'hide')
          @modal.onClickLifetimeButton()
          yield @payPalButton.click()
          expect(@modal.hide).toHaveBeenCalled()
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "SubscribeModal Lifetime Button Click", "Start Lifetime Purchase", "Finish Lifetime Purchase" ])

      describe 'when using Stripe', ->
        it 'calls hide()', wrapJasmine ->
          spyOn(@modal, 'hide')
          @modal.onClickLifetimeButton()
          yield @modal.onClickStripeButton()
          expect(@modal.hide).toHaveBeenCalled()
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "SubscribeModal Lifetime Button Click", "Start Lifetime Purchase", "Finish Lifetime Purchase" ])

    describe 'when the purchase response is 402', ->
      beforeEach ->
        @purchaseRequest.andReturn({status: 402, responseText: '{}'})

      describe 'when using Stripe', ->
        it 'shows state "declined"', wrapJasmine ->
          @modal.onClickLifetimeButton()
          yield @modal.onClickStripeButton()
          expect(@modal.state).toBe('declined')
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "SubscribeModal Lifetime Button Click", "Start Lifetime Purchase", "Fail Lifetime Purchase" ])

    describe 'when the purchase response is 422', ->
      beforeEach ->
        @purchaseRequest.andReturn({status: 422, responseText: '{"i18n": "subscribe.paypal_payment_error"}'})

      describe 'when using PayPal', ->
        it 'shows state "error"', wrapJasmine ->
          @modal.onClickLifetimeButton()
          yield @payPalButton.click()
          expect(@modal.state).toBe('error')
          expect(@getTrackerEventNames()).toDeepEqual(
            [ "SubscribeModal Lifetime Button Click", "Start Lifetime Purchase", "Fail Lifetime Purchase" ])
