c = require './../schemas'

PrepaidSchema = c.object({title: 'Prepaid', required: ['type']}, {
  creator: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
  clientCreator: c.objectId(links: [ {rel: 'extra', href: '/db/api-clients/{($)}'} ])
  redeemers: c.array {title: 'Users who have redeemed this code'},
    c.object {required: ['date']},
      date: c.date {title: 'Redeemed date'}
      code: c.shortString(title: 'activation code', description: 'use for both student-activation and teacher-activation')
      userID: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
      teacherID: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ],
        description: 'userID of teacher that applied the license, if not the creator')
      startDate: c.stringDate(description: 'the startDate of teacher-activation code, means when a teacher join this license by this code, so his current License start from this date.')
  maxRedeemers: { type: 'integer' }
  removedRedeemers: c.array {title: 'Users who once redeemed this code', description: 'only record the last revoke event. if redeem/revoke multiple times, ref the user.products for details'},
    c.object {required: []},
      userID: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
      startDate: c.stringDate(description: 'the last redeemed date of this user')
      endDate: c.stringDate(description: 'the last end date of this user')
      teacherID: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ],
        description: 'userID of teacher that revoke the license, if not the creator')
  code: c.shortString(title: "Unique code to redeem")
  type: { type: 'string' }
  properties: c.object { additionalProperties: true },
    activatedByTeacher: { type: 'boolean', description: 'if this Prepaid used for teacher-activation code.'}
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
      redeemers: {type: 'integer', description: 'how many students does this joiner already redeem'}
      maxRedeemers: { type: 'integer', description: 'the max number of students that this joiner can redeem from this Prepaid. if unset, then unlimited.'}
  removedJoiners: c.array {title: 'Teachers this Prepaid was shared with'},
    c.object {required: ['userID']},
      userID: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
})

c.extendBasicProperties(PrepaidSchema, 'prepaid')

module.exports = PrepaidSchema
