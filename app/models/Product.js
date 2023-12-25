// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ProductModel
const CocoModel = require('./CocoModel')
const utils = require('core/utils')

module.exports = (ProductModel = (function () {
  ProductModel = class ProductModel extends CocoModel {
    static initClass () {
      this.className = 'Product'
      this.schema = require('schemas/models/product.schema')
      this.prototype.urlRoot = '/db/products'
    }

    isRegionalSubscription (name) { return utils.isRegionalSubscription(name != null ? name : this.get('name')) }

    priceStringNoSymbol () { return (this.get('amount') / 100).toFixed(2) }

    adjustedPriceStringNoSymbol () {
      return (this.adjustedPrice() / 100).toFixed(2)
    }

    adjustedPrice () {
      let amt = this.get('amount')
      if ((this.get('coupons') != null) && (this.get('coupons').length > 0)) {
        amt = this.get('coupons')[0].amount
      }
      return amt
    }

    translateName () {
      if (/year_subscription/.test(this.get('name'))) {
        return i18n.t('subscribe.year_subscription')
      }
      if (/lifetime_subscription/.test(this.get('name'))) {
        return i18n.t('subscribe.lifetime')
      }
      return this.get('name')
    }

    purchase (token, options) {
      if (options == null) { options = {} }
      options.url = _.result(this, 'url') + '/purchase'
      options.method = 'POST'
      if (options.data == null) { options.data = {} }
      options.data.token = token != null ? token.id : undefined
      options.data.timestamp = new Date().getTime()
      options.data = JSON.stringify(options.data)
      options.contentType = 'application/json'
      return $.ajax(options)
    }

    purchaseWithPayPal (payment, options) {
      return this.purchase(undefined, _.merge({
        data: {
          service: 'paypal',
          paymentID: payment.id,
          payerID: payment.payer.payer_info.payer_id
        }
      }, options))
    }
  }
  ProductModel.initClass()
  return ProductModel
})())
