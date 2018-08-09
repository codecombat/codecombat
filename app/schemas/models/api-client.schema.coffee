c = require './../schemas'

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
    description: 'Feature flags applied to users created by this APIClient'
    # key is the feature id
    additionalProperties: c.object({}, {
      enabled: {type: 'boolean', description: 'Whether to apply feature flag', default: false}
      updated: c.date()
    })
  }
}

c.extendBasicProperties APIClientSchema, 'Client'
c.extendNamedProperties APIClientSchema

module.exports = APIClientSchema
