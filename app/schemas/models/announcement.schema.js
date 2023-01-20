const c = require('./../schemas')
const _ = require('lodash')

const MongoQueryOperatorSchema = {
  title: 'Query Operator',
  type: 'object',
  properties: {
    $gt: { type: 'number' },
    $gte: { type: 'number' },
    $in: { type: 'array' },
    $lt: { type: 'number' },
    $lte: { type: 'number' },
    $ne: { type: ['number', 'string'] },
    $nin: { type: 'array' },
    $exists: { type: 'boolean' }
  },
  additionalProperties: false
}

const MongoFindQuerySchema = {
  title: 'Query',
  type: 'object',
  format: 'mongo-query-user',
  patternProperties: {
    '^[-a-zA-Z0-9._]*$': {
      anyOf: [
        { $ref: '#/definitions/mongoQueryOperator' },
        { type: 'string' },
        { type: 'object' },
        { type: 'boolean' }
      ]
    }
  },
  properties: {},
  additionalProperties: false,
  definitions: {}
}

const AnnouncementSchema = c.object({
  title: 'Announcement',
  description: '',
  required: ['name', 'product'],
  default: {
    content: '',
    startDate: '',
    query: {},
    product: 'codecombat',
    kind: 'normal'
  },
  allOf: [
    {
      if: {
        properties: { kind: { const: 'sequence' } },
        required: ['kind']
      },
      then: {
        required: ['sequence']
      }
    },
    {
      if: {
        not: { properties: { kind: { const: 'banner' } } }
      },
      then: {
        required: ['content']
      }
    }
  ]
})

// c.extendNamedProperties AnnouncementSchema # do we need name/slug ?

_.extend(AnnouncementSchema.properties, {
  created: c.date({
    title: 'Created',
    readOnly: true
  }),
  name: {
    title: 'Title', // we can't use a property named title
    type: 'string'
  },
  content: {
    type: 'string',
    format: 'markdown'
  },
  startDate: c.stringDate({ title: 'PublishDate', description: 'The publish/start date that user can see this Notification' }),
  endDate: c.stringDate(), // unset for forever
  query: {
    $ref: '#/definitions/mongoFindQuery'
  },
  product: {
    type: 'string',
    enum: ['ozaria', 'codecombat', 'both']
  },
  kind: {
    type: 'string',
    enum: ['normal', 'sequence', 'banner'],
    description: 'normal: normal notifications; banner: show as the banner in the homeview but not in notifications; sequence: show'
  },
  sequence: {
    type: 'object',
    description: 'if kind is sequence but sequence is empty, means it is the first notification in sequence',
    properties: {
      prevId: { type: 'string', links: [{ rel: 'db', href: '/db/announcement/{{$}}' }], format: 'announcement', description: 'requires reading prev announcement first', title: 'Prev Announcement' },
      prevTime: {
        type: 'number',
        description: 'how many hours required after read prev announcement'
      }
    }
  },

  i18n: {
    type: 'object',
    format: 'i18n',
    props: ['name', 'content']
  }
})

AnnouncementSchema.definitions = {}
AnnouncementSchema.definitions.mongoQueryOperator = MongoQueryOperatorSchema
AnnouncementSchema.definitions.mongoFindQuery = MongoFindQuerySchema
c.extendBasicProperties(AnnouncementSchema, 'announcement')
c.extendSearchableProperties(AnnouncementSchema)
c.extendTranslationCoverageProperties(AnnouncementSchema)

module.exports = AnnouncementSchema
