const c = require('./../schemas')

const LicenseRequestSchema = c.object({
  title: 'License request',
  required: ['requesterEmail', 'requestedLicenses', 'createdOn']
})

_.extend(LicenseRequestSchema.properties, {
  trialRequest: c.objectId({ links: [{ rel: 'extra', href: '/db/trial.request/{($)}' }] }),
  created: c.date(),
  createdOn: { type: 'string', enum: ['CodeCombat', 'Ozaria'] },
  requestedLicenses: c.int(),
  requester: c.objectId({ links: [{ rel: 'extra', href: '/db/user/{($)}' }] }),
  requesterEmail: c.shortString({ title: 'From email', format: 'email' }),
  receiverEmail: c.shortString({ title: 'To email', format: 'email' }),
  message: { type: 'string', maxLength: 2000 },
  phone: c.shortString({ title: 'Phone number' }),
  district: c.shortString({ title: 'District' }),
  role: c.shortString({ title: 'Teacher, principal etc' }),
  school: c.shortString({ title: 'School' }),
  status: { type: 'string', enum: ['CREATED', 'SLACK_SENT', 'FAILED', 'PROCESSING'] },
})

c.extendBasicProperties(LicenseRequestSchema, 'LicenseRequest')

module.exports = LicenseRequestSchema
