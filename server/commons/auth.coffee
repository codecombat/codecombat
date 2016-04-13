authentication = require 'passport'
LocalStrategy = require('passport-local').Strategy
User = require '../models/User'
config = require '../../server_config'
errors = require '../commons/errors'

module.exports.setup = ->
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
        if not user
          return done(new errors.Unauthorized('not found', { property: 'email' }))
        passwordReset = (user.get('passwordReset') or '').toLowerCase()
        if passwordReset and password.toLowerCase() is passwordReset
          User.update {_id: user.get('_id')}, {$unset: {passwordReset: ''}}, {}, ->
          return done(null, user)

        hash = User.hashPassword(password)
        unless user.get('passwordHash') is hash
          return done(new errors.Unauthorized('is wrong', { property: 'password' }))
        return done(null, user)
      )
  ))
