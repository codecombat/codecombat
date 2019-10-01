c = require './../schemas'

TrialRequestSchema = c.object {
  title: 'Trial request',
  required: ['type']
}

_.extend TrialRequestSchema.properties,
  applicant: c.objectId(links: [{rel: 'extra', href: '/db/user/{($)}'}])
  created: c.date()
  prepaidCode: c.objectId()
  reviewDate: c.date({readOnly: true})
  reviewer: c.objectId(links: [{rel: 'extra', href: '/db/user/{($)}'}])
  properties: {type: 'object', description: 'Data specific to this request.'}
  status: {type: 'string', 'enum': ['submitted', 'approved', 'denied']}
  type: {type: 'string', 'enum': ['course', 'subscription']}

c.extendBasicProperties TrialRequestSchema, 'TrialRequest'
module.exports = TrialRequestSchema
