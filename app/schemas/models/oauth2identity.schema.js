const schema = require('./../schemas')

const OAuth2IdentitySchema = schema.object({
  description: 'An OAuth2 Identity',
  title: 'OAuth2 Identity',
  required: ['provider']
})
_.extend(OAuth2IdentitySchema.properties, {
  provider: { type: 'string' },
  ownerID: schema.objectId(),
  token: {
    description: 'A single OAuth identity',
    type: 'object',
    properties: {
      access_token: { type: 'string', description: 'The access token for the user' },
      refresh_token: { type: 'string', description: 'The refresh token for the user' },
      token_type: { type: 'string', description: 'The type of token' },
      expires_in: { type: 'integer', description: 'The number of seconds until the token expires' },
      id_token: { type: 'string', description: 'The id token for the user' },
      scope: { type: 'string', description: 'The scope of the token' },
      expires_at: { type: schema.date(), description: 'The time at which the token expires' },
    }
  },
  profile: {type: 'object', description: 'The profile info of the user on the OAuth2 provider'},
})

schema.extendBasicProperties(OAuth2IdentitySchema,'oauth2identity',)

module.exports = OAuth2IdentitySchema
