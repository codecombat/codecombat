c = require './../schemas'

CourseSchema = c.object {title: 'Course', required: ['name']}
c.extendNamedProperties CourseSchema  # name first

_.extend CourseSchema.properties,
  i18n: {type: 'object', title: 'i18n', format: 'i18n', props: ['name', 'description' ]}
  campaignID: c.objectId()
  concepts: c.array {title: 'Programming Concepts', uniqueItems: true}, c.concept
  description: {type: 'string'}
  duration: oneOf: [
    { type: 'object', title: 'Course duration', properties: {
      total: { type: 'string', title: 'Total class time (overall)' }
      inGame: { type: 'string', title: 'In-game time' }
      totalTimeRange: { type: 'string', title: 'Total class time (range)', description: 'Relevant for curriculum guides hover tooltip' }
      i18n: {type: 'object', title: 'i18n', format: 'i18n', props: [
        'total', 'inGame', 'totalTimeRange'
      ]}
    }},
    {type: 'number', description: 'Approximate hours of content'}  # deprecated
  ]
  pricePerSeat: {type: 'number', description: 'Price per seat in USD cents.'} # deprecated
  free: { type: 'boolean' }
  screenshot: oneOf: [
    { type: 'string', format: 'image-file', title: 'Thumbnail image', description: 'Relevant for teacher dashboard' }
    c.path { title: 'URL', description: 'Link to course screenshot.'} # deprecated
  ]
  adminOnly: { type: 'boolean', description: 'Deprecated in favor of releasePhase.' }
  releasePhase: { enum: ['beta', 'internalRelease', 'released'], description: "How far along the course's development is, determining who sees it." }
  isOzaria: { type: 'boolean', description: 'Is this an ozaria course' } # not used
  shortName: { type: 'string', title: 'Short Name', description: 'Short name to be used on dashboards' }
  cstaStandards: c.array {title: 'CSTA standards', description: 'Sample CSTA standards list for display on teacher dashboard curriculum guides'}, {
    type: 'object', title: 'CSTA standard', properties: {
      name: { type: 'string', title: 'Name' }
      description: { type: 'string', title: 'Description' }
      i18n: {type: 'object', title: 'i18n', format: 'i18n', props: [
        'name', 'description'
      ]}
    }
  }
  modules: { title: 'Modules', type: "object", description: "Module information to be shown on the curriculum guide. Please use module number as key field.", additionalProperties:
    { type: 'object', title: 'Module', description: 'Relevant for information displayed on curriculum guides in teacher dashboard for each module', properties: {
      number: { type: 'number', title: 'Module number' }
      duration: { type: 'object', title: 'Module duration', properties: {
        total: { type: 'string', title: 'Total class time (overall)' }
        inGame: { type: 'string', title: 'In-game time' }
        totalTimeRange: { type: 'string', title: 'Total class time (range)', description: 'Relevant for curriculum guides hover tooltip'}
      }}
      lessonSlidesUrl: c.url { title: 'Lesson Slides URL' }
    }} # TODO move module name from utils.coffee to schema
  }

c.extendBasicProperties CourseSchema, 'Course'
c.extendTranslationCoverageProperties CourseSchema
c.extendPatchableProperties CourseSchema
c.extendSearchableProperties CourseSchema

module.exports = CourseSchema
