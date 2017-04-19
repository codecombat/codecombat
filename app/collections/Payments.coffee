Payment = require 'models/Payment'
CocoCollection = require 'collections/CocoCollection'

module.exports = class Payments extends CocoCollection
  model: Payment
  url: '/db/payment'

  fetchByCreator: (creatorID, opts) ->
    opts ?= {}
    opts.data ?= {}
    opts.data.creator = creatorID
    @fetch opts
