RootView = require 'views/core/RootView'
template = require 'templates/account/payments-view'
CocoCollection = require 'collections/CocoCollection'
Payment = require 'models/Payment'

module.exports = class PaymentsView extends RootView
  id: "payments-view"
  template: template

  constructor: (options) ->
    super(options)
    @payments = new CocoCollection([], { url: '/db/payment', model: Payment, comparator:'_id' })
    @supermodel.loadCollection(@payments, 'payments', {cache: false})
