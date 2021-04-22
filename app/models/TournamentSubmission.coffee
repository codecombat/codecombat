LevelSession = require './LevelSession'

module.exports = class TournamentSubmission extends LevelSession
  @className: 'TournamentSubmission'
  @schema: require 'schemas/models/tournament_submission.schema'
  urlRoot: '/db/tournament.submission'