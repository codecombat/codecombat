_ = require 'lodash'
utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
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

module.exports =
  getByOwner: wrap (req, res, next) ->
    options = req.query
    ownerID = options.ownerID
    return next() unless ownerID
    throw new errors.UnprocessableEntity('Bad ownerID') unless utils.isID ownerID
    throw new errors.Unauthorized() unless req.user
    throw new errors.Forbidden('"ownerID" must be yourself') unless req.user.isAdmin() or ownerID is req.user.id
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
    select = 'state.complete level creator playtime changed dateFirstCompleted'
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
      throw new errors.Forbidden('You do not own this classroom.')
    memberIDs = classroom.get('members') or []
    memberIDs = memberIDs.slice(memberSkip, memberSkip + memberLimit)
    
    members = yield User.find({ _id: { $in: memberIDs }}).select(parse.getProjectFromReq(req))
    # members = yield User.find({ _id: { $in: memberIDs }, deleted: { $ne: true }}).select(parse.getProjectFromReq(req))
    memberObjects = (member.toObject({ req: req, includedPrivates: ["name", "email"] }) for member in members)
    
    res.status(200).send(memberObjects)

  post: wrap (req, res) ->
    throw new errors.Unauthorized() unless req.user and not req.user.isAnonymous()
    throw new errors.Forbidden() unless req.user?.isTeacher()
    classroom = database.initDoc(req, Classroom)
    classroom.set 'ownerID', req.user._id
    classroom.set 'members', []
    database.assignBody(req, classroom)
    
    # copy over data from how courses are right now
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
        _.extend(levelData, _.pick(level, 'type', 'slug', 'name'))
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
      throw new errors.Forbidden('Cannot join a classroom as a teacher')
    code = req.body.code.toLowerCase()
    classroom = yield Classroom.findOne({code: code})
    if not classroom
      throw new errors.NotFound(res) 
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
