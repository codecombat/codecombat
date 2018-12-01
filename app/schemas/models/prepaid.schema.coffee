c = require './../schemas'

PrepaidSchema = c.object({title: 'Prepaid', required: ['type']}, {
  creator: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
  clientCreator: c.objectId(links: [ {rel: 'extra', href: '/db/api-clients/{($)}'} ])
  redeemers: c.array {title: 'Users who have redeemed this code'},
    c.object {required: ['date', 'userID']},
      date: c.date {title: 'Redeemed date'}
      userID: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
      teacherID: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ],
        description: 'userID of teacher that applied the license, if not the creator')
  maxRedeemers: { type: 'integer' }
  code: c.shortString(title: "Unique code to redeem")
  type: { type: 'string' }
  properties: { type: 'object' }
  exhausted: { type: 'boolean' }
  startDate: c.stringDate()
  vendorPurchased: c.object {},
    gems: {type: 'number', description: 'Overwrites the number of gems given by Product when the prepaid is redeemed'}
    expires: c.stringDate({description: 'Date the prepaid expires and cannot be redeemed'})
  endDate: c.stringDate()
  includedCourseIDs: c.array({ description: 'courseIDs that this prepaid includes access to' }, c.objectId())
  joiners: c.array {title: 'Teachers this Prepaid is shared with'},
    c.object {required: ['userID']},
      userID: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
})

c.extendBasicProperties(PrepaidSchema, 'prepaid')

module.exports = PrepaidSchema
