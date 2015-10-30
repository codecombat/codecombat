log = require 'winston'
async = require 'async'
errors = require '../../commons/errors'
scoringUtils = require './scoringUtils'
LevelSession = require '../../levels/sessions/LevelSession'

module.exports = getTwoGames = (req, res) ->
  #return errors.unauthorized(res, 'You need to be logged in to get games.') unless req.user?.get('email')
  return if scoringUtils.simulatorIsTooOld req, res
  humansSessionID = req.body.humansGameID
  ogresSessionID = req.body.ogresGameID
  return getSpecificSessions res, humansSessionID, ogresSessionID if humansSessionID and ogresSessionID
  getRandomSessions req.user, sendSessionsResponse(res)

sessionSelectionString = 'team totalScore transpiledCode submittedCodeLanguage teamSpells levelID creatorName creator submitDate leagues'

sendSessionsResponse = (res) ->
  (err, sessions) ->
    if err then return errors.serverError res, "Couldn't get two games to simulate: #{err}"
    unless _.filter(sessions).length is 2
      console.log 'No games to score.', sessions.length
      res.send 204, 'No games to score.'
      return res.end()
    taskObject = messageGenerated: Date.now(), sessions: (scoringUtils.formatSessionInformation session for session in sessions)
    #console.log 'Dispatching ladder game simulation between', taskObject.sessions[0].creatorName, 'and', taskObject.sessions[1].creatorName
    scoringUtils.sendResponseObject res, taskObject

getSpecificSessions = (res, humansSessionID, ogresSessionID) ->
  async.map [humansSessionID, ogresSessionID], getSpecificSession, sendSessionsResponse(res)

getSpecificSession = (sessionID, callback) ->
  LevelSession.findOne(_id: sessionID).select(sessionSelectionString).lean().exec (err, session) ->
    if err? then return callback "Couldn\'t find target simulation session #{sessionID}"
    callback null, session

getRandomSessions = (user, callback) ->
  # Determine whether to play a random match, an internal league match, or an external league match.
  # Only people in a league will end up simulating internal league matches (for leagues they're in) except by dumb chance.
  # If we don't like that, we can rework sampleByLevel to have an opportunity to switch to internal leagues if the first session had a league affiliation.
  leagueIDs = user?.get('clans') or []
  #leagueIDs = leagueIDs.concat user?.get('courseInstances') or []
  leagueIDs = (leagueID + '' for leagueID in leagueIDs)  # Make sure to fetch them as strings.
  return sampleByLevel callback unless leagueIDs.length and Math.random() > 1 / leagueIDs.length
  leagueID = _.sample leagueIDs
  findRandomSession {'leagues.leagueID': leagueID}, (err, session) ->
    if err then return callback err
    unless session then return sampleByLevel callback
    otherTeam = scoringUtils.calculateOpposingTeam session.team
    queryParameters = team: otherTeam, levelID: session.levelID
    if Math.random() < 0.5
      # Try to play a match on the internal league ladder for this level
      queryParameters['leagues.leagueID'] = leagueID
      findRandomSession queryParameters, (err, otherSession) ->
        if err then return callback err
        if otherSession then return callback null, [session, otherSession]
        # No opposing league session found; try to play an external match
        delete queryParameters['leagues.leagueID']
        findRandomSession queryParameters, (err, otherSession) ->
          if err then return callback err
          callback null, [session, otherSession]
    else
      # Play what will probably end up being an external match
      findRandomSession queryParameters, (err, otherSession) ->
        if err then return callback err
        callback null, [session, otherSession]

# Sampling by level: we pick a level, then find a human and ogre session for that level, one at random, one biased towards recent submissions.
#ladderLevelIDs = ['greed', 'criss-cross', 'brawlwood', 'dungeon-arena', 'gold-rush', 'sky-span']  # Let's not give any extra simulations to old ladders.
ladderLevelIDs = ['dueling-grounds', 'cavern-survival', 'multiplayer-treasure-grove', 'harrowland', 'zero-sum', 'ace-of-coders', 'wakka-maul']
sampleByLevel = (callback) ->
  levelID = _.sample ladderLevelIDs
  favorRecentHumans = Math.random() < 0.5  # We pick one session favoring recent submissions, then find another one uniformly to play against
  async.map [{levelID: levelID, team: 'humans', favorRecent: favorRecentHumans}, {levelID: levelID, team: 'ogres', favorRecent: not favorRecentHumans}], findRandomSession, callback

findRandomSession = (queryParams, callback) ->
  # In MongoDB 3.2, we will be able to easily get a random document with aggregate $sample: https://jira.mongodb.org/browse/SERVER-533
  queryParams.submitted = true
  favorRecent = queryParams.favorRecent
  delete queryParams.favorRecent
  if favorRecent
    return findRecentRandomSession queryParams, callback
  queryParams.randomSimulationIndex = $lte: Math.random()
  sort = randomSimulationIndex: -1
  LevelSession.findOne(queryParams).sort(sort).select(sessionSelectionString).lean().exec (err, session) ->
    return callback err if err
    return callback null, session if session
    delete queryParams.randomSimulationIndex  # Just find the highest-indexed session, if our randomSimulationIndex was lower than the lowest one.
    LevelSession.findOne(queryParams).sort(sort).select(sessionSelectionString).lean().exec (err, session) ->
      return callback err if err
      callback null, session

findRecentRandomSession = (queryParams, callback) ->
  # We pick a random submitDate between the first submit date for the level and now, then do a $lt fetch to find a session to simulate.
  # We bias it towards recently submitted sessions.
  findEarliestSubmission queryParams, (err, startDate) ->
    return callback err, null unless startDate
    now = new Date()
    interval = now - startDate
    cutoff = new Date now - Math.pow(Math.random(), 4) * interval
    queryParams.submitDate = $gte: startDate, $lt: cutoff
    LevelSession.findOne(queryParams).sort(submitDate: -1).select(sessionSelectionString).lean().exec (err, session) ->
      return callback err if err
      callback null, session

earliestSubmissionCache = {}
findEarliestSubmission = (queryParams, callback) ->
  cacheKey = JSON.stringify queryParams
  return callback null, cached if cached = earliestSubmissionCache[cacheKey]
  LevelSession.findOne(queryParams).sort(submitDate: 1).lean().exec (err, earliest) ->
    return callback err if err
    result = earliestSubmissionCache[cacheKey] = earliest?.submitDate
    callback null, result
