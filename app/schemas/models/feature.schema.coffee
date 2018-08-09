c = require './../schemas'

FeatureSchema = c.object {
    title: 'Feature Flag'
    required: ['name', 'type']
  },
  {
    name: c.shortString({title: 'Name'})
    type: c.shortString(title: 'Type', description: 'Intended type of the flag.', enum: ['global', 'user'])
    enabled: {type: 'boolean', description: 'Whether to apply feature flag', default: false}
  }

c.extendBasicProperties(FeatureSchema, 'feature')

module.exports = FeatureSchema
