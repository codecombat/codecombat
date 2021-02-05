c = require './../schemas'

TournamentSchema = c.object
  title: 'Tournament'
  description: 'A scheduled tournament with certain date, level and clan'
  required: ['levelOriginal', 'name']

c.extendNamedProperties TournamentSchema

_.extend TournamentSchema.properties,
  description:
    type: 'string'
  created: c.date
    title: 'Created'
    readOnly: true
  levelOriginal: c.objectId()
  startDate: c.stringDate()
  endDate: c.stringDate()
  state:
    type: 'string'
    enum: ['initializing', 'starting', 'ended', 'disabled']
  clan: c.objectId({links: [{rel: 'db', href: '/db/clan/{($)}'}]})

c.extendBasicProperties TournamentSchema, 'tournament'
module.exports = TournamentSchema
