c = require './../schemas'

module.exports =
  AchievementSchema :
    type: 'object'
    properties:
      name: c.shortString({title: 'Display Name'})
      query: { $ref: 'mongoFindQuery' } # TODO make this happen
      worth:
        type: 'number'
      collection:
        type: 'string'
      measurableField:
        type: 'string'
        description: 'This field denotes the field a repeatable achievement needs for its calculations'
    required: ['name', 'query', 'worth', 'collection']

  EarnedAchievementSchema :
    type: 'object'
    properties:
      # TODO ref to user
      # TODO ref to original achievement
      achieved:
        type: 'number'

  MongoFindQuerySchema :
    title: 'MongoDB Query'
    id: 'mongoFindQuery'
    type: object
    patternProperties:
      '^[a-zA-Z0-9_\-\$]*$':
        type: [ 'string', 'object' ]
        oneOf: [
          { $ref: 'mongoQueryOperator' }, # TODO make this happen
          { type: 'string' }
        ]
    additionalProperties: false

  # TODO add these: http://docs.mongodb.org/manual/reference/operator/query/
  MongoQueryOperatorSchema :
    title: 'MongoDB Query operator'
    id: 'mongoQueryOperator'
    type: object
    properties:
      '$gt': type: 'number'
      '$gte': type: 'number'
      '$in': type: 'array'
      '$lt': type: 'number'
      '$lte': type: 'number'
      '$ne': type: [ 'number', 'string' ]
      '$nin': type: 'array'
    additionalProperties: true # TODO set to false when the schema's done