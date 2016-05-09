RootView = require 'views/core/RootView'
template = require 'templates/account/payments-view'
CocoCollection = require 'collections/CocoCollection'
Payments = require 'collections/Payments'

module.exports = class PaymentsView extends RootView
  id: "payments-view"
  template: template

  initialize: ->
    @payments = new Payments()
    @supermodel.trackRequest(@payments.fetch({cache: false}))
