const schema = require('./../schemas')
const utils = require('../../core/utils')

const ResourceHubResourceSchema = schema.object(
  {
    description:
      'Dynamic resource store for the teacher dashboard resource hub',
    title: 'ResourceHub Resource',
    required: ['name']
  },
  {
    icon: schema.shortString({
      title: 'Icon',
      description: 'Chooses icon to display by resource',
      enum: schema.resourceIcons
    }),

    section: schema.shortString({
      title: 'Section',
      description: 'Declares which section the resource will appear in.',
      enum: ['gettingStarted', 'educatorResources', 'lessonSlides', 'studentResources']
    }),

    link: {
      type: 'string',
      title: 'Link',
      description: 'Navigation when resource is selected',
      maxLength: 500
    },

    i18n: {
      type: 'object',
      format: 'i18n',
      props: ['name', 'link', 'description']
    },

    hidden: {
      title: 'Hidden',
      description: 'This can be set to hide the resource, or to hide it for unpaid users.',
      type: ['string', 'boolean'],
      enum: [true, false, 'paid-only']
    },

    priority: {
      title: 'Priority',
      description: 'Lower numbers will show earlier.',
      type: 'integer'
    },

    description: {
      type: 'string',
      title: 'Description',
      description: 'Optional: extra context or explanation',
      format: 'markdown'
    },

    product: schema.product,

    courses: {
      title: 'Courses',
      description: 'The Courses that this resource is relevant for, if it is a course-specific resource',
      type: 'array',
      format: 'courses',
      items: schema.shortString({
        format: 'course',
        enum: Object.values(utils.courseIDs).map(c => utils.courseAcronyms[c])
      })
    },

    roles: {
      title: 'Roles',
      description: 'List of roles that can have access to this resource. If set, then only those roles have access otherwise all do',
      type: 'array',
      items: {
        type: 'string',
        enum: ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent', 'parent-home', 'possible teacher']
      }
    }
  }
)

schema.extendBasicProperties(
  ResourceHubResourceSchema,
  'resource_hub_resource'
)

schema.extendNamedProperties(ResourceHubResourceSchema)
schema.extendTranslationCoverageProperties(ResourceHubResourceSchema)
schema.extendPatchableProperties(ResourceHubResourceSchema)
schema.extendSearchableProperties(ResourceHubResourceSchema)

module.exports = ResourceHubResourceSchema
