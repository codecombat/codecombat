c = require './../schemas'

# TODO add these: http://docs.mongodb.org/manual/reference/operator/query/
MongoQueryOperatorSchema =
  title: 'Query Operator'
  type: 'object'
  properties:
    '$gt': type: 'number'
    '$gte': type: 'number'
    '$in': type: 'array'
    '$lt': type: 'number'
    '$lte': type: 'number'
    '$ne': type: ['number', 'string']
    '$nin': type: 'array'
    '$exists': type: 'boolean'
  additionalProperties: false

MongoFindQuerySchema =
  title: 'Query'
  type: 'object'
  patternProperties:
    '^[-a-zA-Z0-9._]*$':
      anyOf: [
        {$ref: '#/definitions/mongoQueryOperator'},
        {type: 'string'}
        {type: 'object'}
        {type: 'boolean'}
      ]
  properties: {}
  additionalProperties: false
  definitions: {}

AchievementSchema = c.object()
c.extendNamedProperties AchievementSchema
c.extendBasicProperties AchievementSchema, 'achievement'
c.extendSearchableProperties AchievementSchema

AchievementSchema.default =
  worth: 10
  description: 'Probably the coolest you\'ll ever get.'
  difficulty: 1
  recalculable: true
  function: {}

_.extend AchievementSchema.properties,
  query:
    #type:'object'
    $ref: '#/definitions/mongoFindQuery'
  worth: c.float()
  collection: {type: 'string'}
  description: c.shortString()
  userField: c.shortString()
  related: c.objectId(description: 'Related entity')
  icon: {type: 'string', format: 'image-file', title: 'Icon', description: 'Image should be a 100x100 transparent png.'}
  category:
    enum: ['level', 'ladder', 'contributor']
    description: 'For categorizing and display purposes'
  difficulty: c.int
    description: 'The higher the more difficult'
  proportionalTo:
    type: 'string'
    description: 'For repeatables only. Denotes the field a repeatable achievement needs for its calculations'
  recalculable:
    type: 'boolean'
    description: 'Deprecated: all achievements must be recalculable now. Used to need to be set to true before it is eligible for recalculation.'
  function:
    type: 'object'
    description: 'Function that gives total experience for X amount achieved'
    properties:
      kind: {enum: ['linear', 'logarithmic', 'quadratic', 'pow'] }
      parameters:
        type: 'object'
        default: { a: 1, b: 0, c: 0 }
        properties:
          a: {type: 'number' }
          b: {type: 'number' }
          c: {type: 'number' }
        additionalProperties: true
    default: {kind: 'linear', parameters: {}}
    required: ['kind', 'parameters']
    additionalProperties: false
  i18n: {type: 'object', format: 'i18n', props: ['name', 'description'], description: 'Help translate this achievement'}
  rewards: c.RewardSchema 'awarded by this achievement'
  hidden: {type: 'boolean', description: 'Hide achievement from user if true'}
  updated: c.stringDate({ description: 'When the achievement was changed in such a way that earned achievements should get updated.' })


_.extend AchievementSchema, # Let's have these on the bottom
  # TODO We really need some required properties in my opinion but this makes creating new achievements impossible as it is now
  #required: ['name', 'description', 'query', 'worth', 'collection', 'userField', 'category', 'difficulty']
  additionalProperties: false

AchievementSchema.definitions = {}
AchievementSchema.definitions['mongoQueryOperator'] = MongoQueryOperatorSchema
AchievementSchema.definitions['mongoFindQuery'] = MongoFindQuerySchema
c.extendTranslationCoverageProperties AchievementSchema
c.extendPatchableProperties AchievementSchema

module.exports = AchievementSchema
