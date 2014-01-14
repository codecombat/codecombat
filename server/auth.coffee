passport = require('passport')
winston = require('winston')
LocalStrategy = require('passport-local').Strategy
User = require('./models/User')
UserHandler = require('./handlers/user')
config = require '../server_config'
nodemailer = require 'nodemailer'
errors = require './errors'

module.exports.setupRoutes = (app) ->
  passport.serializeUser((user, done) -> done(null, user._id))
  passport.deserializeUser((id, done) ->
    User.findById(id, (err, user) -> done(err, user)))

  passport.use(new LocalStrategy(
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
          return done(null, false, {message:'is wrong, wrong, wrong', property:'password'}) 
        return done(null, user)
      )
  ))

  app.post('/auth/login', (req, res, next) ->
    passport.authenticate('local', (err, user, info) ->
      return next(err) if err
      if not user
        return errors.unauthorized(res, [{message:info.message, property:info.property}])

      req.logIn(user, (err) ->
        return next(err) if (err)
        res.send(UserHandler.formatEntity(req, req.user))
        return res.end()
      )
    )(req, res, next)
  )

  app.get('/auth/whoami', (req, res) ->
    res.setHeader('Content-Type', 'text/json');
    res.send(UserHandler.formatEntity(req, req.user))
    res.end()
  )

  app.post('/auth/logout', (req, res) ->
    req.logout()
    res.end()
  )

  app.post('/auth/reset', (req, res) ->
    unless req.body.email
      return errors.badInput(res, [{message:'Need an email specified.', property:email}])

    User.findOne({emailLower:req.body.email.toLowerCase()}).exec((err, user) ->
      if not user
        return errors.notFound(res, [{message:'not found.', property:'email'}])
        
      user.set('passwordReset', Math.random().toString(36).slice(2,7).toUpperCase())
      user.save (err) =>
        return errors.serverError(res) if err
        if config.isProduction
          transport = createSMTPTransport()
          options = createMailOptions req.body.email, user.get('passwordReset')
          transport.sendMail options, (error, response) ->
            if error
              console.error "Error sending mail: #{error.message or error}"
              return errors.serverError(res) if err
            else
              return res.end()
        else
          console.log 'new password is', user.get('passwordReset')
          return res.end()
    )
  )

createMailOptions = (receiver, password) ->
  # TODO: use email templates here
  options =
    from: config.mail.username
    to: receiver
    replyTo: config.mail.username
    subject: "[CodeCombat] Password Reset"
    text: "You can log into your account with: #{password}"
#html: message.replace '\n', '<br>\n'

createSMTPTransport = ->
  return smtpTransport if smtpTransport
  smtpTransport = nodemailer.createTransport "SMTP",
    service: config.mail.service
    user: config.mail.username
    pass: config.mail.password
    authMethod: "LOGIN"
  smtpTransport
