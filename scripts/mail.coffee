do (setupLodash = this) ->
  GLOBAL._ = require 'lodash'
  _.str = require 'underscore.string'
  _.mixin _.str.exports()

async = require 'async'

serverSetup = require '../server_setup'
sendwithus = require '../server/sendwithus'
User = require '../server/users/User.coffee'
Level = require '../server/levels/Level.coffee'
LevelSession = require '../server/levels/sessions/LevelSession.coffee'

alreadyEmailed = []

DEBUGGING = true

sendInitialRecruitingEmail = ->
  leaderboards = [
    {slug: 'brawlwood', team: 'humans', limit: 55, name: "Brawlwood", original: "52d97ecd32362bc86e004e87", majorVersion: 0}
    {slug: 'brawlwood', team: 'ogres', limit: 40, name: "Brawlwood", original: "52d97ecd32362bc86e004e87", majorVersion: 0}
    {slug: 'dungeon-arena', team: 'humans', limit: 200, name: "Dungeon Arena", original: "53173f76c269d400000543c2", majorVersion: 0}
    {slug: 'dungeon-arena', team: 'ogres', limit: 150, name: "Dungeon Arena", original: "53173f76c269d400000543c2", majorVersion: 0}
  ]
  async.waterfall [
    (callback) -> async.map leaderboards, grabSessions, callback
    (sessionLists, callback) -> async.map collapseSessions(sessionLists), grabUser, callback
    (users, callback) -> async.map users, emailUser, callback
  ], (err, results) ->
    return console.log "Error:", err if err
    console.log "Looked at sending to #{results.length} users; sent to #{_.filter(results).length}."
    console.log "Sent to: ['#{(user.email for user in results when user).join('\', \'')}']"

grabSessions = (levelInfo, callback) ->
  queryParameters =
    level: {original: levelInfo.original, majorVersion: levelInfo.majorVersion}
    team: levelInfo.team
    submitted: true
  sortParameters = totalScore: -1
  selectString = 'totalScore creator'
  query = LevelSession
    .find(queryParameters)
    .limit(levelInfo.limit)
    .sort(sortParameters)
    .select(selectString)
    .lean()
  query.exec (err, sessions) ->
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
emailUser = (user, callback) ->
  #return callback null, false if user.emails?.anyNotes?.enabled is false  # TODO: later, uncomment to obey also "anyNotes" when that's untangled
  return callback null, false if user.emails?.recruitNotes?.enabled is false
  return callback null, false if user.email in alreadyEmailed
  return callback null, false if DEBUGGING and (totalEmailsSent > 1 or Math.random() > 0.1)
  ++totalEmailsSent
  name = if user.firstName and user.lastName then "#{user.firstName}" else user.name
  name = "Wizard" if not name or name is "Anoner"
  team = user.session.levelInfo.team
  team = team.substr(0, team.length - 1)
  context =
    email_id: sendwithus.templates.one_time_recruiting_email
    recipient:
      address: if DEBUGGING then 'nick@codecombat.com' else user.email
      name: name
    email_data:
      name: name
      level_name: user.session.levelInfo.name
      place: "##{user.session.rank}"  # like "#31"
      level_race: team
  sendwithus.api.send context, (err, result) ->
    return callback err if err
    callback null, user

serverSetup.connectToDatabase()
sendInitialRecruitingEmail()
