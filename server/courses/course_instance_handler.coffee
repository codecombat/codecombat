async = require 'async'
Handler = require '../commons/Handler'
Course = require './Course'
CourseInstance = require './CourseInstance'
LevelSession = require '../levels/sessions/LevelSession'
LevelSessionHandler = require '../levels/sessions/level_session_handler'
Prepaid = require '../prepaids/Prepaid'
PrepaidHandler = require '../prepaids/prepaid_handler'
User = require '../users/User'
UserHandler = require '../users/user_handler'
utils = require '../../app/core/utils'
sendwithus = require '../sendwithus'

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
    return @createAPI(req, res) if relationship is 'create'
    return @getLevelSessionsAPI(req, res, args[0]) if args[1] is 'level_sessions'
    return @getMembersAPI(req, res, args[0]) if args[1] is 'members'
    return @inviteStudents(req, res, args[0]) if relationship is 'invite_students'
    return @redeemPrepaidCodeAPI(req, res) if args[1] is 'redeem_prepaid'
    super arguments...

  createAPI: (req, res) ->
    return @sendUnauthorizedError(res) if not req.user? or req.user?.isAnonymous()

    # Required Input
    seats = req.body.seats
    unless seats > 0
      @logError(req.user, 'Course create API missing required seats count')
      return @sendBadInputError(res, 'Missing required seats count')
    # Optional - unspecified means create instances for all courses
    courseID = req.body.courseID
    # Optional
    name = req.body.name
    # Optional - as long as course(s) are all free
    stripeToken = req.body.stripe?.token

    query = if courseID? then {_id: courseID} else {}
    Course.find query, (err, courses) =>
      if err
        @logError(user, "Find courses error: #{JSON.stringify(err)}")
        return done(err)

      PrepaidHandler.purchasePrepaidCourse req.user, courses, seats, new Date().getTime(), stripeToken, (err, prepaid) =>
        if err
          @logError(req.user, err)
          return @sendBadInputError(res, err) if err is 'Missing required Stripe token'
          return @sendDatabaseError(res, err)

        courseInstances = []
        makeCreateInstanceFn = (course, name, prepaid) =>
          (done) =>
            @createInstance req, course, name, prepaid, (err, newInstance)=>
              courseInstances.push newInstance unless err
              done(err)
        tasks = (makeCreateInstanceFn(course, name, prepaid) for course in courses)
        async.parallel tasks, (err, results) =>
          return @sendDatabaseError(res, err) if err
          @sendCreated(res, courseInstances)

  createInstance: (req, course, name, prepaid, done) =>
    courseInstance = new CourseInstance
      courseID: course.get('_id')
      members: [req.user.get('_id')]
      name: name
      ownerID: req.user.get('_id')
      prepaidID: prepaid.get('_id')
    courseInstance.save (err, newInstance) =>
      done(err, newInstance)

  getLevelSessionsAPI: (req, res, courseInstanceID) ->
    CourseInstance.findById courseInstanceID, (err, courseInstance) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless courseInstance
      memberIDs = _.map courseInstance.get('members') ? [], (memberID) -> memberID.toHexString?() or memberID
      LevelSession.find {creator: {$in: memberIDs}}, (err, documents) =>
        return @sendDatabaseError(res, err) if err?
        cleandocs = (LevelSessionHandler.formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, cleandocs)

  getMembersAPI: (req, res, courseInstanceID) ->
    CourseInstance.findById courseInstanceID, (err, courseInstance) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless courseInstance
      memberIDs = courseInstance.get('members') ? []
      User.find {_id: {$in: memberIDs}}, (err, users) =>
        return @sendDatabaseError(res, err) if err
        cleandocs = (UserHandler.formatEntity(req, doc) for doc in users)
        @sendSuccess(res, cleandocs)

  inviteStudents: (req, res, courseInstanceID) ->
    if not req.body.emails
      return @sendBadInputError(res, 'Emails not included')
    CourseInstance.findById courseInstanceID, (err, courseInstance) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless courseInstance
      return @sendForbiddenError(res) unless @hasAccessToDocument(req, courseInstance)

      Prepaid.findById courseInstance.get('prepaidID'), (err, prepaid) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless prepaid
        return @sendForbiddenError(res) unless prepaid.get('maxRedeemers') > prepaid.get('redeemers').length
        for email in req.body.emails
          context =
            email_id: sendwithus.templates.course_invite_email
            recipient:
              address: email
            email_data:
              class_name: courseInstance.get('name')
              join_link: "https://codecombat.com/account/prepaid?_ppc=" + prepaid.get('code')
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

        # Add to prepaid redeemers
        query =
          _id: prepaid.get('_id')
          'redeemers.userID': { $ne: req.user.get('_id') }
          $where: "this.redeemers.length < #{prepaid.get('maxRedeemers')}"
        update = { $push: { redeemers : { date: new Date(), userID: req.user.get('_id') } }}
        Prepaid.update query, update, (err, nMatched) =>
          return @sendDatabaseError(res, err) if err
          if nMatched is 0
            @logError(req.user, "Course instance update prepaid lost race on maxRedeemers")
            return @sendForbiddenError(res)

          # Add to each course instance
          makeAddMemberToCourseInstanceFn = (courseInstance) =>
            (done) => courseInstance.update({$addToSet: { members: req.user.get('_id')}}, done)
          tasks = (makeAddMemberToCourseInstanceFn(courseInstance) for courseInstance in courseInstances)
          async.parallel tasks, (err, results) =>
            return @sendDatabaseError(res, err) if err
            @sendSuccess(res)

module.exports = new CourseInstanceHandler()
