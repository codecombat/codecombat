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
Course = require '../models/Course'
Campaign = require '../models/Campaign'
utils = require '../lib/utils'
mongoose = require 'mongoose'
sendwithus = require '../sendwithus'
config = require '../../server_config'
querystring = require 'querystring'
async = require 'async'
Promise.promisifyAll(async)
useragent = require 'express-useragent'


# Is it better to copy these here or import them from app/core/utils?
courseOrdering = (mongoose.Types.ObjectId(id) for id in [
  '560f1a9f22961295f9427742'  # INTRODUCTION_TO_COMPUTER_SCIENCE
  '5789587aad86a6efb573701e'  # GAME_DEVELOPMENT_1
  '5789587aad86a6efb573701f'  # WEB_DEVELOPMENT_1
  '5632661322961295f9428638'  # COMPUTER_SCIENCE_2
  '57b621e7ad86a6efb5737e64'  # GAME_DEVELOPMENT_2
  '5789587aad86a6efb5737020'  # WEB_DEVELOPMENT_2
  '56462f935afde0c6fd30fc8c'  # COMPUTER_SCIENCE_3
  '5a0df02b8f2391437740f74f'  # GAME_DEVELOPMENT_3
  '56462f935afde0c6fd30fc8d'  # COMPUTER_SCIENCE_4
  '569ed916efa72b0ced971447'  # COMPUTER_SCIENCE_5
  '5817d673e85d1220db624ca4'  # COMPUTER_SCIENCE_6
])

practiceLevels = [
  'kounter-kithwise'
  'crawlways-of-kithgard'
  'illusory-interruption'
  'forgetful-gemsmith'
  'favorable-odds'
  'the-raised-sword'
  'descending-further'
  'riddling-kithmaze'
  'radiant-aura'
  'cupboards-of-kithgard-a'
  'cupboards-of-kithgard-b'
  'lowly-kithmen'
  'closing-the-distance'
  'the-skeleton'
  'the-gauntlet-a'
  'the-gauntlet-b'
  'backwoods-ambush'
  'patrol-buster-a'
  'eagle-eye'
  'backwoods-standoff-a'
  'backwoods-standoff-b'
  'the-agrippa-defense-a'
  'the-agrippa-defense-b'
  'return-to-thornbush-farm-a'
  'return-to-thornbush-farm-b'
  'buddys-name-a'
  'buddys-name-b'
]

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
    if req.hostname is 'il.codecombat.com'
      LevelSession.schema.index({changed: 1}, {name: 'oldest session index for aggregateIsraelData'})  # Blech. Don't want this index on our main server.

    limit = if debugging then 20 else 1000
    limit = parseInt(req.query.limit) if req.query.limit?

    lastSolutions = yield IsraelSolution.find({}).select('date').lean().sort('-date').limit(1)
    lastSolution = lastSolutions[0]
    console.log 'found lastSolution', lastSolution

    sessionStartDate = lastSolution?.date ? new Date(2017, 6, 1)
    console.log sessionStartDate, sessionStartDate.getTime(), utils.objectIdFromTimestamp(sessionStartDate.getTime())

    # First, get all the sessions that have changed during the aggregation interval
    sessionQuery =
      changed: {$gte: sessionStartDate}
      'state.complete': true
      isForClassroom: true
    sessionSelect = 'changed creator creatorName created browser level levelID dateFirstCompleted team state.complete state.difficulty code totalScore browser isForClassroom'
    recentSessions = yield LevelSession.find(sessionQuery).select(sessionSelect).limit(limit).lean().sort('changed')

    console.log 'found', recentSessions.length, 'sessions'

    lastRegistrations = yield IsraelRegistration.find({}).select('date').lean().sort('-date').limit(1)
    lastRegistration = lastRegistrations[0]
    console.log 'found lastRegistration', lastRegistration

    userStartDate = lastRegistration?.date ? new Date(2017, 0, 1)
    console.log userStartDate, userStartDate.getTime(), utils.objectIdFromTimestamp(userStartDate.getTime())

    if recentSessions.length
      userIds = _(recentSessions)
        .map((session) -> session.creator)
        .uniq()
        .map((creator) -> mongoose.Types.ObjectId(creator))
        .value()
      userQuery =
        anonymous: false
        $or: [
          {_id: {$in: userIds}}
          {dateCreated: {$gte: userStartDate, $lte: _.last(recentSessions).changed}, 'role': {$exists: true}}
        ]
      #console.log 'let us query', JSON.stringify(userQuery, null, 2)
      userQuery.israelId = {$exists: true} unless debugging
      userSelect = 'name dateCreated israelId stats.gamesCompleted role lastIP'
      users = yield User.find(userQuery).select(userSelect).lean()
      console.log 'users', users.length, 'from', userIds.length, 'userIds', userIds
    else
      users = []

    # Get all the classrooms for all users so we can associate classCodes to users and sessions
    userIds = _.union userIds, (user._id for user in users)
    classroomQuery =
      $or: [
        {members: {$in: userIds}}
        {ownerID: {$in: userIds}}
      ]
    classroomSelect = 'members ownerID code'
    classrooms = yield Classroom.find(classroomQuery).select(classroomSelect).lean()

    console.log "found", classrooms.length, "classrooms"

    if recentSessions.length
      courses = yield Course.find({_id: {$in: courseOrdering}}).select('campaignID').lean()
      campaignOrdering = (_.find(courses, (course) -> course._id + '' is courseId + '')?.campaignID for courseId in courseOrdering)
      campaigns = yield Campaign.find({_id: {$in: campaignOrdering}}).select('levels').lean()
      campaigns = (_.find(campaigns, (campaign) -> campaign._id + '' is campaignId + '') for campaignId in campaignOrdering)
      levelOrdering = {}
      coursesByLevel = {}
      levelIndex = 0
      for campaign in campaigns
        for levelOriginal in Object.keys campaign.levels
          levelOrdering[levelOriginal] = levelIndex++
          coursesByLevel[levelOriginal] = campaign.slug

    # Prepare all registrations we might need to upsert
    registrations = []
    for user in users
      userClassrooms = _.filter classrooms, (classroom) ->
        (classroom.ownerID + '' is user._id + '') or
        (user._id + '') in (member + '' for member in classroom.members)
      for classroom, classroomIndex in userClassrooms
        user.classCode = classroom.code  # Tag student users with a classCode for any solutions we might need to upsert
        userId = user._id
        if classroomIndex > 0
          userId += '-' + classroom.code  # Add another registration for each extra class beyond the first the teacher has made, differentiating key based on code
        registrations.push
          provider: 'CodeCombat'
          date: user.dateCreated
          user:
            userid: userId
            usercodeil: user.israelId?.replace?(/old/, '') or undefined
            usertype: if user.role is 'student' then 'S' else 'T'
            classcode: classroom.code
        if user.israelId and not user.israelId.replace
          console.log "Weird non-string israelId?", user.israelId, typeof user.israelId
        if user.role is 'student'
          break  # Don't provide multiple registrations if students are in multiple classes

    # Prepare all solutions we might need to upsert
    solutions = []
    for session in recentSessions
      user = _.find users, (u) -> u._id + '' is session.creator + '' or (u.name and u.name is session.creatorName)
      console.log 'session', session._id, session.creator, session.creatorName, session.levelID, user?.classCode
      continue unless user and user.classCode
      code = (if session.team is 'ogres' then session.code['hero-placeholder-1']?.plan else session.code['hero-placeholder']?.plan) ? ''
      challengeId = session.level.original + (if session.team is 'ogres' then '-blue' else '')
      challengeName = session.levelID + (if session.team is 'ogres' then ' (blue)' else '')
      challengeOrder = levelOrdering[session.level.original]
      challengeCategory = coursesByLevel[session.level.original] or 'other'
      if session.levelID in ['elemental-wars', 'tesla-tesoro', 'escort-duty']
        challengeCategory = 'tournament'
        otherTeam = if session.team is 'humans' then 'ogres' else 'humans'
        otherSession = yield LevelSession.findOne({level: session.level, creator: session.creator, team: otherTeam}).select(sessionSelect).lean()
        if otherSession
          otherSolution = yield IsraelSolution.findOne({solutionid: otherSession._id})
          if otherSolution
            # We are putting the solution under the other session; don't double-count
            console.log '  Avoiding storing', session.creatorName, session.levelID, session.team, 'because we are using', otherSession.team, 'instead'
            continue
          if otherSession.totalScore > session.totalScore
            console.log ' ', session.creatorName, session.levelID, session.team, 'using ', otherSession.team, 'instead because score is higher'
            session.totalScore = otherSession.totalScore
      score = 1
      if session.levelID in practiceLevels
        score = 0
      if session.totalScore and challengeCategory is 'tournament'
        score = Math.round(Math.max 1, session.totalScore - 5)  # They may cap this at 30 or 40 points. A really good score on a crowded arena might be 60-110. totalScore starts around 20, so they get positive points for improving on that. [except it apparently makes most people negative, Simple CPU sometimes, so we need to subtract less.]
      device = if session.browser then session.browser.name + (if not session.browser.desktop then ' mobile' else '') else null
      solutions.push
        # New data
        solutionid: session._id
        provider: 'CodeCombat'
        date: session.created
        userid: user._id
        usercodeil: user.israelId?.replace(/old/, '') or undefined
        classcode: user.classCode
        usertype: if user.role is 'student' then 'S' else 'T'
        solutionstring: code
        challengeid: challengeId
        challengename: challengeName
        challengeorder: challengeOrder
        score: score
        challengecategory: challengeCategory
        solutionstarttime: session.created
        solutionendtime: session.dateFirstCompleted or session.changed
        ip: user.lastIP
        sessionkey: session._id
        device: device
        os: session.browser?.platform
        country: 'israel'

    done = 0
    yield async.eachLimitAsync registrations, 10, (registration, cb) ->
      IsraelRegistration.findOneAndUpdate({'user.userid': registration.user.userid}, registration, {upsert: true}, (err, result) ->
        done += 1
#        console.log(registration.user.userid, done, 'registrations out of', registrations.length, err)
        cb(err)
      )
    done = 0
    yield async.eachLimitAsync solutions, 10, (solution, cb) ->
      IsraelSolution.findOneAndUpdate({'solutionid': solution.solutionid}, solution, {upsert: true}, (err, result) ->
        done += 1
#        console.log(solution.solutionid, done, 'solutions out of', solutions.length, err)
        cb(err)
      )

    message = "Upserted #{registrations.length} registrations from #{registrations[0]?.date} - #{_.last(registrations)?.date} and #{solutions.length} solutions from #{solutions[0]?.date} - #{_.last(solutions)?.date}."
    console.log message
    res.status(200).send({message: message})
