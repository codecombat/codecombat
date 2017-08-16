errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
APIClient = require '../models/APIClient'

newSecret = wrap (req, res, next) ->
  client = yield database.getDocFromHandle(req, APIClient)
  if not client
    throw new errors.NotFound('APIClient not found.')
  secret = client.setNewSecret()
  yield client.save()
  res.status(200).send({ secret })

module.exports = {
  newSecret
}
