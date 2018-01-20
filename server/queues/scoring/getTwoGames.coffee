log = require 'winston'
async = require 'async'
errors = require '../../commons/errors'
scoringUtils = require './scoringUtils'
LevelSession = require '../../models/LevelSession'
Mandate = require '../../models/Mandate'
simpleCache = require '../../lib/simpleCache'

module.exports = getTwoGames = (req, res) ->
  #return errors.unauthorized(res, 'You need to be logged in to get games.') unless req.user?.get('email')
  return if scoringUtils.simulatorIsTooOld req, res
  humansSessionID = req.body.humansGameID
  ogresSessionID = req.body.ogresGameID
  return getSpecificSessions res, humansSessionID, ogresSessionID if humansSessionID and ogresSessionID
  Mandate.findOne({}).cache(5 * 60 * 1000).exec (err, mandate) ->
    if err then return errors.serverError res, "Error fetching our Mandate: #{err}"
    if (throughputRatio = mandate?.get 'simulationThroughputRatio')? and Math.random() > throughputRatio
      return sendSessionsResponse(res)(null, [])
    options =
      background: req.body.background
      levelID: req.body.levelID
      leagueID: req.body.leagueID
      user: req.user
    getRandomSessions options, sendSessionsResponse(res)

sessionSelectionString = 'team totalScore submittedCode submittedCodeLanguage teamSpells levelID creatorName creator submitDate leagues'

sendSessionsResponse = (res) ->
  (err, sessions) ->
    if err then return errors.serverError res, "Couldn't get two games to simulate: #{err}"
    unless _.filter(sessions).length is 2
      res.status(204).send 'No games to score.'
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

getRandomSessions = (options, callback) ->
  # Determine whether to play a random match, an internal league match, or an external league match.
  # Only people in a league will end up simulating internal league matches (for leagues they're in) except by dumb chance.
  # If we don't like that, we can rework sampleByLevel to have an opportunity to switch to internal leagues if the first session had a league affiliation.
  if not leagueID = options.leagueID
    leagueIDs = options.user?.get('clans') or []
    leagueIDs = leagueIDs.concat options.user?.get('courseInstances') or []
    leagueIDs = (leagueID + '' for leagueID in leagueIDs)  # Make sure to fetch them as strings.
    return sampleByLevel options, callback unless leagueIDs.length and Math.random() > 1 / leagueIDs.length
    options.leagueID = _.sample leagueIDs
  queryParameters = {'leagues.leagueID': options.leagueID}
  queryParameters.levelID = options.levelID if options.levelID
  nextStep = makeGetSecondRandomLeagueSession options, callback
  if Math.random() < 0.5 and options.user and not options.user.isTeacher()
    # Prioritize simulating own games
    LevelSession.find(_.assign({creator: options.user._id + ''}, queryParameters)).select(sessionSelectionString).lean().exec (err, sessions) ->
      if err then return callback err
      if sessions.length
        nextStep null, _.sample sessions
      else
        # Didn't have our own session, so find someone else's
        findRandomSession {query: queryParameters}, nextStep
  else
    findRandomSession {query: queryParameters}, nextStep

makeGetSecondRandomLeagueSession = (options, callback) ->
  (err, session) ->
    if err then return callback err
    unless session then return sampleByLevel options, callback
    otherTeam = scoringUtils.calculateOpposingTeam session.team
    queryParameters = team: otherTeam, levelID: session.levelID, creator: {$ne: session.creator + ''}
    if Math.random() < 0.5
      # Try to play a match on the internal league ladder for this level
      queryParameters['leagues.leagueID'] = options.leagueID
      findNextLeagueOpponent session, queryParameters, (err, otherSession) ->
        if err then return callback err
        if otherSession
          session.shouldUpdateLastOpponentSubmitDateForLeague = options.leagueID
          return callback null, [session, otherSession]
        # No opposing league session found; try to play an external match
        delete queryParameters['leagues.leagueID']
        delete queryParameters.submitDate
        findRandomSession {session: session, query: queryParameters}, (err, otherSession) ->
          if err then return callback err
          callback null, [session, otherSession]
    else
      # Play what will probably end up being an external match
      findRandomSession {session: session, query: queryParameters}, (err, otherSession) ->
        if err then return callback err
        callback null, [session, otherSession]

# Sampling by level: we pick a level, then find a human and ogre session for that level, one at random, one biased towards recent submissions.
ladderLevelIDs = ['dueling-grounds', 'cavern-survival', 'multiplayer-treasure-grove', 'harrowland', 'zero-sum', 'ace-of-coders', 'wakka-maul', 'power-peak', 'cross-bones', 'summation-summit', 'the-battle-of-sky-span']
backgroundLadderLevelIDs = _.without ladderLevelIDs, 'zero-sum', 'ace-of-coders', 'elemental-wars'
sampleByLevel = (options, callback) ->
  levelID = options.levelID or _.sample(if options.background then backgroundLadderLevelIDs else ladderLevelIDs)
  if Math.random() < 0.5 and options.user and not options.user.isTeacher()
    # Prioritize simulating own games
    LevelSession.find({creator: options.user._id + '', submitted: true, levelID: levelID}).select(sessionSelectionString).lean().exec (err, sessions) ->
      if err then return callback err
      if sessions.length
        session = _.sample sessions
        otherTeam = if session.team is 'humans' then 'ogres' else 'humans'
        findRandomSession {session: session, query: {levelID: levelID, team: otherTeam}}, (err, otherSession) ->
          if err then return callback err
          callback null, [session, otherSession]
      else
        delete options.user
        sampleByLevel options, callback
  else
    favorRecentHumans = Math.random() < 0.5  # We pick one session favoring recent submissions, then find another one uniformly to play against
    async.map [
      {query: {levelID: levelID, team: 'humans'}, favorRecent: favorRecentHumans},
      {query: {levelID: levelID, team: 'ogres'}, favorRecent: not favorRecentHumans}
    ], findRandomSession, callback

findNextLeagueOpponent = (session, queryParams, callback) ->
  queryParams.submitted = true
  league = _.find session.leagues, leagueID: queryParams['leagues.leagueID']
  lastOpponentSubmitDate = league.lastOpponentSubmitDate or new Date()
  queryParams.submitDate = $lt: lastOpponentSubmitDate
  sort = submitDate: -1
  LevelSession.findOne(queryParams).sort(sort).select(sessionSelectionString).lean().exec (err, otherSession) ->
    return callback err if err
    callback null, otherSession

findRandomSession = (options, callback) ->
  # In MongoDB 3.2, we will be able to easily get a random document with aggregate $sample: https://jira.mongodb.org/browse/SERVER-533
  query = options.query
  query.submitted = true
  if options.favorRecent
    return findRecentRandomSession query, callback
  if query.team and options.session
    ladderScores = simpleCache.getLadderScores query.levelID, options.session.team
    if ladderScores and Math.random() < 0.5
      # Try to find some match near this one in score
      return findComparableSession {session: options.session, query: query, scores: ladderScores}, callback
  query.randomSimulationIndex = $lte: Math.random()
  sort = randomSimulationIndex: -1
  LevelSession.findOne(query).sort(sort).select(sessionSelectionString).lean().exec (err, session) ->
    return callback err if err
    return callback null, session if session
    delete query.randomSimulationIndex  # Just find the highest-indexed session, if our randomSimulationIndex was lower than the lowest one.
    LevelSession.findOne(query).sort(sort).select(sessionSelectionString).lean().exec (err, session) ->
      return callback err if err
      callback null, session

findRecentRandomSession = (query, callback) ->
  # We pick a random submitDate between the first submit date for the level and now, then do a $lt fetch to find a session to simulate.
  # We bias it towards recently submitted sessions.
  findEarliestSubmission query, (err, startDate) ->
    return callback err, null unless startDate
    now = new Date()
    interval = now - startDate
    cutoff = new Date now - Math.pow(Math.random(), 4) * interval
    query.submitDate = $gte: startDate, $lt: cutoff
    LevelSession.findOne(query).sort(submitDate: -1).select(sessionSelectionString).lean().exec (err, session) ->
      return callback err if err
      callback null, session

earliestSubmissionCache = {}
findEarliestSubmission = (query, callback) ->
  cacheKey = JSON.stringify query
  return callback null, cached if cached = earliestSubmissionCache[cacheKey]
  LevelSession.findOne(query).sort(submitDate: 1).lean().exec (err, earliest) ->
    return callback err if err
    result = earliestSubmissionCache[cacheKey] = earliest?.submitDate
    callback null, result

findComparableSession = (options, callback) ->
  # We pick a random session kind of close in score to the target session
  scores = options.scores
  sessionRank = _.sortedIndex scores, options.session.totalScore, (index) -> -index  # Descending order
  range = Math.max 100, Math.round(scores.length / 500)
  maxScoreIndex = Math.max 0, sessionRank - range
  minScoreIndex = Math.min scores.length - 1, sessionRank + range
  possibleScores = scores.slice(maxScoreIndex, minScoreIndex)
  targetScore = _.sample possibleScores
  #console.log 'trying to find something with score close to', options.session.totalScore, 'of', scores.slice(0, 5), '... where we are ranked', sessionRank, ' and found', targetScore, 'between', maxScoreIndex, scores[maxScoreIndex], 'and', minScoreIndex, scores[minScoreIndex]
  options.query.totalScore = $lte: targetScore
  sort = totalScore: -1
  LevelSession.findOne(options.query).sort(sort).select(sessionSelectionString).lean().exec (err, session) ->
    return callback err if err
    callback null, session
