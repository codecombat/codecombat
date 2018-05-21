errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
AnalyticsLogEvent = require '../models/AnalyticsLogEvent'
TrialRequest = require '../models/TrialRequest'
Campaign = require '../models/Campaign'
CourseInstance = require '../models/CourseInstance'
Classroom = require '../models/Classroom'
Course = require '../models/Course'
User = require '../models/User'
Level = require '../models/Level'
LevelSession = require '../models/LevelSession'
parse = require '../commons/parse'
{objectIdFromTimestamp} = require '../lib/utils'
utils = require '../../app/core/utils'
Prepaid = require '../models/Prepaid'

module.exports =
  addMembers: wrap (req, res) ->
    if req.body.userID
      userIDs = [req.body.userID]
    else if req.body.userIDs
      userIDs = req.body.userIDs
    else
      throw new errors.UnprocessableEntity('Must provide userID or userIDs')

    for userID in userIDs
      unless _.all userIDs, database.isID
        throw new errors.UnprocessableEntity('Invalid list of user IDs')

    courseInstance = yield database.getDocFromHandle(req, CourseInstance)
    if not courseInstance
      throw new errors.NotFound('Course Instance not found.')
    courseId = courseInstance.get('courseID')

    classroom = yield Classroom.findById courseInstance.get('classroomID')
    if not classroom
      throw new errors.NotFound('Classroom not found.')

    classroomMembers = (userID.toString() for userID in classroom.get('members'))
    unless _.all(userIDs, (userID) -> _.contains classroomMembers, userID)
      throw new errors.Forbidden('Users must be members of classroom')

    ownsClassroom = classroom.get('ownerID').equals(req.user._id)
    addingSelf = userIDs.length is 1 and userIDs[0] is req.user.id
    unless ownsClassroom or addingSelf
      throw new errors.Forbidden('You must own the classroom to add members')

    course = yield Course.findById courseId
    throw new errors.NotFound('Course referenced by course instance not found') unless course

    # Only the enrolled users
    users = yield User.find({ _id: { $in: userIDs }}).select('coursePrepaid coursePrepaidID') # TODO: remove coursePrepaidID once migrated
    userPrepaidsIncludeCourse = _.all((user.prepaidIncludesCourse(course) for user in users))

    if not (course.get('free') or userPrepaidsIncludeCourse)
      throw new errors.PaymentRequired('Cannot add users to a course instance until they are added to a prepaid that includes this course')

    # Update the course to latest if nobody is in it yet
    unless courseInstance.get('members')?.length
      {oldCourseCount, newCourseCount, oldLevelCount, newLevelCount} = yield classroom.setUpdatedCourse({courseId})
      database.validateDoc(classroom)
      yield classroom.save()
      if newCourseCount > oldCourseCount or newLevelCount > oldLevelCount
        # TODO: capture level updates that do not increase the level count
        AnalyticsLogEvent.logEvent(req.user._id, 'Classroom Autoupdate Course', {
          classroomId: classroom.get('_id')
          courseId, oldCourseCount, newCourseCount, oldLevelCount, newLevelCount
        })

    userObjectIDs = (mongoose.Types.ObjectId(userID) for userID in userIDs)

    courseInstance = yield CourseInstance.findByIdAndUpdate(
      courseInstance._id,
      { $addToSet: { members: { $each: userObjectIDs } } }
      { new: true }
    )

    userUpdateResult = yield User.update(
      { _id: { $in: userObjectIDs } },
      { $addToSet: { courseInstances: courseInstance._id } }
    )

    res.status(200).send(courseInstance.toObject({ req }))

  removeMembers: wrap (req, res) ->
    if req.body.userID
      userIDs = [req.body.userID]
    else if req.body.userIDs
      userIDs = req.body.userIDs
    else
      throw new errors.UnprocessableEntity('Must provide userID or userIDs')

    for userID in userIDs
      unless _.all userIDs, database.isID
        throw new errors.UnprocessableEntity('Invalid list of user IDs')

    courseInstance = yield database.getDocFromHandle(req, CourseInstance)
    if not courseInstance
      throw new errors.NotFound('Course Instance not found.')
    courseId = courseInstance.get('courseID')

    classroom = yield Classroom.findById courseInstance.get('classroomID')
    if not classroom
      throw new errors.NotFound('Classroom not found.')

    classroomMembers = (userID.toString() for userID in classroom.get('members'))
    unless _.all(userIDs, (userID) -> _.contains classroomMembers, userID)
      throw new errors.Forbidden('Users must be members of classroom')

    ownsClassroom = classroom.get('ownerID').equals(req.user._id)
    removingSelf = userIDs.length is 1 and userIDs[0] is req.user.id
    unless ownsClassroom or removingSelf
      throw new errors.Forbidden('You must own the classroom to remove members')

    course = yield Course.findById courseId
    throw new errors.NotFound('Course referenced by course instance not found') unless course

    userObjectIDs = (mongoose.Types.ObjectId(userID) for userID in userIDs)

    courseInstance = yield CourseInstance.findByIdAndUpdate(
      courseInstance._id,
      { $pull: { members: { $in: userObjectIDs } } }
      { new: true }
    )

    userUpdateResult = yield User.update(
      { _id: { $in: userObjectIDs } },
      { $pull: { courseInstances: courseInstance._id } }
    )

    res.status(200).send(courseInstance.toObject({ req }))

  fetchNextLevels: wrap (req, res) ->
    unless req.user? then return res.status(200).send({})
    levelOriginal = req.params.levelOriginal
    unless database.isID(levelOriginal) then throw new errors.UnprocessableEntity('Invalid level original ObjectId')
    sessionID = req.params.sessionID
    unless database.isID(sessionID) then throw new errors.UnprocessableEntity('Invalid session ObjectId')
    courseInstance = yield database.getDocFromHandle(req, CourseInstance)
    unless courseInstance then throw new errors.NotFound('Course Instance not found.')
    classroom = yield Classroom.findById courseInstance.get('classroomID')
    unless classroom then throw new errors.NotFound('Classroom not found.')
    currentLevel = yield Level.findOne({original: mongoose.Types.ObjectId(levelOriginal)}, {practiceThresholdMinutes: 1, type: 1, assessment: 1})
    unless currentLevel then throw new errors.NotFound('Current level not found.')

    courseID = courseInstance.get('courseID')
    courseLevels = []
    courseLevels = course.levels for course in classroom.get('courses') or [] when courseID.equals(course._id)
    classLanguage = classroom.get('aceConfig')?.language
    _.remove(courseLevels, (level) -> level.primerLanguage is classLanguage) if classLanguage

    # Get level completions and playtime
    # Build one query for each language that's included in this course
    currentLevelSession = null
    queries = []
    groups = _.groupBy(courseLevels, (l) -> l.primerLanguage or classroom.get('aceConfig.language'))
    project = {level: 1, playtime: 1, state: 1}
    for codeLanguage, levelsGroup of groups
      levelIDs = (level.original.toString() for level in levelsGroup)
      while levelIDs.length
        # chunk queries
        subset = levelIDs.splice(0, 10)
        queries.push(LevelSession.find({$and: [
          {creator: req.user.id},
          {'level.original': {$in: subset}}
          {codeLanguage}
        ]}, project))
    levelSessions = _.flatten(yield queries)
    levelCompleteMap = {}

    for levelSession in levelSessions
      currentLevelSession = levelSession if levelSession.id is sessionID
      levelCompleteMap[levelSession.get('level')?.original] = levelSession.get('state')?.complete
    unless currentLevelSession then throw new errors.NotFound('Level session not found.')
    needsPractice = if currentLevel.get('type') in ['course-ladder', 'ladder'] then false
    else if currentLevel.get('assessment') then false
    else utils.needsPractice(currentLevelSession.get('playtime'), currentLevel.get('practiceThresholdMinutes'))

    # Find next level and assessment
    levels = []
    currentIndex = -1
    for level, index in courseLevels
      currentIndex = index if level.original.toString() is levelOriginal
      levels.push
        assessment: level.assessment ? false
        practice: level.practice ? false
        complete: levelCompleteMap[level.original?.toString()] or currentIndex is index
    unless currentIndex >= 0 then throw new errors.NotFound('Level original ObjectId not found in Classroom courses')
    nextLevelIndex = utils.findNextLevel(levels, currentIndex, needsPractice)
    nextLevelOriginal = courseLevels[nextLevelIndex]?.original
    nextAssessmentIndex = utils.findNextAssessmentForLevel(levels, currentIndex, needsPractice)
    nextAssessmentOriginal = courseLevels[nextAssessmentIndex]?.original
    unless nextLevelOriginal then return res.status(200).send({
      level: {}
      assessment: {}
    })

    level = {}
    if nextLevelOriginal
      # Fetch full Level object
      dbq = Level.findOne({original: mongoose.Types.ObjectId(nextLevelOriginal)})
      dbq.sort({ 'version.major': -1, 'version.minor': -1 })
      dbq.select(parse.getProjectFromReq(req))
      level = yield dbq
      level = level.toObject({req: req})

    assessment = {}
    if nextAssessmentOriginal
      # Fetch full Assessment Level object
      dbq = Level.findOne({original: mongoose.Types.ObjectId(nextAssessmentOriginal)})
      dbq.sort({ 'version.major': -1, 'version.minor': -1 })
      dbq.select(parse.getProjectFromReq(req))
      assessment = yield dbq
      assessment = assessment.toObject({req: req})

    res.status(200).send({ level, assessment })

  fetchClassroom: wrap (req, res) ->
    courseInstance = yield database.getDocFromHandle(req, CourseInstance)
    if not courseInstance
      throw new errors.NotFound('Course Instance not found.')

    classroom = yield Classroom.findById(courseInstance.get('classroomID')).select(parse.getProjectFromReq(req))
    if not classroom
      throw new errors.NotFound('Classroom not found.')

    isOwner = classroom.get('ownerID')?.equals req.user?._id
    isMember = _.any(classroom.get('members') or [], (memberID) -> memberID.equals(req.user.get('_id')))
    if not (isOwner or isMember)
      throw new errors.Forbidden('You do not have access to this classroom')

    classroom = classroom.toObject({req: req})

    res.status(200).send(classroom)


  fetchCourse: wrap (req, res) ->
    courseInstance = yield database.getDocFromHandle(req, CourseInstance)
    if not courseInstance
      throw new errors.NotFound('Course Instance not found.')

    course = yield Course.findById(courseInstance.get('courseID')).select(parse.getProjectFromReq(req))
    if not course
      throw new errors.NotFound('Course not found.')

    res.status(200).send(course.toObject({req: req}))


  fetchRecent: wrap (req, res) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()

    courses = yield Course.find({releasePhase: 'released'}).select({_id: 1}).lean()
    courseIDs = (course._id for course in courses)

    query = {$and: [{courseID: {$in: courseIDs}}, {name: {$ne: 'Single Player'}}, {hourOfCode: {$ne: true}}]}
    query["$and"].push(_id: {$gte: objectIdFromTimestamp(req.body.startDay + "T00:00:00.000Z")}) if req.body.startDay?
    query["$and"].push(_id: {$lt: objectIdFromTimestamp(req.body.endDay + "T00:00:00.000Z")}) if req.body.endDay?
    courseInstances = yield CourseInstance.find(query, {courseID: 1, members: 1, ownerID: 1}).lean()

    userIDs = []
    for courseInstance in courseInstances
      if members = courseInstance.members
        userIDs.push(userID) for userID in members
    users = yield User.find({_id: {$in: userIDs}, coursePrepaid: {$exists: true}}, {coursePrepaid: 1}).lean()

    prepaidIDs = (user.coursePrepaid._id for user in users when user.coursePrepaid)
    prepaids = yield Prepaid.find({_id: {$in: prepaidIDs}}, {properties: 1}).lean()

    res.send({
      courseInstances: courseInstances
      students: users
      prepaids: prepaids
    })

  fetchNonHoc: wrap (req, res) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    limit = parseInt(req.query.options?.limit ? 0)
    query = {$and: [{name: {$ne: 'Single Player'}}, {hourOfCode: {$ne: true}}]}
    if req.query.options?.beforeId
      beforeId = mongoose.Types.ObjectId(req.query.options.beforeId)
      query.$and.push({_id: {$lt: beforeId}})
    courseInstances = yield CourseInstance.find(query, { members: 1, ownerID: 1}).sort({_id: -1}).limit(limit).lean()
    res.status(200).send(courseInstances)

  fetchCourseLevelSessions: wrap (req, res) ->
    courseInstance = yield database.getDocFromHandle(req, CourseInstance)
    if not courseInstance
      throw new errors.NotFound('Course Instance not found.')

    classroom = yield Classroom.findById(courseInstance.get('classroomID'))
    if not classroom
      throw new errors.NotFound('Classroom not found.')

    userID = req.params.userID or req.user.id
    unless userID is req.user.id or courseInstance.get('ownerID').equals(req.user.id) or req.user.isAdmin()
    # TODO: grant access to certain projected data to any requestor so that anyone can still view data for certificates if given the certificate URL
      throw new errors.Forbidden('You must be a member of a the given course instance')

    # Construct a query for finding all sessions appropriate for the given course instance and related
    # classroom. For the most part, that means sessions that match the language of the classroom, but for
    # primer levels, need to use the level primerLanguage setting. Each $or entry is for one level session.
    $or = []
    for course in classroom.get('courses') when course._id.equals(courseInstance.get('courseID'))
      for level in course.levels when not _.contains(level.type, 'ladder')
        $or.push({
          'level.original': level.original + "",
          codeLanguage: level.primerLanguage or classroom.get('aceConfig.language')
        })
    if $or.length
      query = {$and: [
        {creator: userID},
        { $or }
      ]}
      levelSessions = yield LevelSession.find(query).setOptions({maxTimeMS:5000}).select(parse.getProjectFromReq(req))
      res.send(session.toObject({req}) for session in levelSessions)
    else
      res.send []

  fetchPeerProjects: wrap (req, res) ->
    courseInstance = yield database.getDocFromHandle(req, CourseInstance)
    if not courseInstance
      throw new errors.NotFound('Course Instance not found.')

    unless courseInstance.get('ownerID').equals(req.user._id) or _.any(courseInstance.get('members'), (id) -> id.equals req.user._id)
      throw new errors.Forbidden('You must be a member of a the given course instance')

    classroom = yield Classroom.findById(courseInstance.get('classroomID'))
    if not classroom
      throw new errors.NotFound('Classroom not found.')

    levelOriginalQueries = []
    for course in classroom.get('courses') when course._id.equals(courseInstance.get('courseID'))
      for level in course.levels when level.shareable is 'project'
        levelOriginalQueries.push({
          'level.original': level.original + '',
          codeLanguage: classroom.get('aceConfig.language')
        })

    if levelOriginalQueries.length > 0
      query = {$and: [
        { creator: { $in: courseInstance.get('members').map((s) -> s + '') } },
        { $or: levelOriginalQueries },
        { published: true }
      ]}
      levelSessions = yield LevelSession.find(query).select(parse.getProjectFromReq(req))
      res.send(session.toObject({req}) for session in levelSessions)
    else
      res.send []
