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
    permissions: {
      type: 'object'
      description: 'permissions assigned to the API client'
      properties: {
        manageLicensesViaUI: { type: 'boolean', default: false}
        manageLicensesViaAPI: { type: 'boolean', default: true}
        revokeLicensesViaUI: { type: 'boolean', default: false}
        revokeLicensesViaAPI : { type: 'boolean', default: false}
        manageSubscriptionViaAPI : { type: 'boolean', default: false}
        revokeSubscriptionViaAPI : { type: 'boolean', default: false}
      }
    }
    minimumLicenseDays : {
      type: 'integer'
      default: 365
    }
    licenseDaysGranted: {
      type: 'integer'
      description: 'The APIClient can grant licenses to its users for this number of days'
      default: 0
    },
    autoClanOwner: c.objectId { description: 'owner (user) of APIClient auto clan' }
    accessPermissions: c.array { description: 'list users who have the access permission to the api-client-auto-clan'}, {
      type: 'object',
      properties: {
        target: c.objectId(), access: {type: 'string', enum: ['read', 'write']}
      }
    }
  }
}

c.extendBasicProperties APIClientSchema, 'Client'
c.extendNamedProperties APIClientSchema

module.exports = APIClientSchema
