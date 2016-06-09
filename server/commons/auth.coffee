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

      # TODO: Add special iPad login endpoint. There was some logic here for the old, hacky method,
      # but was removed for username login 
      q = { $or: [
        { emailLower: username.toLowerCase() }
        { slug: _.str.slugify(username) }
      ]}
      
      User.findOne(q).exec((err, user) ->
        return done(err) if err
        if not user
          return done(new errors.Unauthorized('not found', { errorID: 'not-found' }))
        passwordReset = (user.get('passwordReset') or '').toLowerCase()
        if passwordReset and password.toLowerCase() is passwordReset
          User.update {_id: user.get('_id')}, {$unset: {passwordReset: ''}}, {}, ->
          return done(null, user)

        hash = User.hashPassword(password)
        unless user.get('passwordHash') is hash
          return done(new errors.Unauthorized('is wrong', { errorID: 'wrong-password' }))
        return done(null, user)
      )
  ))
