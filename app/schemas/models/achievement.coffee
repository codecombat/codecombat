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
      proportionalTo:
        type: 'string'
        description: 'For repeatables only. Denotes the field a repeatable achievement needs for its calculations'
      ratio:
        type: 'integer'
        description: 'For repeatables only. Denotes how many proportionalTo\'s trigger an achievement. Usually 1.'
        minimum: 1
    required: ['name', 'query', 'worth', 'collection']

  EarnedAchievementSchema :
    type: 'object'
    properties:
      user: c.objectId
        links:
          [
            {
              rel: 'extra'
              href: "/db/user/{($)}"
            }
          ]
      achievement: c.objectId
        links:
          [
            {
              rel: 'extra'
              href: '/db/user/{($)}'
            }
          ]
      achievedAmount:
        type: 'number'

  MongoFindQuerySchema :
    title: 'MongoDB Query'
    id: 'mongoFindQuery'
    type: 'object'
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
    type: 'object'
    properties:
      '$gt': type: 'number'
      '$gte': type: 'number'
      '$in': type: 'array'
      '$lt': type: 'number'
      '$lte': type: 'number'
      '$ne': type: [ 'number', 'string' ]
      '$nin': type: 'array'
    additionalProperties: true # TODO set to false when the schema's done