wrap = require 'co-express'
AnalyticsStripeInvoice = require './../models/AnalyticsStripeInvoice'

getAll = wrap (req, res) ->
  docs = yield AnalyticsStripeInvoice.find({}).lean()
  res.send(docs)

module.exports = {
  getAll
}
