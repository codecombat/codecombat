c = require './../schemas'

# TODO add these: http://docs.mongodb.org/manual/reference/operator/query/
MongoQueryOperatorSchema =
  title: 'MongoDB Query operator'
  id: 'mongoQueryOperator'
  type: 'object'
  properties:
    '$gt': type: 'number'
    '$gte': type: 'number'
    '$in': type: 'array'
    '$lt': type: 'number'
    '$lte': type: 'number'
    '$ne': type: ['number', 'string']
    '$nin': type: 'array'
  additionalProperties: true # TODO set to false when the schema's done

MongoFindQuerySchema =
  title: 'MongoDB Query'
  id: 'mongoFindQuery'
  type: 'object'
  patternProperties:
    #'^[-a-zA-Z0-9_]*$':
    '^[-a-zA-Z0-9\.]*$':
      oneOf: [
        #{$ref: '#/definitions/' + MongoQueryOperatorSchema.id},
        {type: 'string'}
        {type: 'object'}
        {type: 'boolean'}
      ]
  additionalProperties: true # TODO make Treema accept new pattern matched keys
  definitions: {}

MongoFindQuerySchema.definitions[MongoQueryOperatorSchema.id] = MongoQueryOperatorSchema

AchievementSchema = c.object()
c.extendNamedProperties AchievementSchema
c.extendBasicProperties AchievementSchema, 'achievement'
c.extendSearchableProperties AchievementSchema

_.extend AchievementSchema.properties,
  query:
    #type:'object'
    $ref: '#/definitions/' + MongoFindQuerySchema.id
  worth: c.float
    default: 10
  collection: {type: 'string'}
  description: c.shortString
    default: 'Probably the coolest you\'ll ever get.'
  userField: c.shortString()
  related: c.objectId(description: 'Related entity')
  icon: {type: 'string', format: 'image-file', title: 'Icon', description: 'Image should be a 100x100 transparent png.'}
  category:
    enum: ['level', 'ladder', 'contributor']
    description: 'For categorizing and display purposes'
  difficulty: c.int
    description: 'The higher the more difficult'
    default: 1
  proportionalTo:
    type: 'string'
    description: 'For repeatables only. Denotes the field a repeatable achievement needs for its calculations'
  recalculable:
    type: 'boolean'
    description: 'Needs to be set to true before it is elligible for recalculation.'
    default: true
  function:
    type: 'object'
    description: 'Function that gives total experience for X amount achieved'
    properties:
      kind: {enum: ['linear', 'logarithmic', 'quadratic'], default: 'linear'}
      parameters:
        type: 'object'
        properties:
          a: {type: 'number', default: 1}
          b: {type: 'number', default: 1}
          c: {type: 'number', default: 1}
        additionalProperties: true
    default: {kind: 'linear', parameters: a: 1}
    required: ['kind', 'parameters']
    additionalProperties: false
  i18n: c.object
    format: 'i18n'
    props: ['name', 'description']
    description: 'Help translate this achievement'

_.extend AchievementSchema, # Let's have these on the bottom
  # TODO We really need some required properties in my opinion but this makes creating new achievements impossible as it is now
  #required: ['name', 'description', 'query', 'worth', 'collection', 'userField', 'category', 'difficulty']
  additionalProperties: false

AchievementSchema.definitions = {}
AchievementSchema.definitions[MongoFindQuerySchema.id] = MongoFindQuerySchema

module.exports = AchievementSchema
