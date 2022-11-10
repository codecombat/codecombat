const schema = require('./../schemas')

const EventSchema = schema.object(
  {
    title: 'Calendar Events',
    required: ['type', 'owner', 'startDate'],
    default: {
      type: 'online-classes'
    }
  },
  {
    name: { type: 'string', description: 'event Title' },
    description: { type: 'string', format: 'markdown' },
    owner: schema.objectId({ description: 'owner of event, i.e. teacher for online-classes' }),
    type: { enum: ['online-classes'], type: 'string' },
    members: schema.array({
      description: 'members in event, i.e. students for online-classes'
    }, schema.objectId()),
    startDate: schema.stringDate({ description: 'the (first) start time of event' }),
    endDate: schema.stringDate({ description: 'the (first) end time of event' }),
    rrule: { type: 'string', description: 'recurring rule. follow the rrule.js' }
  }
)

schema.extendBasicProperties(EventSchema, 'event')

module.exports = EventSchema
