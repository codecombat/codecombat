errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
APIClient = require '../models/APIClient'

postClient = wrap (req, res, next) ->
    client = new APIClient()
    client.set(_.pick(req.body, _.identity))
    client.set('creator', req.user._id)
    database.validateDoc(client)
    client = yield client.save()
    res.status(201).send(client.toObject({req: req}))

newSecret = wrap (req, res, next) ->
  client = yield database.getDocFromHandle(req, APIClient)
  if not client
    throw new errors.NotFound('APIClient not found.')
  secret = client.setNewSecret()
  yield client.save()
  res.status(200).send({ secret })

getByName = wrap (req, res, next) ->
    clientName = req.query.name
    return next() if not clientName
    clients = yield APIClient.find({name: clientName})
    res.send(clients)

module.exports = {
  postClient
  newSecret
  getByName
}
