SkippedContact = require('../models/SkippedContact')
wrap = require('co').wrap

module.exports =
  fetchAll: wrap (req, res, next) ->
    skippedContacts = yield SkippedContact.find().exec()
    console.log skippedContacts
    res.status(200).send(skippedContacts)
