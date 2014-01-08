winston = require('winston')
schema = require('../schemas/user')
crypto = require('crypto')
request = require('request')
User = require('../models/User')
Handler = require('./Handler')
languages = require '../languages'
mongoose = require 'mongoose'
config = require '../../server_config'

serverProperties = ['passwordHash', 'emailLower', 'nameLower', 'passwordReset']
privateProperties = ['permissions', 'email', 'firstName', 'lastName', 'gender', 'facebookID', 'music', 'volume']

UserHandler = class UserHandler extends Handler
  modelClass: User

  editableProperties: [
    'name', 'photoURL', 'password', 'anonymous', 'wizardColor1', 'volume',
    'firstName', 'lastName', 'gender', 'facebookID', 'emailSubscriptions',
    'testGroupNumber', 'music', 'hourOfCode', 'hourOfCodeComplete', 'preferredLanguage'
  ]

  jsonSchema: schema
  
  constructor: ->
    super(arguments...)
    @editableProperties.push('permissions') unless config.isProduction

  formatEntity: (req, document) ->
    return null unless document?
    obj = document.toObject()
    delete obj[prop] for prop in serverProperties
    includePrivates = req.user and (req.user.isAdmin() or req.user._id.equals(document._id))
    delete obj[prop] for prop in privateProperties unless includePrivates

    # emailHash is used by gravatar
    hash = crypto.createHash('md5')
    if document.get('email')
      hash.update(_.trim(document.get('email')).toLowerCase())
    else
      hash.update(@_id+'')
    obj.emailHash = hash.digest('hex')

    return obj

  waterfallFunctions: [
    # FB access token checking
    # Check the email is the same as FB reports
    (req, user, callback) ->
      fbID = req.query.facebookID
      fbAT = req.query.facebookAccessToken
      return callback(null, req, user) unless fbID and fbAT
      url = "https://graph.facebook.com/me?access_token=#{fbAT}"
      request(url, (error, response, body) ->
        body = JSON.parse(body)
        emailsMatch = req.body.email is body.email
        return callback(res:'Invalid Facebook Access Token.', code:422) unless emailsMatch
        callback(null, req, user)
      )

    # GPlus access token checking
    (req, user, callback) ->
      gpID = req.query.gplusID
      gpAT = req.query.gplusAccessToken
      return callback(null, req, user) unless gpID and gpAT
      url = "https://www.googleapis.com/oauth2/v2/userinfo?access_token=#{gpAT}"
      request(url, (error, response, body) ->
        body = JSON.parse(body)
        emailsMatch = req.body.email is body.email
        return callback(res:'Invalid G+ Access Token.', code:422) unless emailsMatch
        callback(null, req, user)
      )

    # Email setting
    (req, user, callback) ->
      return callback(null, req, user) unless req.body.email?
      emailLower = req.body.email.toLowerCase()
      return callback(null, req, user) if emailLower is user.get('emailLower')
      User.findOne({emailLower:emailLower}).exec (err, otherUser) ->
        return callback(res:'Database error.', code:500) if err

        if (req.query.gplusID or req.query.facebookID) and otherUser
          # special case, log in as that user
          return req.logIn(otherUser, (err) ->
            return callback(res:'Facebook user login error.', code:500) if err
            return callback(null, req, otherUser)
          )
        r = {message:'is already used by another account', property:'email'}
        return callback({res:r, code:409}) if otherUser
        user.set('email', req.body.email)
        callback(null, req, user)

    # Name setting
    (req, user, callback) ->
      return callback(null, req, user) unless req.body.name
      nameLower = req.body.name?.toLowerCase()
      return callback(null, req, user) if nameLower is user.get('nameLower')
      User.findOne({nameLower:nameLower}).exec (err, otherUser) ->
        return callback(res:'Database error.', code:500) if err
        r = {message:'is already used by another account', property:'name'}
        return callback({res:r, code:409}) if otherUser
        user.set('name', req.body.name)
        callback(null, req, user)
  ]

  getById: (req, res, id) ->
    if req.user and req.user._id.equals(id)
      return @sendSuccess(res, @formatEntity(req, req.user))
    super(req, res, id)

  post: (req, res) ->
    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendBadInputError(res, 'Existing users cannot create new ones.') unless req.user.get('anonymous')
    req.body._id = req.user._id if req.user.get('anonymous')
    @put(req, res)

  hasAccessToDocument: (req, document) ->
    if req.route.method in ['put', 'post', 'patch']
      return true if req.user.isAdmin()
      return req.user._id.equals(document._id)
    return true

  getByRelationship: (req, res, args...) ->
    return @agreeToCLA(req, res) if args[1] is 'agreeToCLA'
    return @sendNotFoundError(res)
    
  agreeToCLA: (req, res) ->
    doc =
      user: req.user._id+''
      email: req.user.get 'email'
      name: req.user.get 'name'
      githubUsername: req.body.githubUsername
      created: new Date()+''
    collection = mongoose.connection.db.collection 'cla.submissions', (err, collection) ->
      return @sendDatabaseError(res, err) if err
      collection.insert doc, (err) ->
        return @sendDatabaseError(res, err) if err
        req.user.set('signedCLA', doc.created)
        req.user.save (err) ->
          return @sendDatabaseError(res, err) if err
          res.send({result:'success'})
          res.end()

module.exports = new UserHandler()

module.exports.setupMiddleware = (app) ->
  app.use (req, res, next) ->
    if req.user
      next()
    else
      user = new User({anonymous:true})
      user.set 'testGroupNumber', Math.floor(Math.random() * 256)  # also in app/lib/auth
      user.set 'preferredLanguage', languages.languageCodeFromAcceptedLanguages req.acceptedLanguages
      loginUser(req, res, user, false, next)

loginUser = (req, res, user, send=true, next=null) ->
  user.save((err) ->
    if err
      res.status(500)
      return res.end()

    req.logIn(user, (err) ->
      if err
        res.status(500)
        return res.end()

      if send
        res.send(user)
        return res.end()
      next() if next
    )
  )
