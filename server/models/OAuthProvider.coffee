mongoose = require 'mongoose'
plugins = require '../plugins/plugins'
log = require 'winston'
config = require '../../server_config'
jsonSchema = require '../../app/schemas/models/o-auth-provider.schema.coffee'
co = require 'co'
request = require('request')
errors = require '../commons/errors'
Promise = require 'bluebird'

requestAsync = Promise.promisify(request)

OAuthProviderSchema = new mongoose.Schema(body: String, {strict: false,read:config.mongo.readpref})

OAuthProviderSchema.statics.jsonSchema = jsonSchema
OAuthProviderSchema.statics.editableProperties = [
  'name'
]

OAuthProviderSchema.plugin(plugins.NamedPlugin)

OAuthProviderSchema.methods.lookupAccessToken = co.wrap (accessToken) ->
  url = _.template(@get('lookupUrlTemplate'))({accessToken})
  [res, body] = yield request.getAsync({url, json: true})
  if res.statusCode >= 400
    return null
  return body
  
OAuthProviderSchema.methods.getTokenWithCode = co.wrap (code) ->
  url = @get('tokenUrl')
  if not url
    throw new errors.InternalServerError('OAuthProvider does not have a "tokenUrl" set.')
  json = {
    grant_type: 'authorization_code'
    code
    client_id: @get('clientID')
  }

  options = {url, json}
  tokenAuth = @get('tokenAuth')
  options.auth = tokenAuth if tokenAuth
  options.method = if @get('tokenMethod') is 'post' then 'POST' else 'GET'
  
  res = yield requestAsync(options)
  if res.statusCode >= 400
    return null
  return res.body

module.exports = OAuthProvider = mongoose.model('OAuthProvider', OAuthProviderSchema, 'o.auth.providers')
