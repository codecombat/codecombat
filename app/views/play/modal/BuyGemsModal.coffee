ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/buy-gems-modal'
stripeHandler = require 'core/services/stripe'
utils = require 'core/utils'
SubscribeModal = require 'views/core/SubscribeModal'

module.exports = class BuyGemsModal extends ModalView
  id: 'buy-gems-modal'
  template: template
  plain: true

  originalProducts: [
    { price: '$4.99', gems: 5000, amount: 499, id: 'gems_5', i18n: 'buy_gems.few_gems' }
    { price: '$9.99', gems: 11000, amount: 999, id: 'gems_10', i18n: 'buy_gems.pile_gems' }
    { price: '$19.99', gems: 25000, amount: 1999, id: 'gems_20', i18n: 'buy_gems.chest_gems' }
  ]

  subscriptions:
    'ipad:products': 'onIPadProducts'
    'ipad:iap-complete': 'onIAPComplete'
    'stripe:received-token': 'onStripeReceivedToken'

  events:
    'click .product button:not(.start-subscription-button)': 'onClickProductButton'
    'click #close-modal': 'hide'
    'click .start-subscription-button': 'onClickStartSubscription'

  constructor: (options) ->
    super(options)
    @timestampForPurchase = new Date().getTime()
    @state = 'standby'
    if application.isIPadApp
      @products = []
      Backbone.Mediator.publish 'buy-gems-modal:update-products'
    else
      @products = @originalProducts
      $.post '/db/payment/check-stripe-charges', (something, somethingElse, jqxhr) =>
        if jqxhr.status is 201
          @state = 'recovered_charge'
          @render()

  getRenderData: ->
    c = super()
    c.products = @products
    c.state = @state
    c.stateMessage = @stateMessage
    return c

  onIPadProducts: (e) ->
    newProducts = []
    for iapProduct in e.products
      localProduct = _.find @originalProducts, { id: iapProduct.id }
      continue unless localProduct
      localProduct.price = iapProduct.price
      newProducts.push localProduct
    @products = _.sortBy newProducts, 'gems'
    @render()

  onClickProductButton: (e) ->
    @playSound 'menu-button-click'
    productID = $(e.target).closest('button').val()
    product = _.find @products, { id: productID }

    if application.isIPadApp
      Backbone.Mediator.publish 'buy-gems-modal:purchase-initiated', { productID: productID }

    else
      application.tracker?.trackEvent 'Started gem purchase', { productID: productID }
      stripeHandler.open({
        description: $.t(product.i18n)
        amount: product.amount
        bitcoin: true
        alipay: if me.get('chinaVersion') or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'
      })

    @productBeingPurchased = product

  onStripeReceivedToken: (e) ->
    data = {
      productID: @productBeingPurchased.id
      stripe: {
        token: e.token.id
        timestamp: @timestampForPurchase
      }
    }
    @state = 'purchasing'
    @render()
    jqxhr = $.post('/db/payment', data)
    jqxhr.done(=>
      application.tracker?.trackEvent 'Finished gem purchase',
        productID: @productBeingPurchased.id
        value: @productBeingPurchased.amount
      document.location.reload()
    )
    jqxhr.fail(=>
      if jqxhr.status is 402
        @state = 'declined'
        @stateMessage = arguments[2]
      else if jqxhr.status is 500
        @state = 'retrying'
        f = _.bind @onStripeReceivedToken, @, e
        _.delay f, 2000
      else
        @state = 'unknown_error'
        @stateMessage = "#{jqxhr.status}: #{jqxhr.responseText}"
      @render()
    )

  onIAPComplete: (e) ->
    product = _.find @products, { id: e.productID }
    purchased = me.get('purchased') ? {}
    purchased = _.clone purchased
    purchased.gems ?= 0
    purchased.gems += product.gems
    me.set('purchased', purchased)
    @hide()

  onClickStartSubscription: (e) ->
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'buy gems modal'
