require('app/styles/play/modal/buy-gems-modal.sass')
require('app/styles/play/modal/lang-nl/buy-gems-modal-nl.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/buy-gems-modal'
stripeHandler = require 'core/services/stripe'
utils = require 'core/utils'
SubscribeModal = require 'views/core/SubscribeModal'
Products = require 'collections/Products'
CreateAccountModal = require 'views/core/CreateAccountModal'

module.exports = class BuyGemsModal extends ModalView
  id:
    if (me.get('preferredLanguage',true) || 'en-US').split('-')[0] == 'nl'
      'buy-gems-modal-nl'
    else
      'buy-gems-modal'
  template: template
  plain: true

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
    @products = new Products()
    @products.comparator = 'amount'
    if application.isIPadApp
      @products = []
      Backbone.Mediator.publish 'buy-gems-modal:update-products'
    else
      @supermodel.loadCollection(@products, 'products')
      $.post '/db/payment/check-stripe-charges', (something, somethingElse, jqxhr) =>
        if jqxhr.status is 201
          @state = 'recovered_charge'
          @render()
    @trackTimeVisible({ trackViewLifecycle: true })

  onLoaded: ->
    @basicProduct = @products.getBasicSubscriptionForUser(me)
    @lifetimeProduct = @products.getLifetimeSubscriptionForUser(me)
    @products.reset @products.filter (product) -> _.string.startsWith(product.get('name'), 'gems_')
    super()

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @playSound 'game-menu-open'
    if @basicProduct
      @$el.find('.subscription-gem-amount').text $.i18n.t('buy_gems.price').replace('{{gems}}', @basicProduct.get('gems'))

  onHidden: ->
    super()
    @playSound 'game-menu-close'

  onIPadProducts: (e) ->
    # TODO: Update to handle new products collection
#    newProducts = []
#    for iapProduct in e.products
#      localProduct = _.find @originalProducts, { id: iapProduct.id }
#      continue unless localProduct
#      localProduct.price = iapProduct.price
#      newProducts.push localProduct
#    @products = _.sortBy newProducts, 'gems'
#    @render()
    
  getProductDescription: (productName) ->
    return switch productName
      when 'gems_5' then 'buy_gems.few_gems'
      when 'gems_10' then 'buy_gems.pile_gems'
      when 'gems_20' then 'buy_gems.chest_gems'
      else ''

  onClickProductButton: (e) ->
    @playSound 'menu-button-click'
    return @openModalView new CreateAccountModal() if me.get('anonymous')
    productID = $(e.target).closest('button').val()
    # Don't throw error when product is not found
    if productID.length == 0
      return
    product = @products.findWhere { name: productID }

    if application.isIPadApp
      Backbone.Mediator.publish 'buy-gems-modal:purchase-initiated', { productID: productID }

    else
      application.tracker?.trackEvent 'Started gem purchase', { productID: productID }
      stripeHandler.open({
        description: $.t(@getProductDescription(product.get('name')))
        amount: product.get('amount')
        bitcoin: true
        alipay: if me.get('country') is 'china' or (me.get('preferredLanguage') or 'en-US')[...2] is 'zh' then true else 'auto'
      })

    @productBeingPurchased = product

  onStripeReceivedToken: (e) ->
    data = {
      productID: @productBeingPurchased.get('name')
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
        productID: @productBeingPurchased.get('name')
        value: @productBeingPurchased.get('amount')
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
    product = @products.findWhere { name: e.productID }
    purchased = me.get('purchased') ? {}
    purchased = _.clone purchased
    purchased.gems ?= 0
    purchased.gems += product.gems
    me.set('purchased', purchased)
    @hide()

  onClickStartSubscription: (e) ->
    @openModalView new SubscribeModal()
    window.tracker?.trackEvent 'Show subscription modal', category: 'Subscription', label: 'buy gems modal'
