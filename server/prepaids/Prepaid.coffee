mongoose = require 'mongoose'
config = require '../../server_config'
PrepaidSchema = new mongoose.Schema {}, {strict: false, minimize: false,read:config.mongo.readpref}

PrepaidSchema.statics.generateNewCode = (done) ->
  tryCode = ->
    code = _.sample("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", 8).join('')
    Prepaid.findOne code: code, (err, prepaid) ->
      return done() if err
      return done(code) unless prepaid
      tryCode()
  tryCode()

module.exports = Prepaid = mongoose.model('prepaid', PrepaidSchema)
