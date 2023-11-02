c = require './../schemas'

OAuthProviderSchema = {
  description: 'A service which provides OAuth identification, login for our users.'
  type: 'object'
  properties: {
    creator: {
      type: 'object',
      description: 'Id of user who created this OAuthProvider'
    }
    lookupUrlTemplate: {
      type: 'string'
      description: '
        A template of the URL for the user resource. Should include "<%= accessToken %>" for string interpolation.'
    }
    lookupIdProperty: { 
      type: 'string', 
      description: 'What property in the response from lookupUrlTemplate to use as the user id. Defaults to "id".' 
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
    tokenMethod: { enum: ['get', 'post']}
    authorizeUrl: { type: 'string' }
    clientID: { type: 'string' }
    strictSSL: { type: 'boolean' }
    redirectAfterLogin: { type: 'string' }
  }
}

c.extendBasicProperties OAuthProviderSchema, 'OAuthProvider'
c.extendNamedProperties OAuthProviderSchema

module.exports = OAuthProviderSchema
