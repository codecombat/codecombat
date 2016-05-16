log = require 'winston'
async = require 'async'
errors = require '../../commons/errors'
scoringUtils = require './scoringUtils'
LevelSession = require '../../models/LevelSession'
TaskLog = require './../../models/ScoringTask'

module.exports = processTaskResult = (req, res) ->
  return if scoringUtils.simulatorIsTooOld req, res
  originalSessionID = req.body?.originalSessionID
  req.body?.simulator?.user = '' + req.user?._id
  yetiGuru = {}
  try
    async.waterfall [
      verifyClientResponse.bind(yetiGuru, req.body)
      fetchTaskLog.bind(yetiGuru)
      checkTaskLog.bind(yetiGuru)
      deleteQueueMessage.bind(yetiGuru)
      fetchLevelSession.bind(yetiGuru)
      checkSubmissionDate.bind(yetiGuru)
      logTaskComputation.bind(yetiGuru)
      scoringUtils.calculateSessionScores.bind(yetiGuru)
      scoringUtils.indexNewScoreArray.bind(yetiGuru)
      scoringUtils.addMatchToSessionsAndUpdate.bind(yetiGuru)
      scoringUtils.updateUserSimulationCounts.bind(yetiGuru, req.user?._id)
      determineIfSessionShouldContinueAndUpdateLog.bind(yetiGuru)
      findNearestBetterSessionID.bind(yetiGuru)
      addNewSessionsToQueue.bind(yetiGuru)
    ], (err, results) ->
      if err is 'shouldn\'t continue'
        markSessionAsDoneRanking originalSessionID, (err) ->
          if err? then return scoringUtils.sendResponseObject res, {'error': 'There was an error marking the session as done ranking'}
          scoringUtils.sendResponseObject res, {message: 'The scores were updated successfully, person lost so no more games are being inserted!'}
      else if err is 'no session was found'
        markSessionAsDoneRanking originalSessionID, (err) ->
          if err? then return scoringUtils.sendResponseObject res, {'error': 'There was an error marking the session as done ranking'}
          scoringUtils.sendResponseObject res, {message: 'There were no more games to rank (game is at top)!'}
      else if err?
        errors.serverError res, "There was an error:#{err}"
      else
        scoringUtils.sendResponseObject res, {message: 'The scores were updated successfully and more games were sent to the queue!'}
  catch e
    errors.serverError res, 'There was an error processing the task result!'


verifyClientResponse = (responseObject, callback) ->
  # TODO: better verification
  if typeof responseObject isnt 'object' or responseObject?.originalSessionID?.length isnt 24
    callback 'The response to that query is required to be a JSON object.'
  else
    @clientResponseObject = responseObject
    callback null, responseObject

fetchTaskLog = (responseObject, callback) ->
  TaskLog.findOne(_id: responseObject.taskID).exec (err, taskLog) =>
    return callback new Error("Couldn't find TaskLog for _id #{responseObject.taskID}!") unless taskLog
    @taskLog = taskLog
    callback err, taskLog

checkTaskLog = (taskLog, callback) ->
  if taskLog.get('calculationTimeMS') then return callback 'That computational task has already been performed'
  if hasTaskTimedOut taskLog.get('sentDate') then return callback 'The task has timed out'
  callback null

hasTaskTimedOut = (taskSentTimestamp) ->
  taskSentTimestamp + scoringUtils.scoringTaskTimeoutInSeconds * 1000 < Date.now()

deleteQueueMessage = (callback) ->
  scoringUtils.scoringTaskQueue.deleteMessage @clientResponseObject.receiptHandle, (err) ->
    callback err

fetchLevelSession = (callback) ->
  selectString = 'submitDate creator level standardDeviation meanStrength totalScore submittedCodeLanguage leagues'
  LevelSession.findOne(_id: @clientResponseObject.originalSessionID).select(selectString).lean().exec (err, session) =>
    @levelSession = session
    callback err

checkSubmissionDate = (callback) ->
  supposedSubmissionDate = new Date(@clientResponseObject.sessions[0].submitDate)
  if Number(supposedSubmissionDate) isnt Number(@levelSession.submitDate)
    callback 'The game has been resubmitted. Removing from queue...'
  else
    callback null

logTaskComputation = (callback) ->
  @taskLog.set 'calculationTimeMS', @clientResponseObject.calculationTimeMS
  @taskLog.set 'sessions', @clientResponseObject.sessions
  @taskLog.save (err, saved) ->
    callback err

determineIfSessionShouldContinueAndUpdateLog = (cb) ->
  sessionID = @clientResponseObject.originalSessionIDx
  sessionRank = parseInt @clientResponseObject.originalSessionRank
  update = '$inc': {}
  if sessionRank is 0
    update['$inc'] = {numberOfWinsAndTies: 1}
  else
    update['$inc'] = {numberOfLosses: 1}
  LevelSession.findOneAndUpdate {_id: sessionID}, update, {select: 'numberOfWinsAndTies numberOfLosses', lean: true}, (err, updatedSession) ->
    if err? then return cb err, updatedSession
    totalNumberOfGamesPlayed = updatedSession.numberOfWinsAndTies + updatedSession.numberOfLosses
    if totalNumberOfGamesPlayed < 10
      #console.log 'Number of games played is less than 10, continuing...'
      cb null
    else
      ratio = (updatedSession.numberOfLosses) / (totalNumberOfGamesPlayed)
      if ratio > 0.33
        cb 'shouldn\'t continue'
        #console.log "Ratio(#{ratio}) is bad, ending simulation"
      else
        #console.log "Ratio(#{ratio}) is good, so continuing simulations"
        cb null

findNearestBetterSessionID = (cb) ->
  try
    levelOriginalID = @levelSession.level.original
    levelMajorVersion = @levelSession.level.majorVersion
    sessionID = @clientResponseObject.originalSessionID
    sessionTotalScore = @newScoresObject[sessionID].totalScore
    opponentSessionID = _.pull(_.keys(@newScoresObject), sessionID)
    opponentSessionTotalScore = @newScoresObject[opponentSessionID].totalScore
    opposingTeam = scoringUtils.calculateOpposingTeam(@clientResponseObject.originalSessionTeam)
  catch e
    cb e

  retrieveAllOpponentSessionIDs sessionID, (err, opponentSessionIDs) ->
    if err? then return cb err, null
    queryParameters =
      totalScore:
        $gt: opponentSessionTotalScore
      _id:
        $nin: opponentSessionIDs
      'level.original': levelOriginalID
      'level.majorVersion': levelMajorVersion
      submitted: true
      team: opposingTeam
    if opponentSessionTotalScore < 30
      # Don't play a ton of matches at low scores--skip some in proportion to how close to 30 we are.
      # TODO: this could be made a lot more flexible.
      queryParameters['totalScore']['$gt'] = opponentSessionTotalScore + 2 * (30 - opponentSessionTotalScore) / 20

    limitNumber = 1
    sortParameters = totalScore: 1
    selectString = '_id totalScore'
    query = LevelSession.findOne(queryParameters)
      .sort(sortParameters)
      .limit(limitNumber)
      .select(selectString)
      .lean()
    #console.log "Finding session with score near #{opponentSessionTotalScore}"
    query.exec (err, session) ->
      if err? then return cb err, session
      unless session then return cb 'no session was found'
      #console.log "Found session with score #{session.totalScore}"
      cb err, session._id

retrieveAllOpponentSessionIDs = (sessionID, cb) ->
  selectString = 'matches.opponents.sessionID matches.date submitDate'
  LevelSession.findOne({_id: sessionID}).select(selectString).lean().exec (err, session) ->
    if err? then return cb err, null
    opponentSessionIDs = (match.opponents[0].sessionID for match in session.matches when match.date > session.submitDate)
    cb err, opponentSessionIDs

addNewSessionsToQueue = (sessionID, callback) ->
  sessions = [@clientResponseObject.originalSessionID, sessionID]
  scoringUtils.addPairwiseTaskToQueue sessions, callback

markSessionAsDoneRanking = (sessionID, cb) ->
  #console.log 'Marking session as done ranking...'
  LevelSession.update {_id: sessionID}, {isRanking: false}, cb
