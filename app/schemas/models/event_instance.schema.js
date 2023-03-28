const schema = require('./../schemas')

const EventInstanceSchema = schema.object(
  {
    title: 'Calendar Event Instance',
    required: ['event'],
    default: { done: false }
  },
  {
    event: schema.objectId(),
    owner: schema.objectId({ description: 'real owner of event, unset when same with event.owner i.e. temp teacher for a course in online-classes' }),
    members: schema.array({
      description: 'event instance attendees'
    }, {
      userId: schema.objectId(),
      attendance: { type: 'boolean' },
      description: { type: 'string' }
    }),
    startDate: schema.stringDate({ description: 'the start time of event instance' }),
    endDate: schema.stringDate({ description: 'the (first) end time of event' }),
    done: { type: 'boolean' },
    index: { type: 'number', description: 'the instance index of recurring events' },
    video: { type: 'string', description: 'the video url of event instance' }
  }
)

schema.extendBasicProperties(EventInstanceSchema, 'EventInstance')

module.exports = EventInstanceSchema
