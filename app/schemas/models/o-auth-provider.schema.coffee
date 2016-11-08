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
    authorizeUrl: { type: 'string' }
    clientID: { type: 'string' }
  }
}

c.extendBasicProperties OAuthProviderSchema, 'OAuthProvider'
c.extendNamedProperties OAuthProviderSchema

module.exports = OAuthProviderSchema
