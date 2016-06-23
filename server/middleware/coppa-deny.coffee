sendwithus = require '../sendwithus'
utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
parse = require '../commons/parse'

module.exports =
  sendParentSignupInstructions: wrap (req, res) ->
    context =
      email_id: sendwithus.templates.coppa_deny_parent_signup
      recipient:
        address: req.body.parentEmail
    sendwithus.api.send context, (err, result) ->
      console.log err
      console.log result
      if err
        res.status(400).send { error: err }
      else
        res.status(200).send()
