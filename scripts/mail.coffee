do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()

async = require 'async'

serverSetup = require '../server_setup'
sendwithus = require '../server/sendwithus'
User = require '../server/models/User'
Level = require '../server/models/Level'
LevelSession = require '../server/models/LevelSession'
tournamentResults = require '../app/views/play/ladder/tournament_results'

alreadyEmailed = []

DEBUGGING = true

sendInitialRecruitingEmail = ->
  leaderboards = [
    {slug: 'brawlwood', team: 'humans', limit: 55, name: 'Brawlwood', original: '52d97ecd32362bc86e004e87', majorVersion: 0}
    {slug: 'brawlwood', team: 'ogres', limit: 40, name: 'Brawlwood', original: '52d97ecd32362bc86e004e87', majorVersion: 0}
    {slug: 'dungeon-arena', team: 'humans', limit: 300, name: 'Dungeon Arena', original: '53173f76c269d400000543c2', majorVersion: 0}
    {slug: 'dungeon-arena', team: 'ogres', limit: 250, name: 'Dungeon Arena', original: '53173f76c269d400000543c2', majorVersion: 0}
    {slug: 'greed', team: 'humans', limit: 465, name: 'Greed', original: '53558b5a9914f5a90d7ccddb', majorVersion: 0}
    {slug: 'greed', team: 'ogres', limit: 371, name: 'Greed', original: '53558b5a9914f5a90d7ccddb', majorVersion: 0}
    {slug: 'gold-rush', team: 'humans', limit: 253, name: 'Gold Rush', original: '533353722a61b7ca6832840c', majorVersion: 0}
    {slug: 'gold-rush', team: 'ogres', limit: 203, name: 'Gold Rush', original: '533353722a61b7ca6832840c', majorVersion: 0}
  ]
  async.waterfall [
    (callback) -> async.map leaderboards, grabSessions, callback
    (sessionLists, callback) -> async.map collapseSessions(sessionLists), grabUser, callback
    (users, callback) -> async.map users, emailUserInitialRecruiting, callback
  ], (err, results) ->
    return console.log 'Error:', err if err
    console.log "Looked at sending to #{results.length} users; sent to #{_.filter(results).length}."
    console.log "Sent to: ['#{(user.email for user in results when user).join('\', \'')}']"

grabSessions = (levelInfo, callback) ->
  queryParameters =
    level: {original: levelInfo.original, majorVersion: levelInfo.majorVersion}
    team: levelInfo.team
    submitted: true
  sortParameters = totalScore: -1
  selectString = 'totalScore creator'
  LevelSession.aggregate [
    {$match: queryParameters}
    {$project: {totalScore: 1, creator: 1}}
    {$sort: sortParameters}
    {$limit: levelInfo.limit}
  ], (err, sessions) ->
    return callback err if err
    for session, rank in sessions
      session.levelInfo = levelInfo
      session.rank = rank + 1
    callback null, sessions

collapseSessions = (sessionLists) ->
  userRanks = {}
  for sessionList in sessionLists
    for session in sessionList
      ranks = userRanks[session.creator] ? []
      ranks.push session
      userRanks[session.creator] = _.sortBy ranks, 'rank'
  topSessions = []
  for userID, ranks of userRanks
    topSessions.push ranks[0]
  topSessions

grabUser = (session, callback) ->
  findParameters = _id: session.creator
  selectString = 'email emailSubscriptions emails name jobProfile'
  query = User
    .findOne(findParameters)
    .select(selectString)
    .lean()
  query.exec (err, user) ->
    return callback err if err
    user.session = session
    callback null, user

totalEmailsSent = 0
emailUserInitialRecruiting = (user, callback) ->
  #return callback null, false if user.emails?.anyNotes?.enabled is false  # TODO: later, uncomment to obey also 'anyNotes' when that's untangled
  return callback null, false if user.emails?.recruitNotes?.enabled is false
  return callback null, false if user.email in alreadyEmailed
  return callback null, false if DEBUGGING and (totalEmailsSent > 1 or Math.random() > 0.05)
  ++totalEmailsSent
  name = if user.firstName and user.lastName then "#{user.firstName}" else user.name
  name = 'Wizard' if not name or name in ['Anoner', 'Anonymous']
  team = user.session.levelInfo.team
  team = team.substr(0, team.length - 1)
  context =
    email_id: sendwithus.templates.recruiting_email
    recipient:
      address: if DEBUGGING then 'nick@codecombat.com' else user.email
      name: name
    email_data:
      name: name
      level_name: user.session.levelInfo.name
      place: "##{user.session.rank}"  # like '#31'
      level_race: team
      ladder_link: "http://codecombat.com/play/ladder/#{user.session.levelInfo.slug}"
  sendwithus.api.send context, (err, result) ->
    return callback err if err
    callback null, user

sendTournamentResultsEmail = ->
  winners = tournamentResults.greed.humans.concat tournamentResults.greed.ogres
  async.waterfall [
    (callback) -> async.map winners, grabSession, callback
    (winners, callback) -> async.map winners, grabEmail, callback
    (winners, callback) -> async.map winners, emailUserTournamentResults, callback
  ], (err, results) ->
    return console.log 'Error:', err if err
    console.log "Looked at sending to #{results.length} users; sent to #{_.filter(results).length}."
    console.log "Sent to: ['#{(user.email for user in results when user).join('\', \'')}']"

grabSession = (winner, callback) ->
  LevelSession.findOne(_id: winner.sessionID).select('creator').lean().exec (err, session) ->
    return callback err if err
    winner.userID = session.creator
    callback null, winner

grabEmail = (winner, callback) ->
  User.findOne(_id: winner.userID).select('email').lean().exec (err, user) ->
    return callback err if err
    winner.email = user.email
    callback null, winner

emailUserTournamentResults = (winner, callback) ->
  return callback null, false if DEBUGGING and (winner.team is 'humans' or totalEmailsSent > 1)
  ++totalEmailsSent
  name = winner.name
  team = winner.team.substr(0, winner.team.length - 1)
  context =
    email_id: sendwithus.templates.greed_tournament_rank
    recipient:
      address: if DEBUGGING then 'nick@codecombat.com' else winner.email
      name: name
    email_data:
      userID: winner.userID
      name: name
      level_name: 'Greed'
      wins: winner.wins
      ties: {humans: 377, ogres: 407}[winner.team] - winner.wins - winner.losses
      losses: winner.losses
      rank: winner.rank
      team_name: team
      ladder_url: 'http://codecombat.com/play/ladder/greed#winners'
      top3: winner.rank <= 3
      top5: winner.rank <= 5
      top10: winner.rank <= 10
      top40: winner.rank <= 40
      top100: winner.rank <= 100
  sendwithus.api.send context, (err, result) ->
    return callback err if err
    callback null, winner

serverSetup.connectToDatabase()

fn = process.argv[2]
try
  eval fn + '()'
catch err
  console.log "Error running #{fn}", err
