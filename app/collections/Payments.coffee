Payment = require 'models/Payment'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Payments extends CocoCollection
  model: Payment
  url: '/db/payment'

  fetchByRecipient: (recipientId, opts) ->
    opts ?= {}
    opts.data ?= {}
    opts.data.recipient = recipientId
    @fetch opts
