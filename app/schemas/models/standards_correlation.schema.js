const schema = require('./../schemas')

const StandardsCorrelation = schema.object(
  {
    description:
      '',
    title: 'Standards Correlation',
  },
  {

  }
)

schema.extendBasicProperties(
  StandardsCorrelation,
  'standards_correlation'
)

schema.extendNamedProperties(StandardsCorrelation)
schema.extendTranslationCoverageProperties(StandardsCorrelation)
schema.extendPatchableProperties(StandardsCorrelation)
schema.extendSearchableProperties(StandardsCorrelation)

module.exports = StandardsCorrelation
