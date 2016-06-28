errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
TrialRequest = require '../models/TrialRequest'
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

    # Only the enrolled users
    users = yield User.find({ _id: { $in: userIDs }}).select('coursePrepaid coursePrepaidID') # TODO: remove coursePrepaidID once migrated
    usersAreEnrolled = _.all((user.isEnrolled() for user in users))

    course = yield Course.findById courseInstance.get('courseID')
    throw new errors.NotFound('Course referenced by course instance not found') unless course

    if not (course.get('free') or usersAreEnrolled)
      throw new errors.PaymentRequired('Cannot add users to a course instance until they are added to a prepaid')

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


  fetchNextLevel: wrap (req, res) ->
    unless req.user? then return res.status(200).send({})
    levelOriginal = req.params.levelOriginal
    unless database.isID(levelOriginal) then throw new errors.UnprocessableEntity('Invalid level original ObjectId')
    sessionID = req.params.sessionID
    unless database.isID(sessionID) then throw new errors.UnprocessableEntity('Invalid session ObjectId')
    courseInstance = yield database.getDocFromHandle(req, CourseInstance)
    unless courseInstance then throw new errors.NotFound('Course Instance not found.')
    classroom = yield Classroom.findById courseInstance.get('classroomID')
    unless classroom then throw new errors.NotFound('Classroom not found.')
    currentLevel = yield Level.findOne({original: mongoose.Types.ObjectId(levelOriginal)}, {practiceThresholdMinutes: 1, type: 1})
    unless currentLevel then throw new errors.NotFound('Current level not found.')

    courseID = courseInstance.get('courseID')
    courseLevels = []
    courseLevels = course.levels for course in classroom.get('courses') or [] when courseID.equals(course._id)

    # Get level completions and playtime
    currentLevelSession = null
    levelIDs = (level.original.toString() for level in courseLevels)
    query = {$and: [{creator: req.user.id}, {'level.original': {$in: levelIDs}}]}
    levelSessions = yield LevelSession.find(query, {level: 1, playtime: 1, state: 1})
    levelCompleteMap = {}
    for levelSession in levelSessions
      currentLevelSession = levelSession if levelSession.id is sessionID
      levelCompleteMap[levelSession.get('level')?.original] = levelSession.get('state')?.complete
    unless currentLevelSession then throw new errors.NotFound('Level session not found.') 
    needsPractice = utils.needsPractice(currentLevelSession.get('playtime'), currentLevel.get('practiceThresholdMinutes'))

    # Find next level
    levels = []
    currentIndex = -1
    for level, index in courseLevels
      currentIndex = index if level.original.toString() is levelOriginal
      levels.push
        practice: level.practice ? false
        complete: levelCompleteMap[level.original?.toString()] or currentIndex is index
    unless currentIndex >=0 then throw new errors.NotFound('Level original ObjectId not found in Classroom courses')
    nextLevelIndex = utils.findNextLevel(levels, currentIndex, needsPractice)
    nextLevelOriginal = courseLevels[nextLevelIndex]?.original
    unless nextLevelOriginal then return res.status(200).send({})

    # Return full Level object
    dbq = Level.findOne({original: mongoose.Types.ObjectId(nextLevelOriginal)})
    dbq.sort({ 'version.major': -1, 'version.minor': -1 })
    dbq.select(parse.getProjectFromReq(req))
    level = yield dbq
    level = level.toObject({req: req})
    res.status(200).send(level)

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


  fetchRecent: wrap (req, res) ->
    query = {$and: [{name: {$ne: 'Single Player'}}, {hourOfCode: {$ne: true}}]}
    query["$and"].push(_id: {$gte: objectIdFromTimestamp(req.body.startDay + "T00:00:00.000Z")}) if req.body.startDay?
    query["$and"].push(_id: {$lt: objectIdFromTimestamp(req.body.endDay + "T00:00:00.000Z")}) if req.body.endDay?
    courseInstances = yield CourseInstance.find(query, {courseID: 1, members: 1, ownerID: 1})

    userIDs = []
    for courseInstance in courseInstances
      if members = courseInstance.get('members')
        userIDs.push(userID) for userID in members
    users = yield User.find({_id: {$in: userIDs}}, {coursePrepaid: 1, coursePrepaidID: 1})

    prepaidIDs = []
    for user in users
      if prepaidID = user.get('coursePrepaid')
        prepaidIDs.push(prepaidID._id)
    prepaids = yield Prepaid.find({_id: {$in: prepaidIDs}}, {properties: 1})

    res.send({
      courseInstances: (courseInstance.toObject({req: req}) for courseInstance in courseInstances)
      students: (user.toObject({req: req}) for user in users)
      prepaids: (prepaid.toObject({req: req}) for prepaid in prepaids)
    })

  fetchNonHoc: wrap (req, res) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    query = {$and: [{name: {$ne: 'Single Player'}}, {hourOfCode: {$ne: true}}]}
    courseInstances = yield CourseInstance.find(query, { members: 1, ownerID: 1}).lean()
    res.status(200).send(courseInstances)
