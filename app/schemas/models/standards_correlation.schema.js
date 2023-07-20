const c = require('./../schemas')

const StandardsCorrelation = c.object(
  {
    description: '',
    title: 'Standards Correlation',
    required: ['name']
  },
  {
    subject: c.shortString({
      title: 'Subject',
      type: 'string',
      enum: ['computer-science', 'literacy', 'math', 'science']
    }),
    district: c.objectId({
      links: [{ rel: 'extra', href: '/db/district/{($)}' }],
      title: 'District ID',
      description: 'The ID of the district that this correlation belongs to'
    }),
    administrativeRegion: c.shortString({
      title: 'Administrative Region',
    }),
    country: c.shortString({
      title: 'Country',
    }),
    gradeLevels: {
      title: 'Grade Levels',
      type: "object",
      additionalProperties: {
        type: 'object',
        properties: {
          sections: c.array({
            title: 'Sections',
          }, {
            type: 'object',
            properties: {
              name: c.shortString({
                title: 'Name'
              }),
              description: c.shortString({
                type: 'string',
                title: 'Description'
              }),
              standards: c.array({ title: 'Standards' }, {
                type: 'object',
                properties: {
                  identifier: c.shortString({ title: 'Identifier' }),
                  standard: { type: 'string', title: 'Standard', format: 'markdown' },
                  i18n: {
                    additionalProperties: true,
                    type: 'object',
                    format: 'i18n',
                    props: ['standard'],
                    description: 'Translations for the standard'
                  },
                  concepts: c.array({ title: 'Programming Concepts', uniqueItems: true, format: 'concepts-list' }, c.concept)
                }
              })
            }
          }),
        }
      }
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

c.extendBasicProperties(
  StandardsCorrelation,
  'standards_correlation'
)

c.extendNamedProperties(StandardsCorrelation)
c.extendTranslationCoverageProperties(StandardsCorrelation)
c.extendPatchableProperties(StandardsCorrelation)
c.extendSearchableProperties(StandardsCorrelation)

module.exports = StandardsCorrelation
