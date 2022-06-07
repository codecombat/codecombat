c = require './../schemas'


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


AnnouncementSchema = c.object
  title: 'Announcement'
  description: ''
  required: ['', 'title']
  default:
    kind: 'normal'

c.extendNamedProperties AnnouncementSchema

_.extend AnnouncementSchema.properties,
  description:
    type: 'string'
  created: c.date
    title: 'Created'
    readOnly: true
  title:
    type: 'string'
  content:
    type: 'string'
  startDate: c.stringDate()
  endDate: c.stringDate() #unset for forever
  query:
    $ref: '#/definitions/mongoFindQuery'
  product:
    type: 'string'
    enum: ['ozaria', 'codecombat', 'both']
  kind:
    type: 'string'
    enum: ['normal', 'sequence', 'banner']
    description: 'normal: normal announcements; banner: show anyway during live dates on homeview ; sequence: requires step to determine when to show'
  sequence:
    prevStep:
      type: 'number'
    prevTime:
      type: 'number'
      description: 'how many hours required after read prev announcement'
    step:
      type: 'number'
      description: 'announcement publish step'

AnnouncementSchema.definitions = {}
AnnouncementSchema.definitions['mongoQueryOperator'] = MongoQueryOperatorSchema
AnnouncementSchema.definitions['mongoFindQuery'] = MongoFindQuerySchema
c.extendBasicProperties AnnouncementSchema, 'announcement'
module.exports = AnnouncementSchema
