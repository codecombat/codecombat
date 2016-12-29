SkippedContact = require('../models/SkippedContact')
wrap = require('co-express')
database = require '../commons/database'
errors = require '../commons/errors'

module.exports =
  fetchAll: wrap (req, res, next) ->
    skippedContacts = yield SkippedContact.find().exec()
    res.status(200).send(skippedContacts)

  put: wrap (req, res, next) ->
    skippedContact = yield SkippedContact.findById(req.body._id).exec()
    throw new errors.NotFound('Skipped Contact not found.') if not skippedContact
    database.assignBody(req, skippedContact)
    database.validateDoc(skippedContact)
    skippedContact = yield skippedContact.save()
    skippedContact = yield SkippedContact.findById(req.body._id)
    res.status(200).send(skippedContact.toObject({req: req}))
