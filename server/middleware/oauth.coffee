OAuthProvider = require '../models/OAuthProvider'
database = require '../commons/database'
wrap = require 'co-express'
errors = require '../commons/errors'

module.exports =
  postOAuthProvider: wrap (req, res, next) ->
    provider = new OAuthProvider()
    provider.set(_.pick(req.body, _.identity))
    provider.set(_.pick(req.body, 'strictSSL'))
    
    database.validateDoc(provider)
    provider = yield provider.save()
    res.status(201).send(provider.toObject({req: req}))

  getOAuthProviderByName: wrap (req, res, next) ->
    providerName = req.query.name
    return next() if not providerName

    providers = yield OAuthProvider.find({name: providerName})
    res.send(providers)

  putOAuthProvider: wrap (req, res, next) ->
    provider = yield OAuthProvider.findById(req.body.id).exec()
    throw new errors.NotFound('Provider not found.') if not provider
    
    provider.set(_.pick(req.body, _.identity))
    provider.set(_.pick(req.body, 'strictSSL'))

    database.validateDoc(provider)
    provider = yield provider.save()
    res.send(provider.toObject({req: req}))