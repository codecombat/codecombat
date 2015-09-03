c = require './../schemas'

CourseSchema = c.object {title: 'Course', required: ['name']}
c.extendNamedProperties CourseSchema  # name first

_.extend CourseSchema.properties,
  campaignID: c.objectId()
  concepts: c.array {title: 'Programming Concepts', uniqueItems: true}, c.concept
  description: {type: 'string'}
  pricePerSeat: {type: 'number', description: 'Price per seat in USD cents.'}
  screenshot: c.url {title: 'URL', description: 'Link to course screenshot.'}

c.extendBasicProperties CourseSchema, 'Course'

module.exports = CourseSchema
