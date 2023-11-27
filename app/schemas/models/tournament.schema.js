// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const c = require('./../schemas')

const TournamentSchema = c.object({
  title: 'Tournament',
  description: 'A scheduled tournament with certain date, level and clan',
  required: ['levelOriginal', 'name'],
  default: {
    simulationType: 'round-robin'
  }
})

c.extendNamedProperties(TournamentSchema)

_.extend(TournamentSchema.properties, {
  description: {
    type: 'string'
  },
  created: c.date({
    title: 'Created',
    readOnly: true
  }),
  levelOriginal: c.objectId(),
  startDate: c.stringDate(),
  endDate: c.stringDate(),
  resultsDate: c.stringDate({ description: 'The date when the tournament results will be announced (hidden until then)' }),
  simulationType: {
    type: 'string'
  },
  simulationPriority: {
    type: 'number',
    description: '0/unset means current match queue priority, 1-5 to increase redis priority so that the matches are simulated earlier'
  },
  reviewResults: {
    type: 'boolean',
    description: 'if the owner want to review results before it be published'
  },
  state: {
    type: 'string',
    enum: ['initializing', 'starting', 'ranking', 'waiting', 'ended', 'disabled']
  },
  clan: c.objectId({ links: [{ rel: 'db', href: '/db/clan/{($)}' }] })
}
)

c.extendBasicProperties(TournamentSchema, 'tournament')
module.exports = TournamentSchema
