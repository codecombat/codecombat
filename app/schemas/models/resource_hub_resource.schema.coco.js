const schema = require('./../schemas')

const ResourceHubResourceSchema = schema.object(
  {
    description:
      'Dynamic resource store for the teacher dashboard resource hub',
    title: 'ResourceHub Resource'
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
      enum: ['gettingStarted', 'educatorResources']
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
      props: ['name', 'link'],
      description: 'This cutscene translation required srt files.'
    },

    hidden: {
      title: 'Hidden',
      description: 'This can be set to hide the resource.',
      type: 'boolean'
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

module.exports = ResourceHubResourceSchema
