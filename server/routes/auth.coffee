authentication = require('passport')
LocalStrategy = require('passport-local').Strategy
User = require('../users/User')
UserHandler = require('../users/user_handler')
LevelSession = require '../levels/sessions/LevelSession'
config = require '../../server_config'
errors = require '../commons/errors'
mail = require '../commons/mail'
languages = require '../routes/languages'

module.exports.setup = (app) ->
  authentication.serializeUser((user, done) -> done(null, user._id))
  authentication.deserializeUser((id, done) ->
    User.findById(id, (err, user) -> done(err, user)))

  authentication.use(new LocalStrategy(
    (username, password, done) ->
      User.findOne({emailLower:username.toLowerCase()}).exec((err, user) ->
        return done(err) if err
        return done(null, false, {message:'not found', property:'email'}) if not user
        passwordReset = (user.get('passwordReset') or '').toLowerCase()
        if passwordReset and password.toLowerCase() is passwordReset
          User.update {_id: user.get('_id')}, {passwordReset: ''}, {}, ->
          return done(null, user)

        hash = User.hashPassword(password)
        unless user.get('passwordHash') is hash
          return done(null, false, {message:'is wrong.', property:'password'})
        return done(null, user)
      )
  ))
  app.post '/auth/spy', (req, res, next) ->
    if req?.user?.isAdmin()

      username = req.body.usernameLower
      emailLower = req.body.emailLower
      if emailLower
        query = {"emailLower":emailLower}
      else if username
        query = {"nameLower":username}
      else
        return errors.badInput res, "You need to supply one of emailLower or username"

      User.findOne query, (err, user) ->
        if err? then return errors.serverError res, "There was an error finding the specified user"

        unless user then return errors.badInput res, "The specified user couldn't be found"

        req.logIn user, (err) ->
          if err? then return errors.serverError res, "There was an error logging in with the specified"
          res.send(UserHandler.formatEntity(req, user))
          return res.end()
    else
      return errors.unauthorized res, "You must be an admin to enter espionage mode"

  app.post('/auth/login', (req, res, next) ->
    authentication.authenticate('local', (err, user, info) ->
      return next(err) if err
      if not user
        return errors.unauthorized(res, [{message:info.message, property:info.property}])

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
    res.send(UserHandler.formatEntity(req, req.user))
    res.end()

  app.post('/auth/logout', (req, res) ->
    req.logout()
    res.end()
  )

  app.post('/auth/reset', (req, res) ->
    unless req.body.email
      return errors.badInput(res, [{message:'Need an email specified.', property:'email'}])

    User.findOne({emailLower:req.body.email.toLowerCase()}).exec((err, user) ->
      if not user
        return errors.notFound(res, [{message:'not found.', property:'email'}])

      user.set('passwordReset', Math.random().toString(36).slice(2,7).toUpperCase())
      user.save (err) =>
        return errors.serverError(res) if err
        if config.isProduction
          options = createMailOptions req.body.email, user.get('passwordReset')
          mail.transport.sendMail options, (error, response) ->
            if error
              console.error "Error sending mail: #{error.message or error}"
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
          res.send "Unsubscribed #{req.query.email} from CodeCombat emails for #{session.levelName} #{session.team} ladder updates. Sorry to see you go! <p><a href='/play/ladder/#{session.levelID}#my-matches'>Ladder preferences</a></p>"
          res.end()

    User.findOne({emailLower:req.query.email.toLowerCase()}).exec (err, user) ->
      if not user
        return errors.notFound res, "No user found with email '#{req.query.email}'"

      emails = _.clone(user.get('emails')) or {}
      msg = ''

      if req.query.recruitNotes
        emails.recruitNotes ?= {}
        emails.recruitNotes.enabled = false
        msg = "Unsubscribed #{req.query.email} from recruiting emails."

      else
        msg = "Unsubscribed #{req.query.email} from all CodeCombat emails. Sorry to see you go!"
        emailSettings.enabled = false for emailSettings in _.values(emails)
        emails.generalNews ?= {}
        emails.generalNews.enabled = false
        emails.anyNotes ?= {}
        emails.anyNotes.enabled = false

      user.update {$set: {emails: emails}}, {}, =>
        return errors.serverError res, 'Database failure.' if err
        res.send msg + "<p><a href='/account/settings'>Account settings</a></p>"
        res.end()

module.exports.loginUser = loginUser = (req, res, user, send=true, next=null) ->
  user.save((err) ->
    if err
      return @sendDatabaseError(res, err)

    req.logIn(user, (err) ->
      if err
        return @sendDatabaseError(res, err)

      if send
        return @sendSuccess(res, user)
      next() if next
    )
  )

module.exports.makeNewUser = makeNewUser = (req) ->
  user = new User({anonymous:true})
  user.set 'testGroupNumber', Math.floor(Math.random() * 256)  # also in app/lib/auth
  user.set 'preferredLanguage', languages.languageCodeFromAcceptedLanguages req.acceptedLanguages

createMailOptions = (receiver, password) ->
  # TODO: use email templates here
  options =
    from: config.mail.username
    to: receiver
    replyTo: config.mail.username
    subject: "[CodeCombat] Password Reset"
    text: "You can log into your account with: #{password}"
