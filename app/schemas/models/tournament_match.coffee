c = require './../schemas'

TournamentMatchSchema = c.object
  title: 'Match'
  description: 'A single match for a given tournament.'

_.extend TournamentMatchSchema.properties,
  tournamentID:
    type: 'string'
  opponents:
    type: 'array'
    items: 'string'
  winner:
    type: 'string'
  type:
    type: 'string'
    enum: ['round-robin']    # maybe more in the future
  date:
    type: c.date {description: 'The Simulation Date'}
  simulator: {type: 'object', description: 'Holds info on who simulated the match, and with what tools.'}
  randomSeed: {description: 'Stores the random seed that was used during this match.'}


module.exports = TournamentMatchSchema