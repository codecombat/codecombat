const schema = require('./../schemas')

const EventSchema = schema.object(
  {
    title: 'Calendar Events',
    required: ['type'],
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
    startDates: schema.array({ description: 'in case there\'re multiple events in a period' }, schema.stringDate({ description: 'the (first) start time of event' })),
    endDates: schema.array({}, schema.stringDate({ description: 'the (first) end time of event' })),
    times: { type: 'number', description: 'how many times does the event repeat. i.e. 1 year online-class may have 48 times' },
    interval: { type: 'number', description: 'In days, only works when times > 1' }
  }
)

schema.extendBasicProperties(EventSchema, 'event')

module.exports = EventSchema
