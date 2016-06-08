async = require 'async'
Handler = require '../commons/Handler'
Campaign = require '../models/Campaign'
Classroom = require '../models/Classroom'
Course = require '../models/Course'
CourseInstance = require './../models/CourseInstance'
LevelSession = require '../models/LevelSession'
LevelSessionHandler = require './level_session_handler'
Prepaid = require '../models/Prepaid'
PrepaidHandler = require './prepaid_handler'
User = require '../models/User'
UserHandler = require './user_handler'
utils = require '../../app/core/utils'
{objectIdFromTimestamp} = require '../lib/utils'
sendwithus = require '../sendwithus'
mongoose = require 'mongoose'

CourseInstanceHandler = class CourseInstanceHandler extends Handler
  modelClass: CourseInstance
  jsonSchema: require '../../app/schemas/models/course_instance.schema'
  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE']

  logError: (user, msg) ->
    console.warn "Course instance error: #{user.get('slug')} (#{user._id}): '#{msg}'"

  hasAccess: (req) ->
    req.method in @allowedMethods or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    return true if document?.get('ownerID')?.equals(req.user?.get('_id'))
    return true if req.method is 'GET' and _.find document?.get('members'), (a) -> a.equals(req.user?.get('_id'))
    req.user?.isAdmin()

  getByRelationship: (req, res, args...) ->
    relationship = args[1]
    return @createHOCAPI(req, res) if relationship is 'create-for-hoc'
    return @getLevelSessionsAPI(req, res, args[0]) if args[1] is 'level_sessions'
    return @removeMember(req, res, args[0]) if req.method is 'DELETE' and args[1] is 'members'
    return @getMembersAPI(req, res, args[0]) if args[1] is 'members'
    return @inviteStudents(req, res, args[0]) if relationship is 'invite_students'
    return @redeemPrepaidCodeAPI(req, res) if args[1] is 'redeem_prepaid'
    return @getMyCourseLevelSessionsAPI(req, res, args[0]) if args[1] is 'my-course-level-sessions'
    return @findByLevel(req, res, args[2]) if args[1] is 'find_by_level'
    super arguments...

  createHOCAPI: (req, res) ->
    return @sendUnauthorizedError(res) if not req.user?
    courseID = mongoose.Types.ObjectId('560f1a9f22961295f9427742')
    CourseInstance.findOne { courseID: courseID, ownerID: req.user.get('_id'), hourOfCode: true }, (err, courseInstance) =>
      return @sendDatabaseError(res, err) if err
      if courseInstance
        console.log 'already made a course instance'
      return @sendSuccess(res, courseInstance) if courseInstance
      courseInstance = new CourseInstance({
        courseID: courseID
        members: [req.user.get('_id')]
        name: 'Single Player'
        ownerID: req.user.get('_id')
        aceConfig: { language: 'python' }
        hourOfCode: true
      })
      courseInstance.save (err, courseInstance) =>
        return @sendDatabaseError(res, err) if err
        @sendCreated(res, courseInstance)

  removeMember: (req, res, courseInstanceID) ->
    return @sendUnauthorizedError(res) if not req.user?
    userID = req.body.userID
    return @sendBadInputError(res, 'Input must be a MongoDB ID') unless utils.isID(userID)
    CourseInstance.findById courseInstanceID, (err, courseInstance) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res, 'Course instance not found') unless courseInstance
      Classroom.findById courseInstance.get('classroomID'), (err, classroom) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res, 'Classroom referenced by course instance not found') unless classroom
        return @sendForbiddenError(res) unless _.any(classroom.get('members'), (memberID) -> memberID.toString() is userID)
        ownsCourseInstance = courseInstance.get('ownerID').equals(req.user.get('_id'))
        removingSelf = userID is req.user.id
        return @sendForbiddenError(res) unless ownsCourseInstance or removingSelf
        alreadyNotInCourseInstance = not _.any courseInstance.get('members') or [], (memberID) -> memberID.toString() is userID
        return @sendSuccess(res, @formatEntity(req, courseInstance)) if alreadyNotInCourseInstance
        members = _.clone(courseInstance.get('members'))
        members = (m for m in members when m.toString() isnt userID)
        courseInstance.set('members', members)
        courseInstance.save (err, courseInstance) =>
          return @sendDatabaseError(res, err) if err
          User.update {_id: mongoose.Types.ObjectId(userID)}, {$pull: {courseInstances: courseInstance.get('_id')}}, (err) =>
            return @sendDatabaseError(res, err) if err
            @sendSuccess(res, @formatEntity(req, courseInstance))

  post: (req, res) ->
    return @sendUnauthorizedError(res) if not req.user?
    return @sendBadInputError(res, 'No classroomID') unless req.body.classroomID
    return @sendBadInputError(res, 'No courseID') unless req.body.courseID
    Classroom.findById req.body.classroomID, (err, classroom) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res, 'Classroom not found') unless classroom
      return @sendForbiddenError(res) unless classroom.get('ownerID').equals(req.user.get('_id'))
      Course.findById req.body.courseID, (err, course) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res, 'Course not found') unless course
        q = {
          courseID: mongoose.Types.ObjectId(req.body.courseID)
          classroomID: mongoose.Types.ObjectId(req.body.classroomID)
        }
        CourseInstance.findOne(q).exec (err, doc) =>
          return @sendDatabaseError(res, err) if err
          return @sendSuccess(res, @formatEntity(req, doc)) if doc
          super(req, res)

  makeNewInstance: (req) ->
    doc = new CourseInstance({
      members: []
      ownerID: req.user.get('_id')
    })
    doc.set('aceConfig', {}) # constructor will ignore empty objects
    return doc

  getLevelSessionsAPI: (req, res, courseInstanceID) ->
    return @sendUnauthorizedError(res) if not req.user?
    CourseInstance.findById courseInstanceID, (err, courseInstance) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless courseInstance
      Course.findById courseInstance.get('courseID'), (err, course) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless course
        Campaign.findById course.get('campaignID'), (err, campaign) =>
          return @sendDatabaseError(res, err) if err
          return @sendNotFoundError(res) unless campaign
          levelIDs = (levelID for levelID of campaign.get('levels'))
          memberIDs = _.map courseInstance.get('members') ? [], (memberID) -> memberID.toHexString?() or memberID
          query = {$and: [{creator: {$in: memberIDs}}, {'level.original': {$in: levelIDs}}]}
          cursor = LevelSession.find(query)
          cursor = cursor.select(req.query.project) if req.query.project
          cursor.exec (err, documents) =>
            return @sendDatabaseError(res, err) if err?
            cleandocs = (LevelSessionHandler.formatEntity(req, doc) for doc in documents)
            @sendSuccess(res, cleandocs)

  getMyCourseLevelSessionsAPI: (req, res, courseInstanceID) ->
    return @sendUnauthorizedError(res) if not req.user?
    CourseInstance.findById courseInstanceID, (err, courseInstance) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless courseInstance
      Course.findById courseInstance.get('courseID'), (err, course) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless course
        Campaign.findById course.get('campaignID'), (err, campaign) =>
          return @sendDatabaseError(res, err) if err
          return @sendNotFoundError(res) unless campaign
          levelIDs = (levelID for levelID, level of campaign.get('levels') when not _.contains(level.type, 'ladder'))
          query = {$and: [{creator: req.user.id}, {'level.original': {$in: levelIDs}}]}
          cursor = LevelSession.find(query)
          cursor = cursor.select(req.query.project) if req.query.project
          cursor.exec (err, documents) =>
            return @sendDatabaseError(res, err) if err?
            cleandocs = (LevelSessionHandler.formatEntity(req, doc) for doc in documents)
            @sendSuccess(res, cleandocs)

  getMembersAPI: (req, res, courseInstanceID) ->
    return @sendUnauthorizedError(res) if not req.user?
    CourseInstance.findById courseInstanceID, (err, courseInstance) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless courseInstance
      memberIDs = courseInstance.get('members') ? []
      User.find {_id: {$in: memberIDs}}, (err, users) =>
        return @sendDatabaseError(res, err) if err
        cleandocs = (UserHandler.formatEntity(req, doc) for doc in users)
        @sendSuccess(res, cleandocs)

  inviteStudents: (req, res, courseInstanceID) ->
    return @sendUnauthorizedError(res) if not req.user?
    if not req.body.emails
      return @sendBadInputError(res, 'Emails not included')
    CourseInstance.findById courseInstanceID, (err, courseInstance) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless courseInstance
      return @sendForbiddenError(res) unless @hasAccessToDocument(req, courseInstance)

      Course.findById courseInstance.get('courseID'), (err, course) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless course

        Prepaid.findById courseInstance.get('prepaidID'), (err, prepaid) =>
          return @sendDatabaseError(res, err) if err
          return @sendNotFoundError(res) unless prepaid
          return @sendForbiddenError(res) unless prepaid.get('maxRedeemers') > prepaid.get('redeemers').length
          for email in req.body.emails
            context =
              email_id: sendwithus.templates.course_invite_email
              recipient:
                address: email
              subject: course.get('name')
              email_data:
                teacher_name: req.user.broadName()
                class_name: course.get('name')
                join_link: "https://codecombat.com/courses/students?_ppc=" + prepaid.get('code')
            sendwithus.api.send context, _.noop
          return @sendSuccess(res, {})

  redeemPrepaidCodeAPI: (req, res) ->
    return @sendUnauthorizedError(res) if not req.user? or req.user?.isAnonymous()
    return @sendBadInputError(res) unless req.body?.prepaidCode

    prepaidCode = req.body?.prepaidCode
    Prepaid.find code: prepaidCode, (err, prepaids) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) if prepaids.length < 1
      return @sendDatabaseError(res, "Multiple prepaid codes found for #{prepaidCode}") if prepaids.length > 1
      prepaid = prepaids[0]

      CourseInstance.find prepaidID: prepaid.get('_id'), (err, courseInstances) =>
        return @sendDatabaseError(res, err) if err
        return @sendForbiddenError(res) if prepaid.get('redeemers')?.length >= prepaid.get('maxRedeemers')

        if _.find((prepaid.get('redeemers') ? []), (a) -> a.userID.equals(req.user.id))
          return @sendSuccess(res, courseInstances)

        # Add to prepaid redeemers
        query =
          _id: prepaid.get('_id')
          'redeemers.userID': { $ne: req.user.get('_id') }
          $where: "this.redeemers.length < #{prepaid.get('maxRedeemers')}"
        update = { $push: { redeemers : { date: new Date(), userID: req.user.get('_id') } }}
        Prepaid.update query, update, (err, result) =>
          return @sendDatabaseError(res, err) if err
          if result?.nModified is 0
            @logError(req.user, "Course instance update prepaid lost race on maxRedeemers")
            return @sendForbiddenError(res)

          # Add to each course instance
          makeAddMemberToCourseInstanceFn = (courseInstance) =>
            (done) => courseInstance.update({$addToSet: { members: req.user.get('_id')}}, done)
          tasks = (makeAddMemberToCourseInstanceFn(courseInstance) for courseInstance in courseInstances)
          async.parallel tasks, (err, results) =>
            return @sendDatabaseError(res, err) if err
            @sendSuccess(res, courseInstances)

  findByLevel: (req, res, levelOriginal) ->
    return @sendUnauthorizedError(res) if not req.user?
    # Find all CourseInstances that req.user is a part of that match the given level.
    CourseInstance.find {_id: {$in: req.user.get('courseInstances')}},  (err, courseInstances) =>
      return @sendDatabaseError res, err if err
      return @sendSuccess res, [] unless courseInstances.length
      courseIDs = _.uniq (ci.get('courseID') for ci in courseInstances)
      Course.find {_id: {$in: courseIDs}}, {name: 1, campaignID: 1}, (err, courses) =>
        return @sendDatabaseError res, err if err
        return @sendSuccess res, [] unless courses.length
        campaignIDs = _.uniq (c.get('campaignID') for c in courses)
        Campaign.find {_id: {$in: campaignIDs}, "levels.#{levelOriginal}": {$exists: true}}, {_id: 1}, (err, campaigns) =>
          return @sendDatabaseError res, err if err
          return @sendSuccess res, [] unless campaigns.length
          courses = _.filter courses, (course) -> _.find campaigns, (campaign) -> campaign.get('_id').toString() is course.get('campaignID').toString()
          courseInstances = _.filter courseInstances, (courseInstance) -> _.find courses, (course) -> course.get('_id').toString() is courseInstance.get('courseID').toString()
          return @sendSuccess res, courseInstances

  get: (req, res) ->
    if ownerID = req.query.ownerID
      return @sendForbiddenError(res) unless req.user and (req.user.isAdmin() or ownerID is req.user.id)
      return @sendBadInputError(res, 'Bad ownerID') unless utils.isID ownerID
      CourseInstance.find {ownerID: mongoose.Types.ObjectId(ownerID)}, (err, courseInstances) =>
        return @sendDatabaseError(res, err) if err
        return @sendSuccess(res, (@formatEntity(req, courseInstance) for courseInstance in courseInstances))
    else if memberID = req.query.memberID
      return @sendForbiddenError(res) unless req.user and (req.user.isAdmin() or memberID is req.user.id)
      return @sendBadInputError(res, 'Bad memberID') unless utils.isID memberID
      CourseInstance.find {members: mongoose.Types.ObjectId(memberID)}, (err, courseInstances) =>
        return @sendDatabaseError(res, err) if err
        return @sendSuccess(res, (@formatEntity(req, courseInstance) for courseInstance in courseInstances))
    else if classroomID = req.query.classroomID
      return @sendForbiddenError(res) unless req.user
      return @sendBadInputError(res, 'Bad memberID') unless utils.isID classroomID
      Classroom.findById classroomID, (err, classroom) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless classroom
        return @sendForbiddenError(res) unless classroom.isMember(req.user._id) or classroom.isOwner(req.user._id)
        CourseInstance.find {classroomID: mongoose.Types.ObjectId(classroomID)}, (err, courseInstances) =>
          return @sendDatabaseError(res, err) if err
          return @sendSuccess(res, (@formatEntity(req, courseInstance) for courseInstance in courseInstances))
    else
      super(arguments...)

module.exports = new CourseInstanceHandler()
