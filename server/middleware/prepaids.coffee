wrap = require 'co-express'
co = require 'co'
errors = require '../commons/errors'
database = require '../commons/database'
mongoose = require 'mongoose'
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
{ STARTER_LICENSE_COURSE_IDS } = require '../../app/core/constants'

cutoffDate = new Date(2015,11,11)
cutoffID = mongoose.Types.ObjectId(Math.floor(cutoffDate/1000).toString(16)+'0000000000000000')

module.exports =
  # Create a prepaid manually (as an admin)
  post: wrap (req, res) ->
    validTypes = ['course']
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

    unless prepaid.get('creator').equals(req.user._id)
      throw new errors.Forbidden('You may not redeem licenses from this prepaid')
    unless prepaid.get('type') in ['course', 'starter_license']
      throw new errors.Forbidden('This prepaid is not of type "course" or "starter_license"')
    if user.isEnrolled()
      return res.status(200).send(prepaid.toObject({req: req}))

    yield prepaid.redeem(user)
      
    # return prepaid with new redeemer added locally
    redeemers = _.clone(prepaid.get('redeemers') or [])
    redeemers.push({ date: new Date(), userID: user._id })
    prepaid.set('redeemers', redeemers)
    res.status(201).send(prepaid.toObject({req: req}))

  fetchByCreator: wrap (req, res, next) ->
    creator = req.query.creator
    return next() if not creator

    unless req.user.isAdmin() or creator is req.user.id
      throw new errors.Forbidden('Must be logged in as given creator')
    unless database.isID(creator)
      throw new errors.UnprocessableEntity('Invalid creator')

    q = {
      _id: { $gt: cutoffID }
      creator: mongoose.Types.ObjectId(creator)
      type: { $in: ['course', 'starter_license'] }
    }

    prepaids = yield Prepaid.find(q)
    res.send((prepaid.toObject({req: req}) for prepaid in prepaids))

  fetchActiveSchools: wrap (req, res) ->
    unless req.user.isAdmin() or creator is req.user.id
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
      userPrepaidsMap[prepaid.creator.valueOf()] ?= []
      userPrepaidsMap[prepaid.creator.valueOf()].push(prepaid)
      userIDs.push prepaid.creator
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
        msg = "#{creator.get('email')} paid #{payment.get('amount')} for starter_license prepaid redeemers=#{maxRedeemers}"
        slack.sendSlackMessage msg, ['tower']
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
