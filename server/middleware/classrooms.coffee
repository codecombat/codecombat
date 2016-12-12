_ = require 'lodash'
utils = require '../lib/utils'
errors = require '../commons/errors'
schemas = require '../../app/schemas/schemas'
wrap = require 'co-express'
log = require 'winston'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
Classroom = require '../models/Classroom'
Course = require '../models/Course'
Campaign = require '../models/Campaign'
Level = require '../models/Level'
parse = require '../commons/parse'
LevelSession = require '../models/LevelSession'
User = require '../models/User'
CourseInstance = require '../models/CourseInstance'
TrialRequest = require '../models/TrialRequest'
sendwithus = require '../sendwithus'
co = require 'co'

module.exports =
  fetchByCode: wrap (req, res, next) ->
    code = req.query.code
    return next() unless req.query.hasOwnProperty('code')
    classroom = yield Classroom.findOne({ code: code.toLowerCase().replace(RegExp(' ', 'g') , '') }).select('name ownerID aceConfig')
    if not classroom
      log.debug("classrooms.fetchByCode: Couldn't find Classroom with code: #{code}")
      throw new errors.NotFound('Classroom not found.')
    classroom = classroom.toObject()
    # Tack on the teacher's name for display to the user
    owner = (yield User.findOne({ _id: mongoose.Types.ObjectId(classroom.ownerID) }).select('name')).toObject()
    res.status(200).send({ data: classroom, owner } )

  getByOwner: wrap (req, res, next) ->
    options = req.query
    ownerID = options.ownerID
    return next() unless ownerID
    throw new errors.UnprocessableEntity('Bad ownerID') unless utils.isID ownerID
    throw new errors.Unauthorized() unless req.user
    unless req.user.isAdmin() or ownerID is req.user.id
      log.debug("classrooms.getByOwner: Can't fetch classroom you don't own. User: #{req.user.id}  Owner: #{ownerID}")
      throw new errors.Forbidden('"ownerID" must be yourself')
    sanitizedOptions = {}
    unless _.isUndefined(options.archived)
      # Handles when .archived is true, vs false-or-null
      sanitizedOptions.archived = { $ne: not (options.archived is 'true') }
    dbq = Classroom.find _.merge sanitizedOptions, { ownerID: mongoose.Types.ObjectId(ownerID) }
    dbq.select(parse.getProjectFromReq(req))
    classrooms = yield dbq
    classrooms = (classroom.toObject({req: req}) for classroom in classrooms)
    res.status(200).send(classrooms)

  fetchAllLevels: wrap (req, res, next) ->
    classroom = yield database.getDocFromHandle(req, Classroom)
    if not classroom
      throw new errors.NotFound('Classroom not found.')

    levelOriginals = []
    for course in classroom.get('courses') or []
      for level in course.levels
        levelOriginals.push(level.original)

    query = {$and: [
      {original: { $in: levelOriginals }}
      {$or: [{primerLanguage: {$exists: false}}, {primerLanguage: { $ne: classroom.get('aceConfig')?.language }}]}
      {slug: { $exists: true }}
    ]}
    levels = yield Level.find(query).select(parse.getProjectFromReq(req))
    levels = (level.toObject({ req: req }) for level in levels)

    # maintain course order
    levelMap = {}
    for level in levels
      levelMap[level.original] = level
    levels = (levelMap[levelOriginal.toString()] for levelOriginal in levelOriginals)

    res.status(200).send(_.filter(levels)) # for dev server where not all levels will be found

  fetchLevelsForCourse: wrap (req, res) ->
    classroom = yield database.getDocFromHandle(req, Classroom)
    if not classroom
      throw new errors.NotFound('Classroom not found.')

    levelOriginals = []
    for course in classroom.get('courses') or []
      if course._id.toString() isnt req.params.courseID
        continue
      for level in course.levels
        levelOriginals.push(level.original)

    query = {$and: [
      {original: { $in: levelOriginals }}
      {$or: [{primerLanguage: {$exists: false}}, {primerLanguage: { $ne: classroom.get('aceConfig')?.language }}]}
      {slug: { $exists: true }}
    ]}
    levels = yield Level.find(query).select(parse.getProjectFromReq(req))
    levels = (level.toObject({ req: req }) for level in levels)

    # maintain course order
    levelMap = {}
    for level in levels
      levelMap[level.original] = level
    levels = (levelMap[levelOriginal.toString()] for levelOriginal in levelOriginals when levelMap[levelOriginal.toString()])

    res.status(200).send(levels)

  fetchMemberSessions: wrap (req, res, next) ->
    # Return member sessions for assigned courses
    throw new errors.Unauthorized() unless req.user
    classroom = yield database.getDocFromHandle(req, Classroom)
    throw new errors.NotFound('Classroom not found.') if not classroom
    throw new errors.Forbidden('You do not own this classroom.') unless req.user.isAdmin() or classroom.get('ownerID').equals(req.user._id)
    courseLevelsMap = {}
    codeLanguage = classroom.get('aceConfig.language')
    for course in classroom.get('courses') ? []
      courseLevelsMap[course._id.toHexString()] = _.map(course.levels, (l) ->
        {'level.original':l.original?.toHexString(), codeLanguage: l.primerLanguage or codeLanguage}
      )
    courseInstances = yield CourseInstance.find({classroomID: classroom._id}).select('_id courseID members').lean()
    memberCoursesMap = {}
    for courseInstance in courseInstances
      for userID in courseInstance.members ? []
        memberCoursesMap[userID.toHexString()] ?= []
        memberCoursesMap[userID.toHexString()].push(courseInstance.courseID)
    memberLimit = parse.getLimitFromReq(req, {default: 10, max: 100, param: 'memberLimit'})
    memberSkip = parse.getSkipFromReq(req, {param: 'memberSkip'})
    members = classroom.get('members') or []
    members = members.slice(memberSkip, memberSkip + memberLimit)
    dbqs = []
    select = 'state.complete level creator playtime changed created dateFirstCompleted submitted'
    for member in members
      $or = []
      for courseID in memberCoursesMap[member.toHexString()] ? []
        for subQuery in courseLevelsMap[courseID.toHexString()] ? []
          $or.push(_.assign({creator: member.toHexString()}, subQuery))
      if $or.length
        query = { $or }
        dbqs.push(LevelSession.find(query).select(select).lean().exec())
    results = yield dbqs
    sessions = _.flatten(results)
    res.status(200).send(sessions)

  fetchMembers: wrap (req, res, next) ->
    throw new errors.Unauthorized() unless req.user
    memberLimit = parse.getLimitFromReq(req, {default: 10, max: 100, param: 'memberLimit'})
    memberSkip = parse.getSkipFromReq(req, {param: 'memberSkip'})
    classroom = yield database.getDocFromHandle(req, Classroom)
    throw new errors.NotFound('Classroom not found.') if not classroom
    isOwner = classroom.get('ownerID').equals(req.user._id)
    isMember = req.user.id in (m.toString() for m in classroom.get('members'))
    unless req.user.isAdmin() or isOwner or isMember
      log.debug "classrooms.fetchMembers: Can't fetch members for class (#{classroom.id}) you (#{req.user.id}) don't own and aren't a member of."
      throw new errors.Forbidden('You do not own this classroom.')
    memberIDs = classroom.get('members') or []
    memberIDs = memberIDs.slice(memberSkip, memberSkip + memberLimit)

    members = yield User.find({ _id: { $in: memberIDs }}).select(parse.getProjectFromReq(req))
    # members = yield User.find({ _id: { $in: memberIDs }, deleted: { $ne: true }}).select(parse.getProjectFromReq(req))
    memberObjects = (member.toObject({ req: req, includedPrivates: ["name", "email", "firstName", "lastName"] }) for member in members)

    res.status(200).send(memberObjects)

  fetchPlaytimes: wrap (req, res, next) ->
    # For given courseID, returns array of course/level IDs and slugs, and an array of recent level sessions
    # TODO: returns on this are pretty weird, because the client calls it repeatedly for more data
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    sessionLimit = parseInt(req.query?.sessionLimit ? 1000)
    unless startDay = req.query?.startDay
      startDay = new Date()
      startDay.setUTCDate(startDay.getUTCDate() - 1)
      startDay = startDay.toISOString().substring(0, 10)
    endDay = req.query?.endDay
    # console.log "DEBUG: fetchPlaytimes courseID=#{req.query?.courseID} startDay=#{startDay} endDay=#{endDay}"

    query = {$and: [{releasePhase: 'released'}]}
    query.$and.push {_id: req.query.courseID} if req.query?.courseID?
    courses = yield Course.find(query, {campaignID: 1, slug: 1}).lean()
    campaignIDs = []
    campaignCourseMap = {}
    for course in courses
      campaignIDs.push(course.campaignID)
      campaignCourseMap[course.campaignID] = course
    campaigns = yield Campaign.find({_id: {$in: campaignIDs}}, {levels: 1, slug: 1}).lean()
    courseLevelPlaytimes = []
    levelOriginals = []
    levelSlugMap = {}
    for campaign in campaigns
      for levelOriginal, level of campaign.levels
        levelOriginals.push(levelOriginal)
        levelSlugMap[levelOriginal] = level.slug
        unless level.campaignIndex?
          log.debug "NO level.campaignIndex for #{campaignCourseMap[campaign._id].slug} #{level.slug}"
        courseLevelPlaytimes.push
          courseID: campaignCourseMap[campaign._id]._id
          courseSlug: campaignCourseMap[campaign._id].slug
          levelIndex: level.campaignIndex
          levelSlug: level.slug
          levelOriginal: levelOriginal
          practice: level.practice ? false
    # console.log "DEBUG: courseID=#{req.query?.courseID} total levels=#{levelOriginals.length}"

    query = {$and: [
      {_id: {$gte: utils.objectIdFromTimestamp(startDay + "T00:00:00.000Z")}}
      {'level.original': {$in: levelOriginals}}
      {heroConfig: {$exists: false}}
      {'state.complete': true}
      ]}
    query.$and.push({_id: {$lt: utils.objectIdFromTimestamp(endDay + "T00:00:00.000Z")}}) if endDay
    project = {'level.original': 1, playtime: 1}
    levelSessions = yield LevelSession.find(query, project).lean()
    # console.log "DEBUG: courseID=#{req.query?.courseID} level sessions=#{levelSessions.length}"

    levelCountMap = {}
    minimalLevelSessions = []
    for levelSession in levelSessions
      continue if levelCountMap[levelSession.level.original] >= sessionLimit
      levelCountMap[levelSession.level.original] ?= 0
      levelCountMap[levelSession.level.original]++
      minimalLevelSessions.push(levelSession)
    res.status(200).send([courseLevelPlaytimes, minimalLevelSessions])

  post: wrap (req, res) ->
    throw new errors.Unauthorized() unless req.user and not req.user.isAnonymous()
    unless req.user?.isTeacher()
      log.debug "classrooms.post: Can't create classroom if you (#{req.user?.id}) aren't a teacher."
      throw new errors.Forbidden()
    classroom = database.initDoc(req, Classroom)
    classroom.set 'ownerID', req.user._id
    classroom.set 'members', []
    database.assignBody(req, classroom)

    yield classroom.setUpdatedCourses({isAdmin: req.user?.isAdmin(), addNewCoursesOnly: false})

    # finish
    database.validateDoc(classroom)
    classroom = yield classroom.save()
    res.status(201).send(classroom.toObject({req: req}))

  updateCourses: wrap (req, res) ->
    throw new errors.Unauthorized() unless req.user and not req.user.isAnonymous()
    classroom = yield database.getDocFromHandle(req, Classroom)
    if not classroom
      throw new errors.NotFound('Classroom not found.')
    unless req.user._id.equals(classroom.get('ownerID')) or req.user.isAdmin()
      throw new errors.Forbidden('Only the owner may update their classroom content')
    addNewCoursesOnly = req.body?.addNewCoursesOnly ? false

    # make sure updates are based on owner, not logged in user
    if not req.user._id.equals(classroom.get('ownerID'))
      owner = yield User.findById(classroom.get('ownerID'))
    else
      owner = req.user

    yield classroom.setUpdatedCourses({isAdmin: owner.isAdmin(), addNewCoursesOnly})

    database.validateDoc(classroom)
    classroom = yield classroom.save()
    res.status(200).send(classroom.toObject({req: req}))

  join: wrap (req, res) ->
    unless req.body?.code
      throw new errors.UnprocessableEntity('Need a code')
    if req.user.isTeacher()
      log.debug("classrooms.join: Cannot join a classroom as a teacher: #{req.user.id}")
      throw new errors.Forbidden('Cannot join a classroom as a teacher')
    code = req.body.code.toLowerCase().replace(RegExp(' ', 'g'), '')
    classroom = yield Classroom.findOne({code: code})
    if not classroom
      log.debug("classrooms.join: Classroom not found with code #{code}")
      throw new errors.NotFound("Classroom not found with code #{code}")
    yield classroom.addMember(req.user)

    # make user role student
    if not req.user.get('role')
      req.user.set('role', 'student')
      yield req.user.save()

    # join any course instances for free courses in the classroom
    courseIDs = (course._id for course in classroom.get('courses'))
    courses = yield Course.find({_id: {$in: courseIDs}, free: true})
    freeCourseIDs = (course._id for course in courses)
    freeCourseInstances = yield CourseInstance.find({ classroomID: classroom._id, courseID: {$in: freeCourseIDs} }).select('_id')
    freeCourseInstanceIDs = (courseInstance._id for courseInstance in freeCourseInstances)
    yield CourseInstance.update({_id: {$in: freeCourseInstanceIDs}}, { $addToSet: { members: req.user._id }})
    yield User.update({ _id: req.user._id }, { $addToSet: { courseInstances: { $each: freeCourseInstanceIDs } } })
    res.send(classroom.toObject({req: req}))

  setStudentPassword: wrap (req, res, next) ->
    newPassword = req.body.password
    { classroomID, memberID } = req.params
    teacherID = req.user.id
    return next() if teacherID is memberID or not newPassword
    ownedClassrooms = yield Classroom.find({ ownerID: mongoose.Types.ObjectId(teacherID) })
    ownedStudentIDs = _.flatten ownedClassrooms.map (c) ->
      c.get('members').map (id) ->
        id.toString()
    unless memberID in ownedStudentIDs
      throw new errors.Forbidden("Can't reset the password of a student that's not in one of your classrooms.")
    student = yield User.findById(memberID)
    if student.get('emailVerified')
      log.debug "classrooms.setStudentPassword: Can't reset password for a student (#{memberID}) that has verified their email address."
      throw new errors.Forbidden("Can't reset password for a student that has verified their email address.")
    { valid, error } = tv4.validateResult(newPassword, schemas.passwordString)
    unless valid
      throw new errors.UnprocessableEntity(error.message)
    yield student.update({ $set: { passwordHash: User.hashPassword(newPassword) } })
    res.status(200).send({})

  inviteMembers: wrap (req, res) ->
    if not req.body.emails
      log.debug "classrooms.inviteMembers: No emails included in request: #{JSON.stringify(req.body)}"
      throw new errors.UnprocessableEntity('Emails not included')

    classroom = yield database.getDocFromHandle(req, Classroom)
    if not classroom
      throw new errors.NotFound('Classroom not found.')

    unless classroom.get('ownerID').equals(req.user?._id)
      log.debug "classroom_handler.inviteMembers: Can't invite to classroom (#{classroom.id}) you (#{req.user.get('_id')}) don't own"
      throw new errors.Forbidden('Must be owner of classroom to send invites.')

    for email in req.body.emails
      joinCode = (classroom.get('codeCamel') or classroom.get('code'))
      context =
        email_id: sendwithus.templates.course_invite_email
        recipient:
          address: email
        email_data:
          teacher_name: req.user.broadName()
          class_name: classroom.get('name')
          join_link: "https://codecombat.com/students?_cc=" + joinCode
          join_code: joinCode
      sendwithus.api.send context, _.noop

    res.status(200).send({})

  getUsers: wrap (req, res, next) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    classrooms = yield Classroom.find().select('ownerID members').lean()
    res.status(200).send(classrooms)
