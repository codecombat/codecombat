# Middleware for handling cron scripts

errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
parse = require '../commons/parse'
request = require 'request'
User = require '../models/User'
LevelSession = require '../models/LevelSession'
Classroom = require '../models/Classroom'
utils = require '../lib/utils'
mongoose = require 'mongoose'
sendwithus = require '../sendwithus'
config = require '../../server_config'
querystring = require 'querystring'

module.exports =
  checkCronAuth: (req, res, next) ->
    requestIP = req.headers['x-forwarded-for']?.replace(' ', '').split(',')[0]
    unless req.user?.isAdmin() or requestIP is config.mail.cronHandlerPublicIP or requestIP is config.mail.cronHandlerPrivateIP
      console.log "RECEIVED REQUEST FROM IP #{requestIP}(headers indicate #{req.headers['x-forwarded-for']}"
      console.log 'UNAUTHORIZED ATTEMPT TO TRIGGER CRON HANDLER'
      return next new errors.Unauthorized('Only an admin or the specified Cron handler may perform that action.')
    next()

  getTeachers: wrap (req, res, next) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    teacherRoles = ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent']
    users = yield User.find(anonymous: false, role: {$in: teacherRoles}).select('lastIP').lean()
    for user in users
      if ip = user.lastIP
        user.geo = geoip.lookup(ip)
        if country = user.geo?.country
          user.geo.countryName = countryList.getName(country)
    res.status(200).send(users)

  aggregateIsraelData: wrap (req, res, next) ->
    debugging = req.user?.isAdmin()
    unless debugging or req.features.israel  # TODO: remove debugging pass before committing
      throw new errors.Forbidden('Do not aggregate Israel data outside of Israel')
    # Query based on user.dateCreated to take advantage of index, refine by user.activity.join/createClassroom.first to find real new users - will miss any users who registered too long after creation
    userDateCreatedInterval =   14 * 24 * 60 * 60 * 1000
    # Query based on session._id date to take advantage of index, refine by session.changed to find real updated sessions - will miss any sessions completed too long after starting
    sessionDateCreatedInterval = 7 * 24 * 60 * 60 * 1000
    # Assume this function is called at this cron interval
    aggregationInterval =                  5 * 60 * 1000
    # Add some buffer time to make sure we don't miss anything between windows
    aggregationInterval +=                     30 * 1000
    userDateCreatedInterval *= 0.02 if debugging
    sessionDateCreatedInterval *= 0.02 if debugging
    #aggregationInterval *= 20 if debugging
    aggregationInterval *= 0.02 if debugging
    userDateCreatedStartTime = new Date(new Date() - userDateCreatedInterval)
    sessionDateCreatedStartTime = new Date(new Date() - sessionDateCreatedInterval)
    lastAggregationStartTime = new Date(new Date() - aggregationInterval)

    # First, get all the sessions that havve changed during the aggregation interval
    sessionQuery =
      _id: {$gte: utils.objectIdFromTimestamp(sessionDateCreatedStartTime.getTime())}
      changed: {$gte: lastAggregationStartTime}
    sessionSelect = 'changed creator created browser level levelID dateFirstCompleted team state.complete state.difficulty code totalScore'
    recentSessions = yield LevelSession.find(sessionQuery).select(sessionSelect).lean()

    # Get all the users for those sessions, or those who first joined or created a classroom during the aggregation interval
    userIds = (mongoose.Types.ObjectId(session.creator) for session in recentSessions)
    userQuery =
      anonymous: false
      $or: [
        {_id: {$in: userIds}}
        {dateCreated: {$gte: userDateCreatedStartTime}, 'activity.joinClassroom.first': {$gte: lastAggregationStartTime}}
        {dateCreated: {$gte: userDateCreatedStartTime}, 'activity.createClassroom.first': {$gte: lastAggregationStartTime}}
      ]
    userQuery.israelId = {$exists: true} unless debugging
    userSelect = 'dateCreated israelId stats.gamesCompleted activity.joinClassroom.first activity.createClassroom.first role lastIP'
    users = yield User.find(userQuery).select(userSelect).lean()

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
        {ownerId: {$in: userIds}}
      ]
    classroomSelect = 'members ownerId code'
    classrooms = yield Classroom.find(classroomQuery).select(classroomSelect).lean()

    # Prepare all registrations we might need to upsert
    registrations = []
    for user in users
      classroom = _.find classrooms, (classroom) -> (user._id + '') in (member + '' for member in classroom.members)
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
    console.log 'registrations!', registrations

    # Prepare all solutions we might need to upsert
    solutions = []
    for session in sessions
      user = _.find users, (user) -> user._id + '' is session.creator
      continue unless user and user.classCode and session.state?.complete
      code = (if session.team is 'ogres' then session.code['hero-placeholder-1']?.plan else session.code['hero-placeholder']?.plan) ? ''
      challengeId = session.levelID + (if session.team is 'ogres' then '-blue' else '')
      challengeName = session.levelID + (if session.team is 'ogres' then ' (blue)' else '')
      score = Math.max session.totalScore ? 1, session.state?.difficulty ? 1
      solutions.push
        provider: 'CodeCombat'
        date: session.dateFirstCompleted or session.changed  # TODO: created? changed?
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
          sessionkey: session._id  # TODO: what is this?
          #device: "ipad"  # TODO: need this?
          #os: "win10"  # TODO: need this?
          country: "israel"
    console.log 'solutions!', solutions

    # TODO: actually upsert these somewhere
    res.status(200).send({message: "Upserted #{registrations.length} registrations and #{solutions.length} solutions."})




###
registrations = [{
    "provider" :"code combat",
    "date" : "2016-11-24T10:28:25.641",
    "user" : {
        "userid" : "5836b747ac6a4f2300489123",
        "usercodeil" : "100998987",  # user's israelId
        "usertype" : "T"       # S = Student , T  = Teacher
        "classcode" : "A57YRT" # First class code created, or joined, depending on type
        "createddate" : "2016-11-24T10:28" # same as date, but less precision
      }
}]

solutions = [{
    "provider" :"code combat",
    "date" : "2016-11-24T10:28:25.641",
    "user" : {
        "userid" : "5836b747ac6a4f2300489123",
        "usercodeil" : "100998987",
        "usertype" : "S"       # S = Student , T  = Teacher
        "classcode" : "A57YRT"
    },
    "solution" : {
        "id" : "5836b747ac6a4f2300489123",
        "createddate" : "2016-11-24T10:28:25.641",
        "solutionstring" = "step 10 .......", # the raw code
        "challengeid" = "100", # CHECKING, but think level original, appended with the team string for arena level sessions, perhaps "-humans"
        "challengename" = "challenge 100", # CHECKING
        "challengeorder" = 1, # CHECKING
        "score" : 2
        "starttime" : "2016-11-24T10:28:25.641" # session created
        "endtime" :  "2016-11-24T10:28:25.641" # dateFirstCompleted
    },
    "info" : {
        "ip" : "192.234.17.1",
        "sessionkey" : "5836b747ac6a4f2300489194" ,
        "device" : "ipad",
        "os" : "win10",
        "country" : "israel"
     }
}]
###
