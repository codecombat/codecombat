c = require './../schemas'

TournamentSubmissionSchema = c.object
  title: 'Submission'
  description: 'A single submission for a given tournament.'
  default:
    codeLanguage: 'python'
    score: 1000

_.extend TournamentSubmissionSchema.properties,
  tournamentID:
    type: 'string'
  levelSessionID:
    type: 'string'
  playerID:
    type: 'string'
  code:
    type: 'string'
  codeLanguage:
    type: 'string'
  wins:
    type: 'number'
  losses:
    type: 'number'
  ties:
    type: 'number'
  score:
    type: 'number'


module.exports = TournamentSubmissionSchema