log = require 'winston'
async = require 'async'
errors = require '../../commons/errors'
scoringUtils = require './scoringUtils'
LevelSession = require '../../levels/sessions/LevelSession'

module.exports = getTwoGames = (req, res) ->
  #if isUserAnonymous req then return errors.unauthorized(res, 'You need to be logged in to get games.')
  humansGameID = req.body.humansGameID
  ogresGameID = req.body.ogresGameID
  return if scoringUtils.simulatorIsTooOld req, res
  #ladderGameIDs = ['greed', 'criss-cross', 'brawlwood', 'dungeon-arena', 'gold-rush', 'sky-span']  # Let's not give any extra simulations to old ladders.
  ladderGameIDs = ['dueling-grounds', 'cavern-survival', 'multiplayer-treasure-grove', 'harrowland', 'zero-sum']
  levelID = _.sample ladderGameIDs
  unless ogresGameID and humansGameID
    recentHumans = Math.random() < 0.5  # We pick one session favoring recent submissions, then find another one uniformly to play against
    async.map [{levelID: levelID, team: 'humans', favorRecent: recentHumans}, {levelID: levelID, team: 'ogres', favorRecent: not recentHumans}], findRandomSession, (err, sessions) ->
      if err then return errors.serverError(res, "Couldn't get two games to simulate for #{levelID}.")
      unless sessions.length is 2
        res.send(204, 'No games to score.')
        return res.end()
      taskObject = messageGenerated: Date.now(), sessions: (scoringUtils.formatSessionInformation session for session in sessions)
      #console.log 'Dispatching random game between', taskObject.sessions[0].creatorName, 'and', taskObject.sessions[1].creatorName
      scoringUtils.sendResponseObject req, res, taskObject
  else
    #console.log "Directly simulating #{humansGameID} vs. #{ogresGameID}."
    selection = 'team totalScore transpiledCode submittedCodeLanguage teamSpells levelID creatorName creator submitDate'
    LevelSession.findOne(_id: humansGameID).select(selection).lean().exec (err, humanSession) =>
      if err? then return errors.serverError(res, 'Couldn\'t find the human game')
      LevelSession.findOne(_id: ogresGameID).select(selection).lean().exec (err, ogreSession) =>
        if err? then return errors.serverError(res, 'Couldn\'t find the ogre game')
        taskObject = messageGenerated: Date.now(), sessions: (scoringUtils.formatSessionInformation session for session in [humanSession, ogreSession])
        scoringUtils.sendResponseObject req, res, taskObject


earliestSubmissionCache = {}
findEarliestSubmission = (queryParams, callback) ->
  cacheKey = JSON.stringify queryParams
  return callback null, cached if cached = earliestSubmissionCache[cacheKey]
  LevelSession.findOne(queryParams).sort(submitDate: 1).lean().exec (err, earliest) ->
    return callback err if err
    result = earliestSubmissionCache[cacheKey] = earliest?.submitDate
    callback null, result

findRecentRandomSession = (queryParams, callback) ->
  # We pick a random submitDate between the first submit date for the level and now, then do a $lt fetch to find a session to simulate.
  # We bias it towards recently submitted sessions.
  findEarliestSubmission queryParams, (err, startDate) ->
    return callback err, null unless startDate
    now = new Date()
    interval = now - startDate
    cutoff = new Date now - Math.pow(Math.random(), 4) * interval
    queryParams.submitDate = $gte: startDate, $lt: cutoff
    selection = 'team totalScore transpiledCode submittedCodeLanguage teamSpells levelID creatorName creator submitDate'
    LevelSession.findOne(queryParams).sort(submitDate: -1).select(selection).lean().exec (err, session) ->
      return callback err if err
      callback null, session

findRandomSession = (queryParams, callback) ->
  # In MongoDB 3.2, we will be able to easily get a random document with aggregate $sample: https://jira.mongodb.org/browse/SERVER-533
  queryParams.submitted = true
  favorRecent = queryParams.favorRecent
  delete queryParams.favorRecent
  if favorRecent
    return findRecentRandomSession queryParams, callback
  queryParams.randomSimulationIndex = $lte: Math.random()
  selection = 'team totalScore transpiledCode submittedCodeLanguage teamSpells levelID creatorName creator submitDate'
  sort = randomSimulationIndex: -1
  LevelSession.findOne(queryParams).sort(sort).select(selection).lean().exec (err, session) ->
    return callback err if err
    return callback null, session if session
    delete queryParams.randomSimulationIndex  # Just find the highest-indexed session, if our randomSimulationIndex was lower than the lowest one.
    LevelSession.findOne(queryParams).sort(sort).select(selection).lean().exec (err, session) ->
      return callback err if err
      callback null, session

