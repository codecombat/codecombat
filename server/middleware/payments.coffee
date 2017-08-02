Payment = require '../models/Payment'
errors = require '../commons/errors'
wrap = require 'co-express'
parse = require '../commons/parse'

all = wrap (req, res) ->
  throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
  query = if req.query.nofree then {amount: {$gt: 0}} else {}
  if req.query.limit
    payments = yield Payment.find(query, parse.getProjectFromReq(req)).limit(parse.getLimitFromReq(req)).lean()
  else
    payments = yield Payment.find(query, parse.getProjectFromReq(req)).lean()
  res.send(payments)

module.exports = {
  all
}
