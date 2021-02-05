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
  submittedCode:
    type: 'string'
  submittedCodeLanguage:
    type: 'string'
  wins:
    type: 'number'
  losses:
    type: 'number'
  ties:
    type: 'number'
  totalScore:
    type: 'number'
  originalRank:             # for randomsimulation rank
    type: 'number'
  standardDeviation:
    type: 'number'
    minimum: 0
  meanStrength:
    type: 'number'
  


module.exports = TournamentSubmissionSchema