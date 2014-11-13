ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/buy-gems-modal'

module.exports = class BuyGemsModal extends ModalView
  id: 'buy-gems-modal'
  template: template
  plain: true

  originalProducts: [
    { price: '$4.99', gems: 5000, id: 'gems_5', i18n: 'buy_gems.few_gems' }
    { price: '$9.99', gems: 11000, id: 'gems_10', i18n: 'buy_gems.pile_gems' }
    { price: '$19.99', gems: 25000, id: 'gems_20', i18n: 'buy_gems.chest_gems' }
  ]

  subscriptions:
    'ipad:products': 'onIPadProducts'
    'ipad:iap-complete': 'onIAPComplete'

  events:
    'click .product button': 'onClickProductButton'

  constructor: (options) ->
    super(options)
    if application.isIPadApp
      @products = []
      Backbone.Mediator.publish 'buy-gems-modal:update-products'
    else
      @products = @originalProducts

  getRenderData: ->
    c = super()
    c.products = @products
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
    productID = $(e.target).closest('button.product').val()
    console.log 'purchasing', _.find @products, { id: productID }

    if application.isIPadApp
      Backbone.Mediator.publish 'buy-gems-modal:purchase-initiated', { productID: productID }

    else
      application.tracker?.trackEvent 'Started purchase', {productID:productID}, ['Google Analytics']
      alert('Not yet implemented, but thanks for trying!')

  onIAPComplete: (e) ->
    product = _.find @products, { id: e.productID }
    purchased = me.get('purchased') ? {}
    purchased = _.clone purchased
    purchased.gems ?= 0
    purchased.gems += product.gems
    me.set('purchased', purchased)
    @hide()
