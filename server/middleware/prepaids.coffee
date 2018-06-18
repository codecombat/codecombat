wrap = require 'co-express'
co = require 'co'
errors = require '../commons/errors'
database = require '../commons/database'
mongoose = require 'mongoose'
Promise = require 'bluebird'
Classroom = require '../models/Classroom'
Course = require '../models/Course'
CourseInstance = require '../models/CourseInstance'
LevelSession = require '../models/LevelSession'
Prepaid = require '../models/Prepaid'
Product = require '../models/Product'
Promise = require 'bluebird'
TrialRequest = require '../models/TrialRequest'
User = require '../models/User'
StripeUtils = require '../lib/stripe_utils'
Promise.promisifyAll(StripeUtils)
moment = require 'moment'
slack = require '../slack'
delighted = require '../delighted'
sendgrid = require '../sendgrid'
config = require '../../server_config'

{ STARTER_LICENSE_COURSE_IDS } = require '../../app/core/constants'
{formatDollarValue} = require '../../app/core/utils'

cutoffDate = new Date(2015,11,11)
cutoffID = mongoose.Types.ObjectId(Math.floor(cutoffDate / 1000).toString(16)+'0000000000000000')

module.exports =
  # Create a prepaid manually (as an admin or licensor)
  post: wrap (req, res) ->
    validTypes = ['course', 'starter_license']
    unless req.body.type in validTypes
      throw new errors.UnprocessableEntity("Prepaid type must be one of: #{validTypes}.")
      # TODO: deprecate or refactor other prepaid types

    if req.body.creator
      user = yield User.search(req.body.creator)
      if not user
        throw new errors.NotFound('User not found')
      req.body.creator = user.id

    prepaid = database.initDoc(req, Prepaid)
    database.assignBody(req, prepaid)
    prepaid.set('code', yield Prepaid.generateNewCodeAsync())
    prepaid.set('redeemers', [])
    database.validateDoc(prepaid)
    yield prepaid.save()
    if req.body.creator
      yield delighted.checkTriggerPrepaidAdded user, req.body.type
    res.status(201).send(prepaid.toObject())


  redeem: wrap (req, res) ->
    if not req.user?.isTeacher()
      throw new errors.Forbidden('Must be a teacher to use licenses')

    prepaid = yield database.getDocFromHandle(req, Prepaid)
    if not prepaid
      throw new errors.NotFound('Prepaid not found.')

    user = yield User.findById(req.body?.userID)
    if not user
      throw new errors.NotFound('User not found.')

    unless prepaid.canBeUsedBy(req.user._id)
      throw new errors.Forbidden('You may not redeem licenses from this prepaid')
    unless prepaid.get('type') in ['course', 'starter_license']
      throw new errors.Forbidden('This prepaid is not of type "course" or "starter_license"')
    unless prepaid.canReplaceUserPrepaid(user.get('coursePrepaid'))
      return res.status(200).send(prepaid.toObject({req: req}))

    yield prepaid.redeem(user, req.user._id)

    # return prepaid with new redeemer added locally
    redeemers = _.clone(prepaid.get('redeemers') or [])
    redeemers.push({ date: new Date(), userID: user._id, teacherID: req.user._id })
    prepaid.set('redeemers', redeemers)
    res.status(201).send(prepaid.toObject({req: req}))


  revoke: wrap (req, res) ->
    if not req.user?.isTeacher()
      throw new errors.Forbidden('Must be a teacher to use enrollments')

    prepaid = yield database.getDocFromHandle(req, Prepaid)
    if not prepaid
      throw new errors.NotFound('Prepaid not found.')

    unless prepaid.canBeUsedBy(req.user._id)
      throw new errors.Forbidden('You may not revoke enrollments you do not own.')

    user = yield User.findById(req.body?.userID)

    yield prepaid.revoke(user)

    # return prepaid with new redeemer added locally
    prepaid.set('redeemers', _.filter(prepaid.get('redeemers') or [], (obj) -> not obj.userID.equals(user._id)))
    res.status(200).send(prepaid.toObject({req: req}))

  # Add teachers to a Shared License
  addJoiner: wrap (req, res) ->
    if not req.user?.isTeacher()
      throw new errors.Forbidden('Must be a teacher to share licenses')

    prepaid = yield database.getDocFromHandle(req, Prepaid)
    if not prepaid
      throw new errors.NotFound('Prepaid not found.')

    unless prepaid.get('creator').equals(req.user._id)
      throw new errors.Forbidden('You may not share licenses you do not own.')
    unless prepaid.get('type') is 'course'
      throw new errors.Forbidden('This prepaid is not of type "course".')

    if _.find(prepaid.get('joiners'), (joiner) -> joiner.userID.equals(req.body?.userID)) or req.body?.userID is req.user.id
      throw new errors.UnprocessableEntity("You've already shared these licenses with that teacher.", { i18n: 'share_licenses.already_shared' })

    joiner = yield User.findById(req.body?.userID)
    if not joiner
      throw new errors.NotFound('User not found.')

    if not joiner.isTeacher()
      throw new errors.UnprocessableEntity('User to share with must be a Teacher.', { i181: 'share_licenses.teacher_not_valid' })

    query =
      _id: prepaid._id
    update = { $addToSet: { joiners : { userID: joiner._id } }}
    result = yield Prepaid.update(query, update)

    context =
      templateId: sendgrid.templates.share_licenses_joiner
      to:
        email: joiner.get('email')
        name: joiner.broadName()
      from:
        email: config.mail.username
        name: 'CodeCombat'
      subject: "#{req.user.broadName()} has shared licenses with you!"
      substitutions:
        joiner_email: joiner.get('email')
        creator_email: req.user.get('email')
        creator_name: req.user.broadName()
    try
      yield sendgrid.api.send context
    catch err
      console.error "Error sending license share email:", err
    res.status(201).send(prepaid.toObject({req}))

  fetchJoiners: wrap (req, res) ->
    if not req.user?.isTeacher()
      throw new errors.Forbidden('Must be a teacher to fetch joiners for a license.')

    prepaid = yield database.getDocFromHandle(req, Prepaid)
    if not prepaid
      throw new errors.NotFound('Prepaid not found.')

    unless prepaid.get('creator').equals(req.user._id)
      throw new errors.Forbidden('You may not fetch the joiners of a license you do not own.')
    unless prepaid.get('type') is 'course'
      throw new errors.Forbidden('This prepaid is not of type "course".')

    joinerIDs = (prepaid.get('joiners') or []).map((j)->j.userID)

    joiners = (yield joinerIDs.map (id) ->
      User.findById(id)
    ).map (user) ->
      _.pick(user.toObject(), ['_id', 'email', 'name', 'firstName', 'lastName'])

    res.status(200).send(joiners)

  fetchCreator: wrap (req, res) ->
    unless req.user
      throw new errors.Unauthorized()
    unless req.user.isAdmin() or req.user.isTeacher()
      throw new errors.Forbidden()
    prepaid = yield database.getDocFromHandle(req, Prepaid)
    unless prepaid
      throw new errors.NotFound('No prepaid with that ID found')
    unless prepaid.canBeUsedBy(req.user._id) or req.user.isAdmin()
      throw new errors.Forbidden('You can only look up the owner of prepaids that have been shared with you.')
    creator = yield User.findOne({ _id: prepaid.get('creator') })
    res.status(200).send(_.pick(creator.toObject(), ['_id', 'email', 'name', 'firstName', 'lastName']))

  fetchByCreator: wrap (req, res, next) ->
    creator = req.query.creator
    return next() if not creator
    unless req.user.isAdmin() or req.user.isLicensor() or creator is req.user.id
      throw new errors.Forbidden('Must be logged in as given creator')
    unless database.isID(creator)
      throw new errors.UnprocessableEntity('Invalid creator')

    q = {
      _id: { $gt: cutoffID }
      creator: mongoose.Types.ObjectId(creator)
    }
    if req.query.includeShared
      q = {
        _id: { $gt: cutoffID }
        $or: [
          { creator: mongoose.Types.ObjectId(creator) }
          { "joiners.userID": mongoose.Types.ObjectId(creator) }
        ]
      }
    q.type = { $in: ['course', 'starter_license'] } unless req.query.allTypes
    
    prepaids = yield Prepaid.find(q)
    res.send((prepaid.toObject({req: req}) for prepaid in prepaids))

  fetchByClient: wrap (req, res, next) ->
    clientId = req.query.client
    return next() if not clientId

    unless database.isID(clientId)
      throw new errors.UnprocessableEntity('Invalid client Id')

    q = {
      _id: { $gt: cutoffID }
      clientCreator: mongoose.Types.ObjectId(clientId)
    }
    prepaids = yield Prepaid.find(q)
    res.send(prepaid.toObject({req: req}) for prepaid in prepaids)


  fetchActiveSchoolLicenses: wrap (req, res) ->
    throw new errors.Forbidden('Must be logged in as given creator') unless req.user.isAdmin() or creator is req.user.id
    licenseEndMonths = parseInt(req.query?.licenseEndMonths or 6)
    licenseLimit = parseInt(req.query?.licenseLimit or 0)
    latestEndDate = new Date()
    latestEndDate.setUTCMonth(latestEndDate.getUTCMonth() + licenseEndMonths)
    query = {$and: [{type: 'course'}, {endDate: {$gt: new Date().toISOString()}}, {endDate: {$lt: latestEndDate.toISOString()}}, {$where: 'this.redeemers && this.redeemers.length > 0'}, {creator: {$exists: true}}]}
    # query.$and.push({creator: mongoose.Types.ObjectId('57b358055e49e52400b39ea1')})
    prepaids = yield Prepaid.find(query, {creator: 1, startDate: 1, endDate: 1, maxRedeemers: 1, redeemers: 1}).limit(licenseLimit).lean()
    # console.log new Date().toISOString(), 'fetchActiveSchoolLicenses prepaids', prepaids.length
    teacherIds = []
    teacherIds.push(prepaid.creator) for prepaid in prepaids
    teachers = yield User.find({_id: {$in: teacherIds}}, {_id: 1, permissions: 1, name: 1, emailLower: 1}).lean()
    adminMap = {}
    adminMap[teacher._id.toString()] = true for teacher in teachers when 'admin' in (teacher.permissions or [])
    teacherIds = _.reject(teacherIds, (id) -> adminMap[id.toString()])

    # Fetch classrooms with no paid courses assigned
    classrooms = yield Classroom.find({ownerID: {$in: teacherIds}}, {name: 1, ownerID: 1, members: 1, courses: 1}).lean()
    classroomIDs = (classroom._id for classroom in classrooms)
    courses = yield Course.find({free: true}).lean()
    freeCourseIDs = (course._id for course in courses)
    paidCourseInstances = yield CourseInstance.find({ classroomID: {$in: classroomIDs}, courseID: {$nin: freeCourseIDs} }).select('_id classroomID').lean()
    paidClassroomIDs = (courseInstance.classroomID.toString() for courseInstance in paidCourseInstances)
    paidClassroomIDs = _.uniq(paidClassroomIDs)
    classrooms = _.filter(classrooms, (c) -> c._id.toString() in paidClassroomIDs)

    res.status(200).send({classrooms, prepaids, teachers})

  fetchActiveSchools: wrap (req, res) ->
    unless req.user.isAdmin()
      throw new errors.Forbidden('Must be logged in as given creator')
    prepaids = yield Prepaid.find({type: 'course'}, {creator: 1, properties: 1, startDate: 1, endDate: 1, maxRedeemers: 1, redeemers: 1}).lean()
    userPrepaidsMap = {}
    today = new Date()
    userIDs = []
    redeemerIDs = []
    redeemerPrepaidMap = {}
    for prepaid in prepaids
      continue if new Date(prepaid.endDate ? prepaid.properties?.endDate ? '2000') < today
      continue if new Date(prepaid.endDate) < new Date(prepaid.startDate)
      continue unless prepaid.creator
      userPrepaidsMap[prepaid.creator.valueOf()] ?= []
      userPrepaidsMap[prepaid.creator.valueOf()].push(prepaid)
      # NOTE: May not correctly account for shared licenses
      userIDs.push prepaid.creator
      for joiner in prepaid.joiners ? []
        userIDs.push joiner.userID + ''
      for redeemer in prepaid.redeemers ? []
        redeemerIDs.push redeemer.userID + ""
        redeemerPrepaidMap[redeemer.userID + ""] = prepaid._id.valueOf()

    # Find recently created level sessions for redeemers
    lastMonth = new Date()
    lastMonth.setUTCDate(lastMonth.getUTCDate() - 30)
    levelSessions = yield LevelSession.find({$and: [{created: {$gte: lastMonth}}, {creator: {$in: redeemerIDs}}]}, {creator: 1}).lean()
    prepaidActivityMap = {}
    for levelSession in levelSessions
      prepaidActivityMap[redeemerPrepaidMap[levelSession.creator.valueOf()]] ?= 0
      prepaidActivityMap[redeemerPrepaidMap[levelSession.creator.valueOf()]]++

    trialRequests = yield TrialRequest.find({$and: [{type: 'course'}, {applicant: {$in: userIDs}}]}, {applicant: 1, properties: 1}).lean()
    schoolPrepaidsMap = {}
    for trialRequest in trialRequests
      school = trialRequest.properties?.nces_name ? trialRequest.properties?.organization ? trialRequest.properties?.school
      continue unless school
      if userPrepaidsMap[trialRequest.applicant.valueOf()]?.length > 0
        schoolPrepaidsMap[school] ?= []
        for prepaid in userPrepaidsMap[trialRequest.applicant.valueOf()]
          schoolPrepaidsMap[school].push prepaid

    res.send({prepaidActivityMap, schoolPrepaidsMap})

  # Separate endpoint from legacy prepaid purchase handler
  purchaseStarterLicenses: wrap (req, res) ->
    if req.body.type not in ['starter_license']
      throw new errors.Forbidden("License type invalid: #{req.body.type}")

    creator = req.user
    maxRedeemers = parseInt(req.body.maxRedeemers)
    months = parseInt(req.body.months)
    token = req.body.stripe?.token
    timestamp = req.body.stripe?.timestamp

    if isNaN(maxRedeemers) or maxRedeemers < 1
      throw new errors.UnprocessableEntity("Invalid number of licenses to buy: #{maxRedeemers}")

    alreadyOwnedStarterLicenses = yield Prepaid.find({
      creator: creator._id
      type: 'starter_license'
    }).exec()
    alreadyOwnedStarterLicenseCount = alreadyOwnedStarterLicenses.map((prepaid) -> prepaid.get('maxRedeemers')).reduce(((a,b) -> a+b), 0)

    if maxRedeemers + alreadyOwnedStarterLicenseCount > Prepaid.MAX_STARTER_LICENSES
      throw new errors.Forbidden('You cannot own more than 75 starter licenses.')

    if not (token or creator.isAdmin())
      throw new errors.UnprocessableEntity('Missing required Stripe token')

    if creator.isAdmin()
      yield createStarterLicense({ creator: creator.id, maxRedeemers })
      res.status(200).send(prepaid)

    else
      product = yield Product.findOne({ name: 'starter_license' })

      try
        customer = yield StripeUtils.getCustomerAsync(creator, token)
      catch e
        logError(creator, "Stripe getCustomer error: #{JSON.stringify(err)}")
      metadata =
        type: 'starter_license'
        userID: creator.id
        timestamp: parseInt(timestamp)
        maxRedeemers: maxRedeemers
        productID: "prepaid starter_license"

      totalAmount = maxRedeemers * product.get('amount')
      try
        charge = yield StripeUtils.createChargeAsync(creator, totalAmount, metadata)
        prepaid = yield createStarterLicense({ creator: creator.id, maxRedeemers })
        payment = yield StripeUtils.createPaymentAsync(creator, charge, {prepaidID: prepaid._id})
        msg = "#{creator.get('email')} paid #{formatDollarValue(payment.get('amount') / 100)} for starter_license prepaid redeemers=#{maxRedeemers}"
        slack.sendSlackMessage msg, ['starters']
        res.status(200).send(prepaid)
      catch err
        logError(creator, "getCustomer error: #{JSON.stringify(err)}")
        throw(err)

createStarterLicense = co.wrap ({ creator, maxRedeemers }) ->
  yield createPrepaid({
    creator: creator
    type: 'starter_license'
    maxRedeemers, properties: {}
    startDate: moment().toISOString()
    endDate: moment().add(6, 'months').toISOString()
    includedCourseIDs: STARTER_LICENSE_COURSE_IDS
  })

createPrepaid = co.wrap ({ creator, type, maxRedeemers, properties, startDate, endDate, includedCourseIDs }) ->
  options =
    creator: creator
    type: type
    code: yield Prepaid.generateNewCodeAsync()
    maxRedeemers: parseInt(maxRedeemers)
    properties: properties
    redeemers: []
    startDate: startDate
    endDate: endDate
    includedCourseIDs: includedCourseIDs
  prepaid = new Prepaid(options)
  yield prepaid.save()
  return prepaid

logError = (user, msg) ->
  console.warn("Prepaid Error: [#{user.get('slug')} (#{user.id})] '#{msg}'")
