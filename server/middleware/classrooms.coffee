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

module.exports =
  fetchByCode: wrap (req, res, next) ->
    code = req.query.code
    return next() unless code
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
    
    levels = yield Level.find({ original: { $in: levelOriginals }, slug: { $exists: true }}).select(parse.getProjectFromReq(req))
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

    levels = yield Level.find({ original: { $in: levelOriginals }, slug: { $exists: true }}).select(parse.getProjectFromReq(req))
    levels = (level.toObject({ req: req }) for level in levels)
    
    # maintain course order
    levelMap = {}
    for level in levels
      levelMap[level.original] = level
    levels = (levelMap[levelOriginal.toString()] for levelOriginal in levelOriginals)
    
    res.status(200).send(levels)

  fetchMemberSessions: wrap (req, res, next) ->
    throw new errors.Unauthorized() unless req.user
    memberLimit = parse.getLimitFromReq(req, {default: 10, max: 100, param: 'memberLimit'})
    memberSkip = parse.getSkipFromReq(req, {param: 'memberSkip'})
    classroom = yield database.getDocFromHandle(req, Classroom)
    throw new errors.NotFound('Classroom not found.') if not classroom
    throw new errors.Forbidden('You do not own this classroom.') unless req.user.isAdmin() or classroom.get('ownerID').equals(req.user._id)
    members = classroom.get('members') or []
    members = members.slice(memberSkip, memberSkip + memberLimit)
    dbqs = []
    select = 'state.complete level creator playtime changed dateFirstCompleted submitted'
    for member in members
      dbqs.push(LevelSession.find({creator: member.toHexString()}).select(select).exec())
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
    memberObjects = (member.toObject({ req: req, includedPrivates: ["name", "email"] }) for member in members)
    
    res.status(200).send(memberObjects)

  post: wrap (req, res) ->
    throw new errors.Unauthorized() unless req.user and not req.user.isAnonymous()
    unless req.user?.isTeacher()
      log.debug "classrooms.post: Can't create classroom if you (#{req.user?.id}) aren't a teacher."
      throw new errors.Forbidden()
    classroom = database.initDoc(req, Classroom)
    classroom.set 'ownerID', req.user._id
    classroom.set 'members', []
    database.assignBody(req, classroom)
    
    # Copy over data from how courses are right now
    courses = yield Course.find()
    campaigns = yield Campaign.find({_id: {$in: (course.get('campaignID') for course in courses)}})
    campaignMap = {}
    campaignMap[campaign.id] = campaign for campaign in campaigns
    coursesData = []
    for course in courses
      courseData = { _id: course._id, levels: [] }
      campaign = campaignMap[course.get('campaignID').toString()]
      levels = _.values(campaign.get('levels'))
      levels = _.sortBy(levels, 'campaignIndex')
      for level in levels
        levelData = { original: mongoose.Types.ObjectId(level.original) }
        _.extend(levelData, _.pick(level, 'type', 'slug', 'name', 'practice', 'practiceThresholdMinutes'))
        courseData.levels.push(levelData)
      coursesData.push(courseData)
    classroom.set('courses', coursesData)
    
    # finish
    database.validateDoc(classroom)
    classroom = yield classroom.save()
    res.status(201).send(classroom.toObject({req: req}))

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
    members = _.clone(classroom.get('members'))
    if _.any(members, (memberID) -> memberID.equals(req.user._id))
      return res.send(classroom.toObject({req: req}))
    update = { $push: { members : req.user._id }}
    yield classroom.update(update)
    members.push req.user._id
    classroom.set('members', members)
    
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
          join_link: "https://codecombat.com/courses?_cc=" + joinCode
          join_code: joinCode
      sendwithus.api.send context, _.noop
    
    res.status(200).send({})

  getUsers: wrap (req, res, next) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    classrooms = yield Classroom.find().select('ownerID members').lean()
    res.status(200).send(classrooms)
