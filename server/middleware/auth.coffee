# Middleware for both authentication and authorization

errors = require '../commons/errors'
log = require 'winston'
wrap = require 'co-express'
Promise = require 'bluebird'
parse = require '../commons/parse'
request = require 'request'
User = require '../models/User'
utils = require '../lib/utils'
mongoose = require 'mongoose'
authentication = require 'passport'
sendgrid = require '../sendgrid'
LevelSession = require '../models/LevelSession'
config = require '../../server_config'
oauth = require '../lib/oauth'
facebook = require '../lib/facebook'
OAuthProvider = require '../models/OAuthProvider'
querystring = require 'querystring'
{ unsubscribeEmailFromMarketingEmails } = require '../commons/unsubscribe'

module.exports =
  authDelay: (req, res, next) ->
    ms = if global.testing then 0 else 500
    setTimeout(next, ms)

  checkDocumentPermissions: (req, res, next) ->
    return next() if req.user?.isAdmin()
    if not req.doc.hasPermissionsForMethod(req.user, req.method)
      if req.user
        return next new errors.Forbidden('You do not have permissions necessary.')
      return next new errors.Unauthorized('You must be logged in.')
    next()

  checkLoggedIn: ->
    return (req, res, next) ->
      if (not req.user) or (req.user.isAnonymous())
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

  checkHasUser: ->
    return (req, res, next) ->
      if not req.user
        return next new errors.Unauthorized('No user associated with this request.')
      next()

  whoAmI: wrap (req, res) ->
    if not req.user
      user = User.makeNew(req)
      yield user.save()
      req.logInAsync = Promise.promisify(req.logIn)
      yield req.logInAsync(user)

    if req.query.callback
      res.jsonp(req.user.toObject({req, publicOnly: true}))
    else
      res.send(req.user.toObject({req, publicOnly: false}))
    res.end()

  afterLogin: wrap (req, res, next) ->
    activity = req.user.trackActivity 'login', 1
    yield req.user.update {activity: activity}
    res.status(200).send(req.user.toObject({req: req}))

  redirectAfterLogin: wrap (req, res) ->
    activity = req.user.trackActivity 'login', 1
    yield req.user.update {activity: activity}
    if req.shouldRedirect
      res.redirect req.shouldRedirect
    else if req.user.get('role') is 'student'
      res.redirect '/students'
    else if req.user.get('role')
      res.redirect '/teachers/classes'
    else
      res.redirect '/play'

  loginByGPlus: wrap (req, res, next) ->
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
    next()

  loginByClever: wrap (req, res, next) ->
    throw new errors.UnprocessableEntity('Clever integration not configured.') unless config.clever.client_id and config.clever.client_secret

    code = req.query.code
    scope = req.query.scope
    throw new errors.UnprocessableEntity('code and scope required.') unless code and scope


    [cleverRes, auth] = yield request.postAsync
      json: true
      url: "https://clever.com/oauth/tokens"
      form:
        code: code
        grant_type: 'authorization_code'
        redirect_uri: config.clever.redirect_uri

      auth:
        user: config.clever.client_id
        password: config.clever.client_secret
        sendImmediately: true


    throw new errors.UnprocessableEntity('Invalid Clever OAuth Code.') unless auth.access_token

    [re2, userInfo] = yield request.getAsync
      json : true
      url: 'https://api.clever.com/me'
      auth:
        bearer: auth.access_token

    [lookupRes, lookup] = yield request.getAsync
        url: "https://api.clever.com/v1.1/#{userInfo.data.type}s/#{userInfo.data.id}"
        json: true
        auth:
          bearer: auth.access_token

    unless lookupRes.statusCode is 200
      throw new errors.Forbidden("Couldn't look up user.  Is data sharing enabled in clever?")


    user = yield User.findOne({cleverID: userInfo.data.id})
    unless user
      email = lookup.data.email
      if email?
        existingUserWithEmail = yield User.findOne({emailLower: email.toLowerCase()})

      if existingUserWithEmail or not email?
        email = "#{userInfo.data.id}@clever.user"
        existingUserWithEmail = yield User.findOne({emailLower: email.toLowerCase()})
      if existingUserWithEmail
        email = undefined

      name = "Clever"
      if lookup.data.name
        name = "#{lookup.data.name?.first}#{lookup.data.name.last?.substr(0,1)}"

      User.unconflictNameAsync = Promise.promisify(User.unconflictName)
      name = yield User.unconflictNameAsync name

      user = new User
        anonymous: false
        role: if userInfo.data.type is 'student' then 'student' else 'teacher'
        cleverID: userInfo.data.id
        emailVerified: true
        email: email
        name: name

      user.set 'testGroupNumber', Math.floor(Math.random() * 256)  # also in app/core/auth


    if lookup.data.name
      user.set 'firstName', lookup.data.name.first
      user.set 'lastName', lookup.data.name.last

    yield user.save()

    #console.log JSON.stringify
    #  userInfo: userInfo
    #  lookup: lookup
    #,null,'  '

    req.logInAsync = Promise.promisify(req.logIn)
    yield req.logInAsync(user)
    next()

  loginByFacebook: wrap (req, res, next) ->
    fbID = req.body.facebookID
    fbAT = req.body.facebookAccessToken
    throw new errors.UnprocessableEntity('facebookID and facebookAccessToken required.') unless fbID and fbAT
    facebookPerson = yield facebook.fetchMe(fbAT)
    idsMatch = fbID is facebookPerson.id
    throw new errors.UnprocessableEntity('Invalid Facebook Access Token.') unless idsMatch
    user = yield User.findOne({facebookID: fbID})
    throw new errors.NotFound('No user with that Facebook ID') unless user
    req.logInAsync = Promise.promisify(req.logIn)
    yield req.logInAsync(user)
    next()

  loginByOAuthProvider: wrap (req, res, next) ->
    { provider: providerId, accessToken, code, redirect } = req.query
    identity = yield oauth.getIdentityFromOAuth({providerId, accessToken, code})

    user = yield User.findOne({oAuthIdentities: { $elemMatch: identity }})
    if not user
      throw new errors.NotFound('No user with this identity exists')

    req.loginAsync = Promise.promisify(req.login)
    yield req.loginAsync user

    if redirect
      req.shouldRedirect = redirect
    else
      provider = yield OAuthProvider.findById(providerId)
      req.shouldRedirect = provider.get('redirectAfterLogin')

    next()

  redirectOnError: wrap (err, req, res, next) ->
    { errorRedirect } = req.query
    return next(err) unless errorRedirect
    qs = querystring.stringify(err.toJSON())
    res.redirect errorRedirect + '?' + qs

  spy: wrap (req, res) ->
    throw new errors.Unauthorized('You must be logged in to enter espionage mode') unless req.user
    throw new errors.Forbidden('You must be an admin to enter espionage mode') unless req.user.isAdmin()

    user = req.body.user
    throw new errors.UnprocessableEntity('Specify an id, username or email to espionage.') unless user
    user = yield User.search(user)
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

  logout: (req, res) ->
    req.logout()
    res.send({})

  reset: wrap (req, res) ->
    unless req.body.email
      throw new errors.UnprocessableEntity('Need an email specified.', {property: 'email'})

    user = yield User.findOne({emailLower: req.body.email.toLowerCase()})
    if not user
      throw new errors.NotFound('not found', {property: 'email'})

    user.set('passwordReset', utils.getCodeCamel())
    yield user.save()
    message =
      templateId: sendgrid.templates.password_reset
      to:
        email: req.body.email
      from:
        email: config.mail.username
        name: 'CodeCombat'
      substitutions:
        tempPassword: user.get('passwordReset')
    try
      yield sendgrid.api.send message
    catch err
      log.error("auth/reset sendgrid error: #{JSON.stringify(err)}\n#{JSON.stringify(message)}")
    res.end()

  unsubscribe: wrap (req, res) ->
    # need to grab email directly from url, in case it has "+" in it
    queryString = req.url.split('?')[1] or ''
    queryParts = queryString.split('&')
    email = null
    for part in queryParts
      [name, value] = part.split('=')
      if name is 'email'
        email = value
        break

    unless email
      throw new errors.UnprocessableEntity 'No email provided to unsubscribe.'
    email = decodeURIComponent(email)

    if req.query.session
      # Unsubscribe from just one session's notifications instead.
      session = yield LevelSession.findOne({_id: req.query.session})
      if not session
        throw new errors.NotFound "Level session not found"
      session.set 'unsubscribed', true
      yield session.save()
      res.send "Unsubscribed #{email} from CodeCombat emails for #{session.get('levelName')} #{session.get('team')} ladder updates. Sorry to see you go! <p><a href='/play/ladder/#{session.levelID}#my-matches'>Ladder preferences</a></p>"
      res.end()
      return

    user = yield User.findOne({emailLower: email.toLowerCase()})
    if not user
      throw new errors.NotFound "No user found with email '#{email}'"

    emails = _.clone(user.get('emails')) or {}
    msg = ''

    newConsentHistory = []
    addNewConsentHistoryItem = (description) ->
      newConsentHistory.push
        action: 'forbid'
        date: new Date()
        type: 'email'
        emailHash: User.hashEmail(user.get('email'))
        description: description

    if req.query.recruitNotes
      msg = "Unsubscribed #{email} from recruiting emails."
      emails.recruitNotes ?= {}
      emails.recruitNotes.enabled = false
      addNewConsentHistoryItem('recruitNotes')
    else if req.query.employerNotes
      msg = "Unsubscribed #{email} from employer emails."
      emails.employerNotes ?= {}
      emails.employerNotes.enabled = false
      addNewConsentHistoryItem('employerNotes')
    else
      msg = "Unsubscribed #{email} from all CodeCombat announcement and marketing emails. Sorry to see you go!"
      yield unsubscribeEmailFromMarketingEmails(email)
      res.send msg + '<p><a href="/account/settings">Account settings</a></p>'
      res.end()
      return

    yield user.update {$set: {emails: emails}}
    yield user.update {$push: {'consentHistory': newItem}} for newItem in newConsentHistory
    res.send msg + '<p><a href="/account/settings">Account settings</a></p>'
    res.end()

  name: wrap (req, res) ->
    if not req.params.name
      throw new errors.UnprocessableEntity 'No name provided.'
    givenName = req.params.name

    User.unconflictNameAsync = Promise.promisify(User.unconflictName)
    suggestedName = yield User.unconflictNameAsync givenName
    response = {
      givenName
      suggestedName
      conflicts: givenName isnt suggestedName
    }
    res.status(200).send response

  email: wrap (req, res) ->
    { email } = req.params
    if not email
      throw new errors.UnprocessableEntity 'No email provided.'

    user = yield User.findByEmail(email)
    res.status(200).send { exists: user? }
