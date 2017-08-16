RootView = require 'views/core/RootView'
template = require 'templates/account/payments-view'
CocoCollection = require 'collections/CocoCollection'
Payments = require 'collections/Payments'
Prepaids = require 'collections/Prepaids'

module.exports = class PaymentsView extends RootView
  id: "payments-view"
  template: template

  initialize: ->
    @payments = new Payments()
    @supermodel.trackRequest @payments.fetchByRecipient(me.id)
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(me.id, {data: {allTypes: true}})

  onLoaded: ->
    @prepaidMap = _.zipObject(_.map(@prepaids.models, (m) => m.id), @prepaids.models)
    @reload?()
    super()
