# Middleware for handling cron scripts

errors = require '../commons/errors'
wrap = require 'co-express'
co = require 'co'
Promise = require 'bluebird'
parse = require '../commons/parse'
request = require 'request'
User = require '../models/User'
LevelSession = require '../models/LevelSession'
Classroom = require '../models/Classroom'
IsraelRegistration = require '../models/IsraelRegistration'
IsraelSolution = require '../models/IsraelSolution'
utils = require '../lib/utils'
mongoose = require 'mongoose'
sendwithus = require '../sendwithus'
config = require '../../server_config'
querystring = require 'querystring'
async = require 'async'
useragent = require 'express-useragent'

module.exports =
  checkCronAuth: (req, res, next) ->
    requestIP = req.headers['x-forwarded-for']?.replace(' ', '').split(',')[0]
    unless req.user?.isAdmin() or requestIP is config.mail.cronHandlerPublicIP or requestIP is config.mail.cronHandlerPrivateIP
      console.log "RECEIVED REQUEST FROM IP #{requestIP}(headers indicate #{req.headers['x-forwarded-for']}"
      console.log 'UNAUTHORIZED ATTEMPT TO TRIGGER CRON HANDLER'
      return next new errors.Unauthorized('Only an admin or the specified Cron handler may perform that action.')
    next()

  aggregateIsraelData: wrap (req, res, next) ->
    debugging = req.user?.isAdmin()
    unless req.features.israel
      throw new errors.Forbidden('Do not aggregate Israel data outside of Israel')
    # Query based on user.dateCreated to take advantage of index, refine by user.activity.join/createClassroom.first to find real new users - will miss any users who registered too long after creation
    userDateCreatedInterval =   14 * 24 * 60 * 60 * 1000
    # Query based on session._id date to take advantage of index, refine by session.changed to find real updated sessions - will miss any sessions completed too long after starting
    sessionDateCreatedInterval = 7 * 24 * 60 * 60 * 1000
    # Assume this function is called at this cron interval
    aggregationInterval =                  5 * 60 * 1000
    # Add some buffer time to make sure we don't miss anything between windows
    aggregationInterval +=                     30 * 1000
    userDateCreatedStartTime = new Date(new Date() - userDateCreatedInterval)
    sessionDateCreatedStartTime = new Date(new Date() - sessionDateCreatedInterval)
    lastAggregationStartTime = new Date(new Date() - aggregationInterval)
    limit = if debugging then 20 else 0

    # First, get all the sessions that have changed during the aggregation interval
    sessionQuery =
      _id: {$gte: utils.objectIdFromTimestamp(sessionDateCreatedStartTime.getTime())}
      changed: {$gte: lastAggregationStartTime}
      'state.complete': true
    sessionSelect = 'changed creator created browser level levelID dateFirstCompleted team state.complete state.difficulty code totalScore browser'
    recentSessions = yield LevelSession.find(sessionQuery).select(sessionSelect).limit(limit).lean()

    # Get all the users for those sessions, or those who first joined or created a classroom during the aggregation interval
    userIds = _.uniq (mongoose.Types.ObjectId(session.creator) for session in recentSessions)
    userQuery =
      anonymous: false
      $or: [
        {_id: {$in: userIds}}
        {dateCreated: {$gte: userDateCreatedStartTime}, 'activity.joinClassroom.first': {$gte: lastAggregationStartTime}}
        {dateCreated: {$gte: userDateCreatedStartTime}, 'activity.createClassroom.first': {$gte: lastAggregationStartTime}}
      ]
    userQuery.israelId = {$exists: true} unless debugging
    userSelect = 'dateCreated israelId stats.gamesCompleted activity.joinClassroom.first activity.createClassroom.first role lastIP'
    users = yield User.find(userQuery).select(userSelect).limit(limit).lean()

    # Get all the sessions for any new users
    newUserIds = (user._id + '' for user in users when user.activity?.joinClassroom?.first >= lastAggregationStartTime or user.activity?.createClassroom?.first >= lastAggregationStartTime)
    sessionQuery =
      creator: {$in: newUserIds}
      changed: {$lt: lastAggregationStartTime}
    oldSessionsForNewUsers = yield LevelSession.find(sessionQuery).select(sessionSelect).lean()
    sessions = recentSessions.concat oldSessionsForNewUsers

    # Get all the classrooms for all users so we can associate classCodes to users and sessions
    userIds = _.union userIds, (mongoose.Types.ObjectId(session.creator) for session in oldSessionsForNewUsers), (user._id for user in users)
    classroomQuery =
      $or: [
        {members: {$in: userIds}}
        {ownerID: {$in: userIds}}
      ]
    classroomSelect = 'members ownerID code'
    classrooms = yield Classroom.find(classroomQuery).select(classroomSelect).lean()

    # Prepare all registrations we might need to upsert
    registrations = []
    for user in users
      classroom = _.find classrooms, (classroom) ->
        (classroom.ownerID + '' is user._id + '') or
        (user._id + '') in (member + '' for member in classroom.members)
      continue unless classroom
      user.classCode = classroom.code
      registrations.push
        provider: 'CodeCombat'
        date: user.dateCreated
        user:
          userid: user._id
          usercodeil: user.israelId
          usertype: if user.role is 'student' then 'S' else 'T'
          classcode: classroom.code

    # Prepare all solutions we might need to upsert
    solutions = []
    for session in sessions
      user = _.find users, (user) -> user._id + '' is session.creator
      continue unless user and user.classCode
      code = (if session.team is 'ogres' then session.code['hero-placeholder-1']?.plan else session.code['hero-placeholder']?.plan) ? ''
      challengeId = session.level.original + (if session.team is 'ogres' then '-blue' else '')
      challengeName = session.levelID + (if session.team is 'ogres' then ' (blue)' else '')
      score = Math.round(Math.max 1, ((session.totalScore or 0) - 20) / 2, (session.state?.difficulty or 0) * 3)
      device = if session.browser then session.browser.name + (if not session.browser.desktop then ' mobile' else '') else null
      solutions.push
        provider: 'CodeCombat'
        date: session.created
        user:
          userid: user._id
          usercodeil: user.israelId
          usertype: if user.role is 'student' then 'S' else 'T'
          classcode: user.classCode
        solution:
          id: session._id
          createddate: session.created
          solutionstring: code
          challengeid: challengeId
          challengename: challengeName
          challengeorder: 1  # TODO: what is this?
          score: score
          starttime: session.created
          endtime: session.dateFirstCompleted or session.changed
        info:
          ip: user.lastIP
          sessionkey: session._id  # How to find cookie session? Need it?
          device: device
          os: session.browser?.platform
          country: 'israel'

    # TODO: figure out out to make this work with async to run, say, 5 in parallel
    for registration in registrations
      yield IsraelRegistration.findOneAndUpdate {'user.userid': registration.user.userid}, registration, upsert: true
    for solution in solutions
      yield IsraelSolution.findOneAndUpdate {'solution.id': solution.solution.id}, solution, upsert: true

    res.status(200).send({message: "Upserted #{registrations.length} registrations and #{solutions.length} solutions."})
