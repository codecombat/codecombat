c = require './../schemas'

TournamentMatchSchema = c.object
  title: 'Match'
  description: 'A single match for a given tournament.'

_.extend TournamentMatchSchema.properties,
  tournament: c.objectId()
  opponents:
    type: 'string'   # use id1:id2 here to avoid mongo cannot unique index on array
  winner:
    type: 'string'
  type:
    type: 'string'
    enum: ['round-robin', 'king-of-the-hill']    # maybe more in the future
  date:
    type: c.date {description: 'The Simulation Date'}
  simulator: {type: 'object', description: 'Holds info on who simulated the match, and with what tools.'}
  randomSeed: {description: 'Stores the random seed that was used during this match.'}


c.extendBasicProperties TournamentMatchSchema, 'tournament.match'
module.exports = TournamentMatchSchema