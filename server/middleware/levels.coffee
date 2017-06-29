mongoose = require 'mongoose'
wrap = require 'co-express'
co = require 'co'
errors = require '../commons/errors'
Level = require '../models/Level'
LevelSession = require '../models/LevelSession'
Prepaid = require '../models/Prepaid'
CourseInstance = require '../models/CourseInstance'
Classroom = require '../models/Classroom'
Course = require '../models/Course'
User = require '../models/User'
database = require '../commons/database'
codePlay = require '../../app/lib/code-play'
log = require 'winston'

module.exports =
  upsertSession: wrap (req, res) ->
    level = yield database.getDocFromHandle(req, Level)
    if not level
      throw new errors.NotFound('Level not found.')
    levelOriginal = level.get('original')

    sessionQuery =
      level:
        original: level.get('original').toString()
        majorVersion: level.get('version').major
      creator: req.user.id

    if req.query.team?
      sessionQuery.team = req.query.team

    if req.query.courseInstance
      unless mongoose.Types.ObjectId.isValid(req.query.courseInstance)
        throw new errors.UnprocessableEntity('Invalid course instance id')
      courseInstance = yield CourseInstance.findById(req.query.courseInstance)
      if not courseInstance
        throw new errors.NotFound('Course Instance not found.')
      if not _.find(courseInstance.get('members'), (memberID) -> memberID.equals(req.user._id))
        throw new errors.Forbidden('You must be a member of the Course Instance.')
      classroom = yield Classroom.findById(courseInstance.get('classroomID'))
      if not classroom
        throw new errors.NotFound('Classroom not found.')
      courseID = courseInstance.get('courseID')
      classroomCourse = _.find(classroom.get('courses'), (c) -> c._id.equals(courseID))
      targetLevel = null
      for courseLevel in classroomCourse.levels
        if courseLevel.original.equals(levelOriginal)
          targetLevel = courseLevel
          break
      if not targetLevel
        throw new errors.NotFound('Level not found in classroom courses')
      language = targetLevel.primerLanguage or classroom.get('aceConfig.language')
      if language
        sessionQuery.codeLanguage = language

    session = yield LevelSession.findOne(sessionQuery)
    if session
      return res.send(session.toObject({req: req}))

    attrs = sessionQuery
    _.extend(attrs, {
      state:
        complete: false
        scripts:
          currentScript: null # will not save empty objects
      permissions: [
        {target: req.user.id, access: 'owner'}
        {target: 'public', access: 'write'}
      ]
      codeLanguage: req.user.get('aceConfig')?.language ? 'python'
    })

    if level.get('type') in ['course', 'course-ladder'] or req.query.course?

      # Find the course and classroom that has assigned this level, verify access
      # Handle either being given the courseInstance, or having to deduce it
      if courseInstance and classroom
        courseInstances = [courseInstance]
        classrooms = [classroom]
      else
        courseInstances = yield CourseInstance.find({members: req.user._id})
        classroomIDs = (courseInstance.get('classroomID') for courseInstance in courseInstances)
        classroomIDs = _.filter _.uniq classroomIDs, false, (objectID='') -> objectID.toString()
        classrooms = yield Classroom.find({ _id: { $in: classroomIDs }})

      classroomWithLevel = null
      targetLevel = null
      courseID = null
      classroomMap = {}
      classroomMap[classroom.id] = classroom for classroom in classrooms
      for courseInstance in courseInstances
        classroomID = courseInstance.get('classroomID')
        continue unless classroomID
        classroom = classroomMap[classroomID.toString()]
        continue unless classroom
        courseID = courseInstance.get('courseID')
        classroomCourse = _.find(classroom.get('courses'), (c) -> c._id.equals(courseID))
        for courseLevel in classroomCourse.levels
          if courseLevel.original.equals(levelOriginal)
            targetLevel = courseLevel
            classroomWithLevel = classroom
            break
        break if classroomWithLevel

      if course?.id
        prepaidIncludesCourse = req.user.prepaidIncludesCourse(course?.id)
      else
        prepaidIncludesCourse = true

      unless classroomWithLevel and prepaidIncludesCourse
        throw new errors.PaymentRequired('You must be in a course which includes this level to play it')

      course = yield Course.findById(courseID).select('free')
      unless course.get('free') or req.user.isEnrolled()
        throw new errors.PaymentRequired('You must be enrolled to access this content')

      lang = targetLevel.primerLanguage or classroomWithLevel.get('aceConfig')?.language
      attrs.codeLanguage = lang if lang

    else
      requiresSubscription = level.get('requiresSubscription') or (req.user.isOnPremiumServer() and level.get('campaign') and not (level.slug in ['dungeons-of-kithgard', 'gems-in-the-deep', 'shadow-guard', 'forgetful-gemsmith', 'signs-and-portents', 'true-names']))
      canPlayAnyway = _.any([
        req.user.isPremium(),
        level.get('adventurer'),
        req.features.codePlay and codePlay.canPlay(level.get('slug'))
      ])
      if requiresSubscription and not canPlayAnyway
        throw new errors.PaymentRequired('This level requires a subscription to play')

    attrs.isForClassroom = course?
    session = new LevelSession(attrs)
    if classroom # Potentially set intercom trigger flag on teacher
      teacher = yield User.findOne({ _id: classroom.get('ownerID') })
      reportLevelStarted({teacher, level})
    yield session.save()
    res.status(201).send(session.toObject({req: req}))

# Notes on the teacher object that the relevant intercom trigger should be activated.
reportLevelStarted = co.wrap ({teacher, level}) ->
  intercom = require('../lib/intercom')
  if level.get('slug') is 'wakka-maul'
    yield teacher.update({ $set: { "studentMilestones.studentStartedWakkaMaul": true } })
    update = {
      user_id: teacher.get('_id') + '',
      email: teacher.get('email'),
      custom_attributes:
        studentStartedWakkaMaul: true
    }
  if level.get('slug') is 'a-mayhem-of-munchkins'
    yield teacher.update({ $set: { "studentMilestones.studentStartedMayhemOfMunchkins": true } })
    update = {
      user_id: teacher.get('_id') + '',
      email: teacher.get('email'),
      custom_attributes:
        studentStartedMayhemOfMunchkins: true
    }
  if update
    tries = 0
    while tries < 100
      tries += 1
      try
        yield intercom.users.create update
        return
      catch e
        yield new Promise (accept, reject) -> setTimeout(accept, 1000)
    log.error "Couldn't update intercom for user #{teacher.get('email')} in 100 tries"
