const schema = require('./../schemas')

const ConceptSchema = schema.object(  {
  description:
    'A Computer Science Concepts like while loops, or nested if statements.',
  title: 'Concept',
  required: ['name']
})
_.extend(ConceptSchema.properties,{
    levelsCount: {
      type: 'integer',
      title: 'Levels Count',
      description: 'The number of levels that use this concept',
    },
    coursesCount: {
      type: 'integer',
      title: 'Courses Count',
      description: 'The number of courses that use this concept',
    },  
    key: {
      type: 'string',
      title: 'Key',
      description: 'The unique key of this concept',
    },      
    tagger: {
      type: 'string',
      title: 'Tagger',
      description: 'A AST node string that automatically tags this concept'
    },

    taggerFunction: {
      type: 'string',
      title: 'Tagger Function',
      description: 'A AST parsing function that automatically tags this concept',
      format: 'code'
    },

    automatic: {
      title: 'Automatic',
      type: 'boolean',
      description: 'Whether this concept is can be automatically determined in the level'
    },

    deprecated: {
      title: 'Deprecated',
      type: 'boolean',
      description: 'Whether this concept is deprecated'
    },

    i18n: {
      type: 'object',
      format: 'i18n',
      props: ['name', 'description']
    },

    description: {
      type: 'string',
      title: 'Description',
      description: 'Optional: extra context or explanation',
      format: 'markdown'
    }
  }
)

schema.extendBasicProperties(
  ConceptSchema,
  'concept'
)

schema.extendNamedProperties(ConceptSchema)
schema.extendTranslationCoverageProperties(ConceptSchema)
schema.extendPatchableProperties(ConceptSchema)
schema.extendSearchableProperties(ConceptSchema)

module.exports = ConceptSchema
