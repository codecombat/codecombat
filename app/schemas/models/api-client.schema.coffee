c = require './../schemas'
{FeatureAuthoritySchema} = require './feature.schema'

APIClientSchema = {
  description: 'Third parties who can make API calls, usually on behalf of a user.'
  type: 'object'
  properties: {
    creator: {
      type: 'object',
      description: 'Id of user who created this APIClient'
    }
    secret: {
      type: 'string'
      description: 'hashed version of a secret key that is required for API calls'
    }
    features:
      type: 'object'
      description: 'Feature flags applied to associated users'
      # key is the feature id
      additionalProperties: FeatureAuthoritySchema
  }
}

c.extendBasicProperties APIClientSchema, 'Client'
c.extendNamedProperties APIClientSchema

module.exports = APIClientSchema
