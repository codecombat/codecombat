mongoose = require 'mongoose'
wrap = require 'co-express'
co = require 'co'
errors = require '../commons/errors'
Level = require '../models/Level'
LevelSession = require '../models/LevelSession'
Prepaid = require '../models/Prepaid'
CourseInstance = require '../models/CourseInstance'
Classroom = require '../models/Classroom'
Campaign = require '../models/Campaign'
Course = require '../models/Course'
User = require '../models/User'
database = require '../commons/database'
codePlay = require '../../app/lib/code-play'
log = require 'winston'

module.exports =
  upsertSession: wrap (req, res) ->
    level = yield database.getDocFromHandle(req, Level)  # TODO: project only fields we need?
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
      unless _.find(courseInstance.get('members'), (memberID) -> memberID.equals(req.user._id)) or courseInstance.get('ownerID').equals(req.user._id)
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

    mirrorMatches = ['ace-of-coders', 'elemental-wars', 'the-battle-of-sky-span', 'tesla-tesoro', 'escort-duty', 'treasure-games']
    if sessionQuery.team and level.get('slug') in mirrorMatches
      # Find their other session for this, so that if it exists, we can initialize the new team's session with the mirror code.
      otherTeam = if sessionQuery.team is 'humans' then 'ogres' else 'humans'
      otherSessionQuery = _.defaults {team: otherTeam, code: {$exists: true}}, sessionQuery
      otherSession = yield LevelSession.findOne(otherSessionQuery).select('team code codeLanguage')
      if otherSession
        heroSlugs = humans: 'hero-placeholder', ogres: 'hero-placeholder-1'
        code = {}
        code[heroSlugs[sessionQuery.team]] = plan: otherSession.get('code')[heroSlugs[otherSession.get('team')]].plan

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
      codeLanguage: otherSession?.get('codeLanguage') ? req.user.get('aceConfig')?.language ? 'python'
    })
    if code
      attrs.code = code

    if not req.user.isAnonymous() and level.get('slug') in ['treasure-games', 'escort-duty', 'tesla-tesoro', 'elemental-wars']
      console.log "Allowing session creation for #{level.get('slug')} outside of any course"
      attrs.isForClassroom = true
    else if level.get('type') in ['course', 'course-ladder'] or req.query.course?

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

      if req.query.campaign and not canPlayAnyway
        # check if the campaign requesting this is game dev hoc, if so then let it work
        query = {
          _id: mongoose.Types.ObjectId(req.query.campaign),
          type: 'hoc'
          "levels.#{level.get('original')}": {$exists: true}
        }
        campaign = yield Campaign.count(query)
        if campaign
          canPlayAnyway = true

      if requiresSubscription and not canPlayAnyway
        throw new errors.PaymentRequired('This level requires a subscription to play')

    attrs.isForClassroom ?= course?
    session = new LevelSession(attrs)
    if classroom # Potentially set intercom trigger flag on teacher
      teacher = yield User.findOne({ _id: classroom.get('ownerID') })
      reportLevelStarted({teacher, level})
    yield session.save()
    res.status(201).send(session.toObject({req: req}))

# Notes on the teacher object that the relevant intercom trigger should be activated.
reportLevelStarted = co.wrap ({teacher, level}) ->
  intercom = require('../lib/intercom')
  return unless level.get('slug') in ['wakka-maul', 'a-mayhem-of-munchkins', 'dungeons-of-kithgard', 'true-names', 'throwing-fire', 'over-the-garden-wall', 'humble-beginnings', 'defense-of-plainswood', 'guard-duty', 'javascript-true-names', 'query-confirmed', 'friend-and-foe', 'the-rule-of-the-square', 'dust', 'vital-powers', 'misty-island-mine', 'queue-manager']
  levelVariable = level.get('slug').replace(/(?:^|\s|-)\S/g, (c) -> c.toUpperCase()).replace(/-/g, '')
  levelVariable = level.replace 'AMayhemOfMunchkins', 'MayhemOfMunchkins'  # inconsistent variable name
  update =
      user_id: teacher.get('_id') + ''
      email: teacher.get('email')
      custom_attributes: {}
  if levelVariable in ['WakkaMaul', 'MayhemOfMunchkins']
    update.custom_attributes['studentStarted' + levelVariable] = true
    yield teacher.update({ $set: { "studentMilestones.studentStarted#{levelVariable}": true } })
  else
    update.custom_attributes['studentsStarted' + levelVariable] = (teacher.studentMilestones?["studentsStarted#{levelVariable}"] ? 0) + 1
    yield teacher.update({ $inc: { "studentMilestones.studentsStarted#{levelVariable}": 1 } })

  tries = 0
  while tries < 100
    tries += 1
    try
      yield intercom.users.create update
      return
    catch e
      yield new Promise (accept, reject) -> setTimeout(accept, 1000)
  log.error "Couldn't update intercom for user #{teacher.get('email')} in 100 tries"
