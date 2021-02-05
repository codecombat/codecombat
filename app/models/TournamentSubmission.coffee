CocoModel = require './CocoModel'

module.exports = class TournamentSubmission extends CocoModel
  @className: 'TournamentSubmission'
  @schema: require 'schemas/models/tournament_submission.schema'
  urlRoot: '/db/tournament.submission'