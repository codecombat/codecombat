// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const c = require('./../schemas')

const FeatureSchema = {
  type: 'object',
  title: 'Feature Flag',
  required: ['name', 'type'],
  properties: {
    name: c.shortString({ title: 'Name' }),
    type: c.shortString({ title: 'Type', description: 'Intended type of the flag.', enum: ['global', 'user'] }),
    enabled: { type: 'boolean', description: 'Whether to apply feature flag', default: false }
  }
}

c.extendBasicProperties(FeatureSchema, 'feature')

const FeatureAuthoritySchema = {
  type: 'object',
  required: ['enabled', 'updated'],
  properties: {
    enabled: { type: 'boolean', description: 'Whether to apply feature flag', default: false },
    updated: c.date()
  }
}

const FeatureRecipientSchema = _.merge(_.cloneDeep(FeatureSchema), {
  type: 'object',
  required: ['authorityID', 'authorityType', 'updated'],
  properties: {
    authorityID: c.objectId({ description: 'Feature setting authority' }),
    authorityType: c.shortString({ title: 'Type', description: 'Authority type settings by', enum: ['api-client'] }),
    updated: c.date()
  }
}
)

module.exports = { FeatureSchema, FeatureAuthoritySchema, FeatureRecipientSchema }
