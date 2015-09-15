async = require 'async'
Handler = require '../commons/Handler'
{getCoursesPrice} = require '../../app/core/utils'
Course = require './Course'
CourseInstance = require './CourseInstance'
LevelSession = require '../levels/sessions/LevelSession'
LevelSessionHandler = require '../levels/sessions/level_session_handler'
Prepaid = require '../prepaids/Prepaid'
User = require '../users/User'
UserHandler = require '../users/user_handler'

CourseInstanceHandler = class CourseInstanceHandler extends Handler
  modelClass: CourseInstance
  jsonSchema: require '../../app/schemas/models/course_instance.schema'
  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE']

  logError: (user, msg) ->
    console.warn "Course error: #{user.get('slug')} (#{user._id}): '#{msg}'"

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
    super arguments...

  createAPI: (req, res) ->
    return @sendUnauthorizedError(res) unless req.user?

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
    stripeToken = req.body.token

    @getCourses courseID, (err, courses) =>
      if err
        @logError(req.user, err)
        return @sendDatabaseError(res, err)

      price = getCoursesPrice(courses, seats)
      if price > 0 and not stripeToken
        @logError(req.user, 'Course create API missing required Stripe token')
        return @sendBadInputError(res, 'Missing required Stripe token')

      # TODO: purchase prepaid for courses, price, and seats
      Prepaid.generateNewCode (code) =>
        return @sendDatabaseError(res, 'Database error.') unless code
        prepaid = new Prepaid
          creator: req.user.get('_id')
          type: 'course'
          code: code
          properties:
            courseIDs: (course.get('_id') for course in courses)
        prepaid.set('maxRedeemers', seats) if seats
        prepaid.save (err) =>
          return @sendDatabaseError(res, err) if err

          courseInstances = []
          makeCreateInstanceFn = (course, name, prepaid) =>
            (done) =>
              @createInstance req, course, name, prepaid, (err, newInstance)=>
                courseInstances.push newInstance unless err
                done(err)
          # tasks = []
          # tasks.push(makeCreateInstanceFn(course, name, prepaid)) for course in courses
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

  getCourses: (courseID, done) =>
    if courseID
      Course.findById courseID, (err, document) =>
        done(err, [document])
    else
      Course.find {}, (err, documents) =>
        done(err, documents)

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

module.exports = new CourseInstanceHandler()
