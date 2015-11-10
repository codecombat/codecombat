mongoose = require 'mongoose'
config = require '../../server_config'
PrepaidSchema = new mongoose.Schema {}, {strict: false, minimize: false,read:config.mongo.readpref}

PrepaidSchema.index({code: 1}, { unique: true })
PrepaidSchema.index({'redeemers.userID': 1})

PrepaidSchema.statics.generateNewCode = (done) ->
  tryCode = ->
    code = _.sample("abcdefghijklmnopqrstuvwxyz0123456789", 8).join('')
    Prepaid.findOne code: code, (err, prepaid) ->
      return done() if err
      return done(code) unless prepaid
      tryCode()
  tryCode()
  
PrepaidSchema.pre('save', (next) ->
  @set('exhausted', @get('maxRedeemers') <= _.size(@get('redeemers')))
  next()
)

PrepaidSchema.post 'init', (doc) ->
  doc.set('maxRedeemers', parseInt(doc.get('maxRedeemers')))

module.exports = Prepaid = mongoose.model('prepaid', PrepaidSchema)
