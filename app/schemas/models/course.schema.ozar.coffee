c = require './../schemas'

CourseSchema = c.object {title: 'Course', required: ['name']}
c.extendNamedProperties CourseSchema  # name first

_.extend CourseSchema.properties,
  i18n: {type: 'object', title: 'i18n', format: 'i18n', props: ['name', 'description' ]}
  campaignID: c.objectId()
  concepts: c.array {title: 'Programming Concepts', uniqueItems: true}, c.concept
  description: {type: 'string'}
  # duration: {type: 'number', description: 'Approximate hours of content'} # deprecated
  duration: { type: 'object', title: 'Course duration', properties: {
    total: { type: 'string', title: 'Total time' }
    inGame: { type: 'string', title: 'In-game time' }
    unplugged: { type: 'string', title: 'Unplugged Activites time' }
  }}
  pricePerSeat: {type: 'number', description: 'Price per seat in USD cents.'} # deprecated
  free: { type: 'boolean' }
  # screenshot: c.path { title: 'URL', description: 'Link to course screenshot.'} # deprecated
  screenshot: { type: 'string', format: 'image-file', title: 'Thumbnail image', description: 'Relevant for teacher dashboard' }
  adminOnly: { type: 'boolean', description: 'Deprecated in favor of releasePhase.' }
  releasePhase: { enum: ['beta', 'internalRelease', 'released'], description: "How far along the course's development is, determining who sees it." }
  isOzaria: { type: 'boolean', description: 'Is this an ozaria course' } # not used
  shortName: { type: 'string', title: 'Short Name', description: 'Short name to be used on dashboards' }
  cstaStandards: c.array {title: 'CSTA standards'}, {
    type: 'object', title: 'CSTA standard', properties: {
      name: { type: 'string', title: 'Name' }
      description: { type: 'string', title: 'Description' }
    }
  }
  modules: { title: 'Modules', type: "object", description: "Module information to be shown on the curriculum guide. Please use module number as key field.", additionalProperties:
    { type: 'object', title: 'Module', description: 'Relevant for information displayed on curriculum guides in teacher dashboard for each module', properties: {
      number: { type: 'number', title: 'Module number' }
      duration: { type: 'object', title: 'Module duration', properties: {
        total: { type: 'string', title: 'Total time' }
        inGame: { type: 'string', title: 'In-game time' }
        unplugged: { type: 'string', title: 'Unplugged Activites time' }
      }}
      lessonSlidesUrl: c.url { title: 'Lesson Slides URL' }
      exemplarProjectUrl: c.url { title: 'Exemplar Project URL', description: 'Only relevant for capstone module' }
      exemplarCodeUrl: c.url { title: 'Exemplar Code URL', description: 'Only relevant for capstone module' }
      projectRubricUrl: c.url { title: 'Project Rubric URL', description: 'Only relevant for capstone module' }
    }} # TODO move module name from utils.coffee to schema
  }

c.extendBasicProperties CourseSchema, 'Course'
c.extendTranslationCoverageProperties CourseSchema
c.extendPatchableProperties CourseSchema
c.extendAlgoliaProperties CourseSchema

module.exports = CourseSchema
