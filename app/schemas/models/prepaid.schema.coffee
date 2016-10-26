c = require './../schemas'

PrepaidSchema = c.object({title: 'Prepaid', required: ['type']}, {
  creator: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
  clientCreator: c.objectId(links: [ {rel: 'extra', href: '/db/api-clients/{($)}'} ])
  redeemers: c.array {title: 'Users who have redeemed this code'},
    c.object {required: ['date', 'userID']},
      date: c.date {title: 'Redeemed date'}
      userID: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
  maxRedeemers: { type: 'integer' }
  code: c.shortString(title: "Unique code to redeem")
  type: { type: 'string' }
  properties: {type: 'object' }
  exhausted: { type: 'boolean' }
  startDate: c.stringDate()
  endDate: c.stringDate()
  includedCourseIDs: c.array({ description: 'courseIDs that this prepaid includes access to' }, c.objectId())
})

c.extendBasicProperties(PrepaidSchema, 'prepaid')

module.exports = PrepaidSchema
