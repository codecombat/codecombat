Promise = require 'bluebird'
mongoose = require 'mongoose'
config = require '../../server_config'
PrepaidSchema = new mongoose.Schema {
  creator: mongoose.Schema.Types.ObjectId
}, {strict: false, minimize: false,read:config.mongo.readpref}
co = require 'co'
jsonSchema = require '../../app/schemas/models/prepaid.schema'

PrepaidSchema.index({code: 1}, { unique: true })
PrepaidSchema.index({'redeemers.userID': 1})
PrepaidSchema.index({owner: 1, endDate: 1}, { sparse: true })

PrepaidSchema.statics.DEFAULT_START_DATE = new Date(2016,4,15).toISOString()
PrepaidSchema.statics.DEFAULT_END_DATE = new Date(2017,5,1).toISOString()

PrepaidSchema.statics.generateNewCode = (done) ->
  # Deprecated for not following Node callback convention. TODO: Remove
  tryCode = ->
    code = _.sample("abcdefghijklmnopqrstuvwxyz0123456789", 8).join('')
    Prepaid.findOne code: code, (err, prepaid) ->
      return done() if err
      return done(code) unless prepaid
      tryCode()
  tryCode()
  
PrepaidSchema.statics.generateNewCodeAsync = co.wrap (done) ->
  code = null
  while true
    code = _.sample("abcdefghijklmnopqrstuvwxyz0123456789", 8).join('')
    prepaid = yield Prepaid.findOne({code: code})
    break if not prepaid
  return code

PrepaidSchema.pre('save', (next) ->
  @set('exhausted', @get('maxRedeemers') <= _.size(@get('redeemers')))
  if not @get('code')
    Prepaid.generateNewCode (code) =>
      @set('code', code)
      next()
  else
    next()
)

PrepaidSchema.post 'init', (doc) ->
  doc.set('maxRedeemers', parseInt(doc.get('maxRedeemers') ? 0))
  if @get('type') is 'course'
    if not @get('startDate')
      @set('startDate', Prepaid.DEFAULT_START_DATE)
    if not @get('endDate')
      @set('endDate', Prepaid.DEFAULT_END_DATE)

PrepaidSchema.statics.postEditableProperties = [
  'creator', 'maxRedeemers', 'properties', 'type', 'startDate', 'endDate'
]
PrepaidSchema.statics.editableProperties = []
PrepaidSchema.statics.jsonSchema = jsonSchema

module.exports = Prepaid = mongoose.model('prepaid', PrepaidSchema)
