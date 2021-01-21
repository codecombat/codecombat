c = require './../schemas'

TournamentSchema = c.object
  title: 'Tournament'
  description: 'A scheduled tournament with certain date and level'
  required: ['levelOriginalID', 'name']

c.extendNamedProperties TournamentSchema

_.extend TournamentSchema.properties,
  description:
    type: 'string'
  created: c.date
    title: 'Created'
    readOnly: true
  levelOriginalID:
    type: 'string' 
  startDate: c.stringDate()
  endDate: c.stringDate()
  state:
    type: 'string'
    'enum': ['Init', 'Strating', 'Ended', 'Disabled']
  clanID:
    type: 'string'

c.extendBasicProperties TournamentSchema, 'Tournament'
module.exports = TournamentSchema