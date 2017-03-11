SubscribeModal = require 'views/core/SubscribeModal'
Products = require 'collections/Products'
stripeHandler = require 'core/services/stripe'
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

describe 'SubscribeModal', ->
  
  tokenSuccess = Promise.resolve({token: {id:'1234'}})
  tokenError = Promise.reject(new Error('Stripe is upset'))
  tokenError.catch(_.noop) # shush, Chrome
  
  beforeEach ->
    @openAsync = jasmine.createSpy()
    spyOn(stripeHandler, 'makeNewInstance').and.returnValue({ @openAsync })
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

      it 'calls hide()', wrapJasmine ->
        spyOn(@modal, 'hide')
        yield @modal.onClickSaleButton()
        expect(@modal.hide).toHaveBeenCalled()
        expect(@getTrackerEventNames()).toDeepEqual(
          [ "Started 1 year subscription purchase", "Finished 1 year subscription purchase" ])

    describe 'when the purchase response is 402', ->
      beforeEach ->
        @purchaseRequest.andReturn({status: 402, responseText: '{}'})

      it 'shows state "declined"', wrapJasmine ->
        yield @modal.onClickSaleButton()
        expect(@modal.state).toBe('declined')
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

      it 'calls hide()', wrapJasmine ->
        spyOn(@modal, 'hide')
        yield @modal.onClickLifetimeButton()
        expect(@modal.hide).toHaveBeenCalled()
        expect(@getTrackerEventNames()).toDeepEqual(
          [ "Start Lifetime Purchase", "Finish Lifetime Purchase" ])

    describe 'when the purchase response is 402', ->
      beforeEach ->
        @purchaseRequest.andReturn({status: 402, responseText: '{}'})

      it 'shows state "declined"', wrapJasmine ->
        yield @modal.onClickLifetimeButton()
        expect(@modal.state).toBe('declined')
        expect(@getTrackerEventNames()).toDeepEqual(
          [ "Start Lifetime Purchase", "Fail Lifetime Purchase" ])
