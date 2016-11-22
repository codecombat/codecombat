c = require './../schemas'

OAuthProviderSchema = {
  description: 'A service which provides OAuth identification, login for our users.'
  type: 'object'
  properties: {
    lookupUrlTemplate: {
      type: 'string'
      description: '
        A template of the URL for the user resource. Should include "<%= accessToken %>" for string interpolation.'
    }
    tokenUrl: { type: 'string' }
    tokenAuth: {
      type: 'object'
      description: '"auth" argument for requests (see https://github.com/request/request#http-authentication)'
      properties: {
        user: { type: 'string' }
        pass: { type: 'string' }
        sendImmediately: { type: 'boolean' }
      }
    }
    authorizeUrl: { type: 'string' }
    clientID: { type: 'string' }
  }
}

c.extendBasicProperties OAuthProviderSchema, 'OAuthProvider'
c.extendNamedProperties OAuthProviderSchema

module.exports = OAuthProviderSchema
