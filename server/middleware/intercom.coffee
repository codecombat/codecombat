errors = require '../commons/errors'
wrap = require 'co-express'
unsubscribe = require '../commons/unsubscribe'

webhook = wrap (req, res) ->
  unless req.signatureMatches
    throw new errors.Forbidden('Signature does not match.')
  if req.body.topic is 'user.unsubscribed'
    unsubscribe.unsubscribeEmailFromMarketingEmails(req.body.data.item.email)
  res.status(200).send()

module.exports = {
  webhook
}
