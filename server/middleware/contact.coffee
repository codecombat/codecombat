sendwithus = require '../sendwithus'
utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
parse = require '../commons/parse'

module.exports =
  sendParentSignupInstructions: wrap (req, res, next) ->
    context =
      email_id: sendwithus.templates.coppa_deny_parent_signup
      recipient:
        address: req.body.parentEmail
    if /@codecombat.com/.test(context.recipient.address) or not _.string.trim context.recipient.address
      console.error "Somehow sent an email with bogus recipient? #{context.recipient.address}"
      return next(new errors.InternalServerError("Error sending email. Need a valid recipient."))
    sendwithus.api.send context, (err, result) ->
      if err
        return next(new errors.InternalServerError("Error sending email. Check that it's valid and try again."))
      else
        res.status(200).send()
