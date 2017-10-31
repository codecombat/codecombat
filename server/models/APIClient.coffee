mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
log = require 'winston'
config = require '../../server_config'
jsonSchema = require '../../app/schemas/models/api-client.schema.coffee'
crypto = require 'crypto'

APIClientSchema = new mongoose.Schema(body: String, {strict: false,read:config.mongo.readpref})

APIClientSchema.statics.jsonSchema = jsonSchema

APIClientSchema.methods.setNewSecret = ->
  secret = _.times(40, -> (_.random(0,Math.pow(2,4)-1)).toString(16)).join('') # 40 hex character string
  @set('secret', APIClient.hash(secret))
  return secret

APIClientSchema.methods.hasControlOfUser = (user, action=undefined) ->
  # Check for The Woo
  return true if @id is '582a4105053eea2400e0c7e8' and user.get('createdOnHost') is 'cp.codecombat.com'
  return true if @id is '5930b75dee776800313fefca' and user.get('country') is 'brazil' and action in ['put-user-license', 'put-user-subscription']
  return @_id.equals(user.get('clientCreator'))

APIClientSchema.statics.hash = (secret) ->
  shasum = crypto.createHash('sha512').update(config.salt + secret)
  return shasum.digest('hex')

APIClientSchema.statics.postEditableProperties = []
APIClientSchema.statics.editableProperties = ['name']

APIClientSchema.plugin(plugins.NamedPlugin)

APIClientSchema.set('toObject', {
  transform: (doc, ret, options) ->
    delete ret.secret
    return ret
})

module.exports = APIClient = mongoose.model('APIClient', APIClientSchema, 'api.clients')
