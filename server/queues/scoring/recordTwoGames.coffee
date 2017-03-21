log = require 'winston'
async = require 'async'
errors = require '../../commons/errors'
scoringUtils = require './scoringUtils'
LevelSession = require '../../models/LevelSession'

module.exports = recordTwoGames = (req, res) ->
  sessions = req.body.sessions
  #console.log 'Recording non-chained result of', sessions?[0]?.name, sessions[0]?.metrics?.rank, 'and', sessions?[1]?.name, sessions?[1]?.metrics?.rank
  return if scoringUtils.simulatorIsTooOld req, res
  req.body?.simulator?.user = '' + req.user?._id

  yetiGuru = clientResponseObject: req.body, isRandomMatch: true
  async.waterfall [
    scoringUtils.calculateSessionScores.bind(yetiGuru)  # Fetches a few small properties from both sessions, prepares @levelSessionUpdates with the score part
    scoringUtils.indexNewScoreArray.bind(yetiGuru)  # Creates and returns @newScoresObject, no query
    scoringUtils.addMatchToSessionsAndUpdate.bind(yetiGuru)  # Adds matches to the session updates and does the writes
    scoringUtils.updateUserSimulationCounts.bind(yetiGuru, req.user?._id)
  ], (err, successMessageObject) ->
    if err? then return errors.serverError res, "There was an error recording the single game: #{err}"
    scoringUtils.sendResponseObject res, {message: 'The single game was submitted successfully!'}
