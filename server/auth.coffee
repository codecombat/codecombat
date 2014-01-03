passport = require('passport')
winston = require('winston')
LocalStrategy = require('passport-local').Strategy
User = require('./models/User')
UserHandler = require('./handlers/user')
config = require '../server_config'
nodemailer = require 'nodemailer'

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
        res.status(401)
        res.send([{message:info.message, property:info.property}])
        return res.end()

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
      res.status(422)
      res.send([{message:'Need an email specified.', property:email}])
      return res.end()
    User.findOne({emailLower:req.body.email.toLowerCase()}).exec((err, user) ->
      if not user
        res.status(404)
        res.send([{message:'not found.', property:'email'}])
        return res.end()
        
      user.set('passwordReset', Math.random().toString(36).slice(2,7).toUpperCase())
      user.save (err) =>
        return returnServerError(res) if err
        if config.isProduction
          transport = createSMTPTransport()
          options = createMailOptions req.body.email, user.get('passwordReset')
          transport.sendMail options, (error, response) ->
            if error
              console.error "Error sending mail: #{error.message or error}"
              return returnServerError(res) if err
            else
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

returnServerError = (res) ->
  res.status(500)
  res.send('Server error.')
  res.end()

