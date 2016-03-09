authentication = require 'passport'
LocalStrategy = require('passport-local').Strategy
User = require '../users/User'
UserHandler = require '../users/user_handler'
LevelSession = require '../levels/sessions/LevelSession'
config = require '../../server_config'
errors = require '../commons/errors'
languages = require '../routes/languages'
sendwithus = require '../sendwithus'
log = require 'winston'
utils = require '../lib/utils'

module.exports.setup = (app) ->
  authentication.serializeUser((user, done) -> done(null, user._id))
  authentication.deserializeUser((id, done) ->
    User.findById(id, (err, user) -> done(err, user)))

  if config.picoCTF
    pico = require('../lib/picoctf');
    authentication.use new pico.PicoStrategy()
    return

  authentication.use(new LocalStrategy(
    (username, password, done) ->

      # kind of a hacky way to make it possible for iPads to 'log in' with their unique device id
      if username.length is 36 and '@' not in username # must be an identifier for vendor
        q = { iosIdentifierForVendor: username }
      else
        q = { emailLower: username.toLowerCase() }

      User.findOne(q).exec((err, user) ->
        return done(err) if err
        return done(null, false, {message: 'not found', property: 'email'}) if not user
        passwordReset = (user.get('passwordReset') or '').toLowerCase()
        if passwordReset and password.toLowerCase() is passwordReset
          User.update {_id: user.get('_id')}, {passwordReset: ''}, {}, ->
          return done(null, user)

        hash = User.hashPassword(password)
        unless user.get('passwordHash') is hash
          return done(null, false, {message: 'is wrong', property: 'password'})
        return done(null, user)
      )
  ))

  app.post('/auth/login', (req, res, next) ->
    authentication.authenticate('local', (err, user, info) ->
      return next(err) if err
      if not user
        return errors.unauthorized(res, [{message: info.message, property: info.property}])

      req.logIn(user, (err) ->
        return next(err) if (err)
        activity = req.user.trackActivity 'login', 1
        user.update {activity: activity}, (err) ->
          return next(err) if (err)
          res.send(UserHandler.formatEntity(req, req.user))
          return res.end()
      )
    )(req, res, next)
  )

  app.get('/auth/whoami', (req, res) ->
    if req.user
      sendSelf(req, res)
    else
      user = makeNewUser(req)
      makeNext = (req, res) -> -> sendSelf(req, res)
      next = makeNext(req, res)
      loginUser(req, res, user, false, next)
  )

  sendSelf = (req, res) ->
    res.setHeader('Content-Type', 'text/json')
    if req.query.callback
      res.jsonp UserHandler.formatEntity(req, req.user, true)
    else
      res.send UserHandler.formatEntity(req, req.user, false)
    res.end()

  app.post('/auth/logout', (req, res) ->
    req.logout()
    res.send({})
  )

  app.post('/auth/reset', (req, res) ->
    unless req.body.email
      return errors.badInput(res, [{message: 'Need an email specified.', property: 'email'}])

    User.findOne({emailLower: req.body.email.toLowerCase()}).exec((err, user) ->
      if not user
        return errors.notFound(res, [{message: 'not found', property: 'email'}])

      user.set('passwordReset', utils.getCodeCamel())
      emailContent = "<h3>Your temporary password: <b>#{user.get('passwordReset')}</b></h3>"
      emailContent += "<p>Reset your password at <a href=\"http://codecombat.com/account/settings\">http://codecombat.com/account/settings</a></p>"
      emailContent += "<p>Your old password cannot be retrieved.</p>"
      user.save (err) =>
        return errors.serverError(res) if err
        unless config.unittest
          context =
            email_id: sendwithus.templates.generic_email
            recipient:
              address: req.body.email
            email_data:
              subject: 'CodeCombat Recovery Password'
              title: ''
              content: emailContent
          sendwithus.api.send context, (err, result) ->
            if err
              console.error "Error sending password reset email: #{err.message or err}"
              return errors.serverError(res) if err
            else
              return res.end()
        else
          console.log 'password is', user.get('passwordReset')
          res.send user.get('passwordReset')
          return res.end()
    )
  )

  app.get '/auth/unsubscribe', (req, res) ->
    req.query.email = decodeURIComponent(req.query.email)
    email = req.query.email
    unless req.query.email
      return errors.badInput res, 'No email provided to unsubscribe.'

    if req.query.session
      # Unsubscribe from just one session's notifications instead.
      return LevelSession.findOne({_id: req.query.session}).exec (err, session) ->
        return errors.serverError res, 'Could not unsubscribe: #{req.query.session}, #{req.query.email}: #{err}' if err
        session.set 'unsubscribed', true
        session.save (err) ->
          return errors.serverError res, 'Database failure.' if err
          res.send "Unsubscribed #{req.query.email} from CodeCombat emails for #{session.get('levelName')} #{session.get('team')} ladder updates. Sorry to see you go! <p><a href='/play/ladder/#{session.levelID}#my-matches'>Ladder preferences</a></p>"
          res.end()

    User.findOne({emailLower: req.query.email.toLowerCase()}).exec (err, user) ->
      if not user
        return errors.notFound res, "No user found with email '#{req.query.email}'"

      emails = _.clone(user.get('emails')) or {}
      msg = ''

      if req.query.recruitNotes
        emails.recruitNotes ?= {}
        emails.recruitNotes.enabled = false
        msg = "Unsubscribed #{req.query.email} from recruiting emails."
      else if req.query.employerNotes
        emails.employerNotes ?= {}
        emails.employerNotes.enabled = false

        msg = "Unsubscribed #{req.query.email} from employer emails."
      else
        msg = "Unsubscribed #{req.query.email} from all CodeCombat emails. Sorry to see you go!"
        emailSettings.enabled = false for emailSettings in _.values(emails)
        emails.generalNews ?= {}
        emails.generalNews.enabled = false
        emails.anyNotes ?= {}
        emails.anyNotes.enabled = false

      user.update {$set: {emails: emails}}, {}, =>
        return errors.serverError res, 'Database failure.' if err
        res.send msg + '<p><a href="/account/settings">Account settings</a></p>'
        res.end()

  app.get '/auth/name*', (req, res) ->
    parts = req.path.split '/'
    originalName = decodeURI parts[3]
    return errors.badInput res, 'No name provided.' unless parts.length > 3 and originalName? and originalName isnt ''
    return errors.notFound res if parts.length isnt 4

    User.unconflictName originalName, (err, name) ->
      return errors.serverError res, err if err
      response = name: name
      if originalName is name
        res.send 200, response
      else
        errors.conflict res, response


module.exports.loginUser = loginUser = (req, res, user, send=true, next=null) ->
  user.save((err) ->
    return errors.serverError res, err if err?

    req.logIn(user, (err) ->
      return errors.serverError res, err if err?
      return res.send(user) and res.end() if send
      next() if next
    )
  )

module.exports.idCounter = 0

module.exports.makeNewUser = makeNewUser = (req) ->
  user = new User({anonymous: true})
  if global.testing
    # allows tests some control over user id creation
    newID = _.pad((module.exports.idCounter++).toString(16), 24, '0')
    user.set('_id', newID)
  user.set 'testGroupNumber', Math.floor(Math.random() * 256)  # also in app/core/auth
  lang = languages.languageCodeFromAcceptedLanguages req.acceptedLanguages
  user.set 'preferredLanguage', lang if lang[...2] isnt 'en'
  user.set 'preferredLanguage', 'pt-BR' if not user.get('preferredLanguage') and /br\.codecombat\.com/.test(req.get('host'))
  user.set 'preferredLanguage', 'zh-HANS' if not user.get('preferredLanguage') and /cn\.codecombat\.com/.test(req.get('host'))
  user.set 'lastIP', (req.headers['x-forwarded-for'] or req.connection.remoteAddress)?.split(/,? /)[0]
  user.set 'country', req.country if req.country
  #log.info "making new user #{user.get('_id')} with language #{user.get('preferredLanguage')} of #{req.acceptedLanguages} and country #{req.country} on #{if config.tokyo then 'Tokyo' else (if config.saoPaulo then 'Brazil' else 'US')} server and lastIP #{user.get('lastIP')}."
  user
