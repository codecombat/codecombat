passport = require('passport')
winston = require('winston')
LocalStrategy = require('passport-local').Strategy
User = require('../users/User')
UserHandler = require('../users/user_handler')
config = require '../../server_config'
errors = require '../commons/errors'
mail = require '../commons/mail'

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
          console.log 'new password is', user.get('passwordReset')
          return res.end()
    )
  )
  
  app.get '/auth/unsubscribe', (req, res) ->
    email = req.query.email
    unless req.query.email
      return errors.badInput res, 'No email provided to unsubscribe.'
      
    User.findOne({emailLower:req.query.email.toLowerCase()}).exec (err, user) ->
      if not user
        return errors.notFound res, "No user found with email '#{req.query.email}'"

      user.set('emailSubscriptions', [])
      user.save (err) =>
        return errors.serverError res, 'Database failure.' if err

        res.send "Unsubscribed #{req.query.email} from all CodeCombat emails. Sorry to see you go! <p><a href='/account/settings'>Account settings</a></p>"
        res.end()

createMailOptions = (receiver, password) ->
  # TODO: use email templates here
  options =
    from: config.mail.username
    to: receiver
    replyTo: config.mail.username
    subject: "[CodeCombat] Password Reset"
    text: "You can log into your account with: #{password}"
#