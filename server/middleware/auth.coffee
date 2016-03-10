# Middleware for both authentication and authorization

errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
parse = require '../commons/parse'
request = require 'request'
User = require '../users/User'
utils = require '../lib/utils'
mongoose = require 'mongoose'

module.exports =
  checkDocumentPermissions: (req, res, next) ->
    return next() if req.user?.isAdmin()
    if not req.doc.hasPermissionsForMethod(req.user, req.method)
      if req.user
        return next new errors.Forbidden('You do not have permissions necessary.')
      return next new errors.Unauthorized('You must be logged in.')
    next()
    
  checkLoggedIn: ->
    return (req, res, next) ->
      if not req.user
        return next new errors.Unauthorized('You must be logged in.')
      next()
    
  checkHasPermission: (permissions) ->
    if _.isString(permissions)
      permissions = [permissions]
    
    return (req, res, next) ->
      if not req.user
        return next new errors.Unauthorized('You must be logged in.')
      if not _.size(_.intersection(req.user.get('permissions'), permissions))
        return next new errors.Forbidden('You do not have permissions necessary.')
      next()

  loginByGPlus: wrap (req, res) ->
    gpID = req.body.gplusID
    gpAT = req.body.gplusAccessToken
    throw new errors.UnprocessableEntity('gplusID and gplusAccessToken required.') unless gpID and gpAT

    url = "https://www.googleapis.com/oauth2/v2/userinfo?access_token=#{gpAT}"
    [googleRes, body] = yield request.getAsync(url, {json: true})
    idsMatch = gpID is body.id
    throw new errors.UnprocessableEntity('Invalid G+ Access Token.') unless idsMatch
    user = yield User.findOne({gplusID: gpID})
    throw new errors.NotFound('No user with that G+ ID') unless user
    req.logInAsync = Promise.promisify(req.logIn)
    yield req.logInAsync(user)
    res.status(200).send(user.formatEntity(req))

  loginByFacebook: wrap (req, res) ->
    fbID = req.body.facebookID
    fbAT = req.body.facebookAccessToken
    throw new errors.UnprocessableEntity('facebookID and facebookAccessToken required.') unless fbID and fbAT

    url = "https://graph.facebook.com/me?access_token=#{fbAT}"
    [facebookRes, body] = yield request.getAsync(url, {json: true})
    idsMatch = fbID is body.id
    throw new errors.UnprocessableEntity('Invalid Facebook Access Token.') unless idsMatch
    user = yield User.findOne({facebookID: fbID})
    throw new errors.NotFound('No user with that Facebook ID') unless user
    req.logInAsync = Promise.promisify(req.logIn)
    yield req.logInAsync(user)
    res.status(200).send(user.formatEntity(req))
    
  spy: wrap (req, res) ->
    throw new errors.Unauthorized('You must be logged in to enter espionage mode') unless req.user
    throw new errors.Forbidden('You must be an admin to enter espionage mode') unless req.user.isAdmin()
    
    user = req.body.user
    throw new errors.UnprocessableEntity('Specify an id, username or email to espionage.') unless user
    if utils.isID(user)
      query = {_id: mongoose.Types.ObjectId(user)}
    else
      user = user.toLowerCase()
      query = $or: [{nameLower: user}, {emailLower: user}]
    user = yield User.findOne(query)
    amActually = req.user
    throw new errors.NotFound() unless user
    req.loginAsync = Promise.promisify(req.login)
    yield req.loginAsync user
    req.session.amActually = amActually.id
    res.status(200).send(user.toObject({req: req}))
    
  stopSpying: wrap (req, res) ->
    throw new errors.Unauthorized('You must be logged in to leave espionage mode') unless req.user
    throw new errors.Forbidden('You must be in espionage mode to leave it') unless req.session.amActually
    
    user = yield User.findById(req.session.amActually)
    delete req.session.amActually
    throw new errors.NotFound() unless user
    req.loginAsync = Promise.promisify(req.login)
    yield req.loginAsync user
    res.status(200).send(user.toObject({req: req}))
