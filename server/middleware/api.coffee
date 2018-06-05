basicAuth = require('basic-auth')
APIClient = require '../models/APIClient'
Classroom = require '../models/Classroom'
CourseInstance = require '../models/CourseInstance'
LevelSession = require '../models/LevelSession'
Course = require '../models/Course'
ThangType = require '../models/ThangType'
User = require '../models/User'
wrap = require 'co-express'
errors = require '../commons/errors'
database = require '../commons/database'
config = require '../../server_config'
Prepaid = require '../models/Prepaid'
moment = require 'moment'
oauth = require '../lib/oauth'

INCLUDED_USER_PRIVATE_PROPS = ['email', 'oAuthIdentities', 'role']
DATETIME_REGEX = /^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}\.\d{3}Z$/ # JavaScript Date's toISOString() output

clientAuth = wrap (req, res, next) ->
  if config.isProduction and not req.isSecure()
    throw new errors.Unauthorized('API calls must be over HTTPS.')

  creds = basicAuth(req)

  unless creds and creds.name and creds.pass
    throw new errors.Unauthorized('Basic auth credentials not provided.')

  client = yield APIClient.findById(creds.name)
  if not client
    throw new errors.Unauthorized('Credentials incorrect.')

  hashed = APIClient.hash(creds.pass)
  if client.get('secret') isnt hashed
    throw new errors.Unauthorized('Credentials incorrect.')

  req.client = client
  next()


postUser = wrap (req, res) ->
  user = new User({anonymous: false})
  user.set(_.pick(req.body, 'name', 'email', 'role'))
  user.set('clientCreator', req.client._id)
  database.validateDoc(user)
  user = yield user.save()
  res.status(201).send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))


putUserHeroConfig = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')

  unless req.client.hasControlOfUser(user)
    throw new errors.Forbidden('Must have created the user.')

  # verify this thang type exists and is a hero
  heroConfig = _.clone(user.get('heroConfig') ? {})
  if req.body.thangType
    thangType = yield ThangType.findCurrentVersion(req.body.thangType, {kind: 1, original: 1})
    if not thangType
      throw new errors.NotFound('Hero not found.')
    if thangType.get('kind') isnt 'Hero'
      throw new errors.Forbidden('Given ThangType is not a Hero.')
    heroConfig.thangType = thangType.get('original')

  user.set({heroConfig})
  database.validateDoc(user)
  yield user.save()
  res.status(200).send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))


getUser = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')

  isSnowplow = req.client.id is '5876a40d19b82624002cf18d'
  exception = _.any([
    req.client.id is '582a134eb9bce324006210e7' and user.get('israelId') # israel access to its users
    isSnowplow # snowplow read access
  ])

  unless exception or req.client.hasControlOfUser(user)
    throw new errors.Forbidden('Must have created the user.')

  obj = user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true})

  if isSnowplow
    obj = _.omit obj, 'email', 'name', 'githubID', 'cleverID', 'oAuthIdentities', 'consentHistory'

  if req.query.includePlayTime
    result = yield LevelSession.aggregate()
      .match({creator: user.id})
      .group({_id: '1', playTime: {$sum: "$playtime"}})
      .exec()
    obj.stats ?= {}
    obj.stats.playTime = result[0].playTime

  res.send(obj)


getUserLookupByIsraelId = wrap (req, res) ->
  { israelId } = req.params
  user = yield User.findOne({ israelId })
  if not user
    throw new errors.NotFound('User not found.')

  res.redirect(301, "/api/users/#{user.id}")


getUserLookupByName = wrap (req, res) ->
  { name } = req.params
  user = yield User.findByName(name)
  if not user
    throw new errors.NotFound('User not found.')

  res.redirect(301, "/api/users/#{user.id}")


postUserOAuthIdentity = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')

  unless req.client.hasControlOfUser(user)
    throw new errors.Forbidden('Must have created the user to perform this action.')

  { provider: providerId, accessToken, code } = req.body or {}
  identity = yield oauth.getIdentityFromOAuth({providerId, accessToken, code})

  otherUser = yield User.findOne({oAuthIdentities: { $elemMatch: identity }})
  if otherUser
    if otherUser.id is user.id
      return res.send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))
    else
      throw new errors.Conflict('User already exists with this identity')

  yield user.update({$push: {oAuthIdentities: identity}})
  oAuthIdentities = user.get('oAuthIdentities') or []
  oAuthIdentities.push(identity)
  user.set({oAuthIdentities})
  res.send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))


putUserSubscription = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')

  unless req.client.hasControlOfUser(user, 'put-user-subscription')
    throw new errors.Forbidden('Must have created the user to perform this action.')

  # TODO: Remove 'endDate' parameter
  { endDate, ends } = req.body
  ends ?= endDate
  unless ends and DATETIME_REGEX.test(ends)
    throw new errors.UnprocessableEntity('ends is not properly formatted.')

  { free } = user.get('stripe') ? {}
  if free is true
    throw new errors.UnprocessableEntity('This user already has free premium access')

  # if the user is already subscribed, this prepaid starts when it would have ended, otherwise it starts now
  now = new Date().toISOString()
  startDate = if _.isString(free) then moment(free).toISOString() else now
  startDate = now if startDate < now

  if startDate >= ends
    throw new errors.UnprocessableEntity("ends is before when the subscription would start: #{startDate}")

  prepaid = new Prepaid({
    creator: user._id
    clientCreator: req.client._id
    redeemers: []
    maxRedeemers: 1
    type: 'terminal_subscription'
    startDate
    endDate: ends
  })
  yield prepaid.save()
  yield prepaid.redeem(user)
  res.send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))


putUserLicense = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')

  unless req.client.hasControlOfUser(user, 'put-user-license')
    throw new errors.Forbidden('Must have created the user to perform this action.')

  { ends } = req.body
  unless ends and DATETIME_REGEX.test(ends)
    throw new errors.UnprocessableEntity('ends is not properly formatted.')

  now = new Date().toISOString()
  if ends < now
    throw new errors.UnprocessableEntity('ends must be in the future.')

  # if the user is already subscribed, this prepaid starts when it would have ended, otherwise it starts now
  { endDate } = user.get('coursePrepaid') ? {}
  if endDate and endDate >= now
    throw new errors.UnprocessableEntity("User is already enrolled, and may not be enrolled again until their current enrollment is finished")

  prepaid = new Prepaid({
    creator: user._id
    clientCreator: req.client._id
    redeemers: []
    maxRedeemers: 1
    type: 'course'
    startDate: now
    endDate: ends
  })
  yield prepaid.save()
  yield prepaid.redeem(user)
  res.send(user.toObject({req, includedPrivates: INCLUDED_USER_PRIVATE_PROPS, virtuals: true}))

postClassroom = wrap (req, res) ->
  owner = yield User.findBySlugOrId(req.body.ownerID)
  unless owner
    throw new errors.NotFound('User not found.')
  unless req.client.hasControlOfUser(owner)
    throw new errors.Forbidden('Must have created the user to perform this action.')
  unless owner?.isTeacher()
    throw new errors.Forbidden("Can't create classroom if user (#{owner?.id}) isn't a teacher.")
  unless req.body.aceConfig?.language
    throw new errors.UnprocessableEntity('aceConfig.language is required in the request body')
  try
    classroom = yield Classroom.create(owner, req)
    res.status(201).send(classroom.toObject({req: req}))
  catch err
    console.log("postClassroom api error: ", err)
    throw new errors.InternalServerError('Error creating the classroom')

putClassroomMember = wrap (req, res) ->
  classroom = yield database.getDocFromHandle(req, Classroom)
  if not classroom
    throw new errors.NotFound('Classroom not found.')

  { code, userId } = req.body
  if not (code and userId)
    throw new errors.UnprocessableEntity('code and userId required.')

  if classroom.get('code') isnt code.toLowerCase()
    throw new errors.UnprocessableEntity('code is incorrect.')

  user = yield User.findBySlugOrId(userId)
  if not user
    throw new errors.NotFound('User not found.')

  unless req.client.hasControlOfUser(user)
    throw new errors.Forbidden('Must have created the user to perform this action.')

  courseInstances = yield CourseInstance.find({classroomID: classroom._id})

  yield classroom.addMember(user)
  res.send(classroom.toObject({req, includeEnrolled: courseInstances}))


putClassroomCourseEnrolled = wrap (req, res) ->
  classroom = yield database.getDocFromHandle(req, Classroom, {handleName: 'classroomHandle'})
  if not classroom
    throw new errors.NotFound('Classroom not found.')

  classroomCourse = _.find(classroom.get('courses'), (c) -> c._id + '' is req.params.courseHandle)
  if not classroomCourse
    throw new errors.NotFound('Course not found.')

  course = yield Course.findById(classroomCourse._id)
  unless course
    throw new errors.NotFound('Course referenced by classroom not found')

  { userId } = req.body
  if not userId
    throw new errors.UnprocessableEntity('userId required.')

  user = yield User.findBySlugOrId(userId)
  if not user
    throw new errors.NotFound('User not found.')

  if not classroom.isMember(user._id)
    throw new errors.Forbidden('User must be in this classroom.')

  clientHasControlOfOwner = yield User.count({_id: classroom.get('ownerID'), clientCreator: req.client._id})
  if not clientHasControlOfOwner
    throw new errors.Forbidden('Must have created the user who created this classroom to perform this action.')

  unless req.client.hasControlOfUser(user)
    throw new errors.Forbidden('Must have created the user to perform this action.')

  unless course.get('free') or user.prepaidIncludesCourse(course)
    throw new errors.PaymentRequired('Cannot enroll this user in this course until they have a license.')

  courseInstances = yield CourseInstance.find({classroomID: classroom._id})
  courseInstance = _.find(courseInstances, (ci) -> ci.get('courseID').equals(classroomCourse._id))
  if not courseInstance
    courseInstance = new CourseInstance({
      courseID: classroomCourse._id
      classroomID: classroom._id
      ownerID: classroom.ownerID
    })
    yield courseInstance.save()
    courseInstances.push(courseInstance)

  courseInstance = yield CourseInstance.findByIdAndUpdate(
    courseInstance._id,
    { $addToSet: { members: user._id } }
    { new: true }
  )

  # put the updated course instance into the courseInstances array
  courseInstanceIndex = _.findIndex(courseInstances, (ci) -> ci.id is courseInstance.id)
  if courseInstanceIndex isnt -1
    courseInstances[courseInstanceIndex] = courseInstance

  userUpdateResult = yield user.update({ $addToSet: { courseInstances: courseInstance._id } })

  res.send(classroom.toObject({req, includeEnrolled: courseInstances}))


getClassroomMemberSessions = wrap (req, res, next) ->
  classroom = yield database.getDocFromHandle(req, Classroom, { handleName: 'classroomHandle' })
  if not classroom
    throw new errors.NotFound('Classroom not found.')

  clientHasControlOfOwner = yield User.count({_id: classroom.get('ownerID'), clientCreator: req.client._id})
  if not clientHasControlOfOwner
    throw new errors.Forbidden('Must have created the user who created this classroom to perform this action.')

  member = yield database.getDocFromHandle(req, User, { handleName: 'memberHandle' })
  memberStrings = classroom.get('members').map((memberId) => memberId + '')
  unless member and member.id in memberStrings
    throw new errors.NotFound('Member id not found in classroom.')

  unless req.client.hasControlOfUser(member)
    throw new errors.Forbidden('Must have created the member to perform this action.')

  sessions = yield classroom.fetchSessionsForMembers([member._id])

  # Return member sessions for assigned courses
  res.status(200).send(sessions)


getUserClassrooms = wrap (req, res) ->
  user = yield database.getDocFromHandle(req, User)
  if not user
    throw new errors.NotFound('User not found.')

  unless req.client.hasControlOfUser(user)
    throw new errors.Forbidden('Must have created the user to perform this action.')

  classrooms = yield Classroom.find(if user.get('role') is 'student' then { members: user._id } else { ownerID: user._id })
  courseInstances = yield CourseInstance.find({classroomID: {$in: _.map(classrooms, '_id')}})
  courseInstancesGrouped = _.groupBy(courseInstances, (ci) -> ci.get('classroomID').toString())

  res.send(_.map(classrooms, (classroom) ->
    courseInstancesGroup = courseInstancesGrouped[classroom.id] ? []
    return classroom.toObject({req, includeEnrolled: courseInstancesGroup})
  ))

getPlayTimeStats = wrap (req, res) ->
  startDate = new Date(2000,1,1).toISOString()
  endDate = new Date().toISOString()

  if req.query.startDate?
    unless DATETIME_REGEX.test req.query.startDate
      throw new errors.UnprocessableEntity('startDate is not properly formatted.')

    startDate = req.query.startDate

  if req.query.endDate?
    unless DATETIME_REGEX.test req.query.endDate
      throw new errors.UnprocessableEntity('endDate is not properly formatted.')

    endDate = req.query.endDate

  query = {
    dateCreated: {$lt: Date.parse(endDate), $gt: Date.parse(startDate)}
    clientCreator: req.client._id,
    oAuthIdentities: {$exists: 1}  # Take advantage of index
  }
  if req.query.country
    query.country = req.query.country

  user = yield User.find(query,{_id: 1}).exec()

  ids = _.map user, (x) -> x._id.toString()

  result = yield LevelSession.aggregate()
    .match({creator: {$in: ids}})
    .group({_id: '1', playTime: {$sum: "$playtime"}, gamesPlayed: {$sum: 1}})
    .exec()

  output = result[0]
  if not output
    return res.send { playTime: 0, gamesPlayed: 0 }

  delete output._id

  res.send output

module.exports = {
  clientAuth
  getUser
  getUserLookupByIsraelId
  getUserLookupByName
  postUser
  postUserOAuthIdentity
  getUserClassrooms
  putUserSubscription
  putUserHeroConfig
  putUserLicense
  postClassroom
  putClassroomMember
  putClassroomCourseEnrolled
  getClassroomMemberSessions
  getPlayTimeStats
}
