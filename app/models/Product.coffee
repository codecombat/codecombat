CocoModel = require './CocoModel'
utils = require 'core/utils'

module.exports = class ProductModel extends CocoModel
  @className: 'Product'
  @schema: require 'schemas/models/product.schema'
  urlRoot: '/db/products'

  isRegionalSubscription: (name) -> utils.isRegionalSubscription(name ? @get('name'))

  priceStringNoSymbol: -> (@get('amount') / 100).toFixed(2)

  adjustedPriceStringNoSymbol: ->
    (@adjustedPrice() / 100).toFixed(2)

  adjustedPrice: ->
    amt = @get('amount')
    if @get('coupons')? and @get('coupons').length > 0
      amt = @get('coupons')[0].amount
    amt

  translateName: ->
    if /year_subscription/.test @get('name')
      return i18n.translate('subscribe.year_subscription')
    if /lifetime_subscription/.test @get('name')
      return i18n.translate('subscribe.lifetime')
    @get('name')

  purchase: (token, options={}) ->
    options.url = _.result(@, 'url') + '/purchase'
    options.method = 'POST'
    options.data ?= {}
    options.data.token = token?.id
    options.data.timestamp = new Date().getTime()
    options.data = JSON.stringify(options.data)
    options.contentType = 'application/json'
    return $.ajax(options)

  purchaseWithPayPal: (payment, options) ->
    @purchase(undefined, _.merge({
      data:
        service: 'paypal'
        paymentID: payment.id
        payerID: payment.payer.payer_info.payer_id
    }, options))
