c = require './../schemas'

TournamentSubmissionSchema = c.object
  title: 'Submission'
  description: 'A single submission for a given tournament.'
  default:
    submittedCodeLanguage: 'python'
    totalScore: 10

_.extend TournamentSubmissionSchema.properties,
  tournament: c.objectId()
  levelSession: c.objectId()
  owner: c.objectId()
  submittedCode:
    type: 'object'
    additionalProperties:
      type: 'object'
      additionalProperties:
        type: 'string'
        format: 'code'
  submittedCodeLanguage:
    type: 'string'
  wins:
    type: 'number'
  losses:
    type: 'number'
  creatorAge:
    type: 'number'
    minimum: 0
  totalScore:               # bayesian calculation of strength
    type: 'number'
  originalRank:             # for randomsimulation rank
    type: 'number'
  standardDeviation:
    type: 'number'
    minimum: 0
  meanStrength:
    type: 'number'
  created: c.date
    title: 'Created'
    readOnly: true



c.extendBasicProperties TournamentSubmissionSchema, 'tournament.submission'
module.exports = TournamentSubmissionSchema
