RootView = require 'views/core/RootView'
template = require 'templates/account/payments-view'
CocoCollection = require 'collections/CocoCollection'
Payments = require 'collections/Payments'
Prepaids = require 'collections/Prepaids'

module.exports = class PaymentsView extends RootView
  id: "payments-view"
  template: template

  initialize: ->
    super()

    @payments = new Payments()
    @supermodel.trackRequest @payments.fetchByRecipient(me.id)
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(me.id, {data: {allTypes: true}})

  getMeta: ->
    title: $.i18n.t 'account.payments_title'

  onLoaded: ->
    @prepaidMap = _.zipObject(_.map(@prepaids.models, (m) => m.id), @prepaids.models)
    @reload?()

    # for administration
    for payment in @payments.models
      payPal = payment.get('payPal')
      transactionId = payPal?.transactions?[0]?.related_resources?[0]?.sale?.id
      if transactionId
        console.log('PayPal Payment', transactionId, payment.get('amount'))

      payPalSale = payment.get('payPalSale')
      transactionId = payPalSale?.id
      if transactionId
        console.log('PayPal Subscription Payment', transactionId)

    super()
