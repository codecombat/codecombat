schema = require './user_schema'
crypto = require 'crypto'
request = require 'request'
User = require './User'
Handler = require '../commons/Handler'
mongoose = require 'mongoose'
config = require '../../server_config'
errors = require '../commons/errors'
async = require 'async'

serverProperties = ['passwordHash', 'emailLower', 'nameLower', 'passwordReset']
privateProperties = ['permissions', 'email', 'firstName', 'lastName', 'gender', 'facebookID', 'music', 'volume']

UserHandler = class UserHandler extends Handler
  modelClass: User

  editableProperties: [
    'name', 'photoURL', 'password', 'anonymous', 'wizardColor1', 'volume',
    'firstName', 'lastName', 'gender', 'facebookID', 'emailSubscriptions',
    'testGroupNumber', 'music', 'hourOfCode', 'hourOfCodeComplete', 'preferredLanguage',
    'wizard'
  ]

  jsonSchema: schema

  constructor: ->
    super(arguments...)
    @editableProperties.push('permissions') unless config.isProduction

  formatEntity: (req, document) ->
    return null unless document?
    obj = document.toObject()
    delete obj[prop] for prop in serverProperties
    includePrivates = req.user and (req.user?.isAdmin() or req.user?._id.equals(document._id))
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
    if req.user?._id.equals(id)
      return @sendSuccess(res, @formatEntity(req, req.user))
    super(req, res, id)
    
  getNamesByIds: (req, res) ->
    ids = req.query.ids or req.body.ids
    ids = ids.split(',') if _.isString ids
    ids = _.uniq ids
    
    makeFunc = (id) ->
      (callback) ->
        User.findById(id, {name:1}).exec (err, document) ->
          return done(err) if err
          callback(null, document?.get('name') or '')
          
    funcs = {}
    for id in ids
      return errors.badInput(res, "Given an invalid id: #{id}") unless Handler.isID(id)
      funcs[id] = makeFunc(id)
    
    async.parallel funcs, (err, results) ->
      return errors.serverError err if err
      res.send results
      res.end()

  nameToID: (req, res, name) ->
    User.findOne({nameLower:name.toLowerCase()}).exec (err, otherUser) ->
      res.send(if otherUser then otherUser._id else JSON.stringify(''))
      res.end()

  post: (req, res) ->
    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendBadInputError(res, 'Must have an anonymous user to post with.') unless req.user
    return @sendBadInputError(res, 'Existing users cannot create new ones.') unless req.user.get('anonymous')
    req.body._id = req.user._id if req.user.get('anonymous')
    @put(req, res)

  hasAccessToDocument: (req, document) ->
    if req.route.method in ['put', 'post', 'patch']
      return true if req.user?.isAdmin()
      return req.user?._id.equals(document._id)
    return true

  getByRelationship: (req, res, args...) ->
    return @agreeToCLA(req, res) if args[1] is 'agreeToCLA'
    return @avatar(req, res, args[0]) if args[1] is 'avatar'
    return @getNamesByIds(req, res) if args[1] is 'names'
    return @nameToID(req, res, args[0]) if args[1] is 'nameToID'
    return @sendNotFoundError(res)

  agreeToCLA: (req, res) ->
    return @sendUnauthorizedError(res) unless req.user
    doc =
      user: req.user._id+''
      email: req.user.get 'email'
      name: req.user.get 'name'
      githubUsername: req.body.githubUsername
      created: new Date()+''
    collection = mongoose.connection.db.collection 'cla.submissions', (err, collection) =>
      return @sendDatabaseError(res, err) if err
      collection.insert doc, (err) =>
        return @sendDatabaseError(res, err) if err
        req.user.set('signedCLA', doc.created)
        req.user.save (err) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res, {result:'success'})

  avatar: (req, res, id) ->
    @modelClass.findById(id).exec (err, document) ->
      return @sendDatabaseError(res, err) if err
      res.redirect(document?.get('photoURL') or '/images/generic-wizard-icon.png')
      res.end()

module.exports = new UserHandler()