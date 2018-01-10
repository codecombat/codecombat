Payment = require '../models/Payment'
errors = require '../commons/errors'
wrap = require 'co-express'
parse = require '../commons/parse'

all = wrap (req, res) ->
  throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
  query = {}
  if req.query.nofree
    query.amount = {$gt: 0}
  if req.query.payPalResource
    query['$or'] = [
      {'payPal.transactions.related_resources.sale.id': req.query.payPalResource},
      {'payPalSale.id': req.query.payPalResource},
    ]
  dbq = Payment.find(query, parse.getProjectFromReq(req))
  dbq.limit(parse.getLimitFromReq(req, {min: 0, default: 0}))
  dbq.skip(parse.getSkipFromReq(req))
  dbq.select(parse.getProjectFromReq(req))
  payments = yield dbq.lean().exec()
  res.send(payments)

module.exports = {
  all
}
