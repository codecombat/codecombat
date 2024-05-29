const schema = require('./../schemas')

const EventSchema = schema.object(
  {
    title: 'Calendar Events',
    required: ['name', 'type', 'owner', 'startDate'],
    default: {
      type: 'online-classes'
    }
  },
  {
    name: { type: 'string', description: 'event Title' },
    description: { type: 'string', format: 'markdown' },
    owner: schema.objectId({ description: 'owner of event, i.e. teacher for online-classes' }),
    type: { enum: ['online-classes', 'trial-classes'], type: 'string' },
    members: schema.array({
      description: 'members in event, i.e. students for online-classes'
    }, schema.object({ required: ['userId'] }, {
      userId: schema.objectId(),
      startIndex: { type: 'integer', description: 'the index of first instance the user would join' },
      count: { type: 'integer', description: 'the total count of instances the user would join' }
    })),
    removedMembers: schema.array({
      description: 'members be removed, make a record'
    }, schema.object({ required: ['userId'] }, {
      userId: schema.objectId(),
      removedDate: schema.stringDate({ description: 'the date the user be removed' })
    })),
    startDate: schema.stringDate({ description: 'the (first) start time of event' }),
    endDate: schema.stringDate({ description: 'the (first) end time of event' }),
    rrule: { type: 'string', description: 'recurring rule follow the rrule.js' },
    syncedToGC: { type: 'boolean', description: 'whether the event has been synced to google calendar' },
    googleEventId: { type: 'string', description: 'the google calendar event id' },
    gcEmails: { type: 'array', items: { type: 'string' }, description: 'google calendar emails' },
    meetingLink: {
      type: 'string',
      description: 'meeting link of the event, i.e. zoom link'
    },
    state: { type: 'string', description: 'state of the event', enum: ['pending', 'active', 'cancelled'] },
    properties: {
      type: 'object',
      additionalProperties: true,
    }
  }
)

schema.extendBasicProperties(EventSchema, 'event')

module.exports = EventSchema
