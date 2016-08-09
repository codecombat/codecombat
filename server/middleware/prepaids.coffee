wrap = require 'co-express'
errors = require '../commons/errors'
database = require '../commons/database'
mongoose = require 'mongoose'
LevelSession = require '../models/LevelSession'
Prepaid = require '../models/Prepaid'
TrialRequest = require '../models/TrialRequest'
User = require '../models/User'

cutoffDate = new Date(2015,11,11)
cutoffID = mongoose.Types.ObjectId(Math.floor(cutoffDate/1000).toString(16)+'0000000000000000')

module.exports =
  post: wrap (req, res) ->
    validTypes = ['course']
    unless req.body.type in validTypes
      throw new errors.UnprocessableEntity("type must be on of: #{validTypes}.")
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

    if prepaid._id.getTimestamp().getTime() < cutoffDate.getTime()
      throw new errors.Forbidden('Cannot redeem from prepaids older than November 11, 2015')
    unless prepaid.get('creator').equals(req.user._id)
      throw new errors.Forbidden('You may not redeem licenses from this prepaid')
    if prepaid.get('redeemers')? and _.size(prepaid.get('redeemers')) >= prepaid.get('maxRedeemers')
      throw new errors.Forbidden('This prepaid is exhausted')
    unless prepaid.get('type') is 'course'
      throw new errors.Forbidden('This prepaid is not of type "course"')
    if prepaid.get('endDate') and new Date(prepaid.get('endDate')) < new Date()
      throw new errors.Forbidden('This prepaid is expired')

    user = yield User.findById(req.body?.userID)
    if not user
      throw new errors.NotFound('User not found.')

    if user.isEnrolled()
      return res.status(200).send(prepaid.toObject({req: req}))
    if user.isTeacher()
      throw new errors.Forbidden('Teachers may not be enrolled')

    query =
      _id: prepaid._id
      'redeemers.userID': { $ne: user._id }
      $where: "this.maxRedeemers > 0 && (!this.redeemers || this.redeemers.length < #{prepaid.get('maxRedeemers')})"
    update = { $push: { redeemers : { date: new Date(), userID: user._id } }}
    result = yield Prepaid.update(query, update)
    if result.nModified is 0
      console.error("Prepaid redeem error: [#{req.user.get('slug')} (#{req.user._id})] 'POST prepaid redeemer lost race on maxRedeemers'")
      throw new errors.Forbidden('This prepaid is exhausted')

    update = {
      $set: {
        coursePrepaid: {
          _id: prepaid._id
          startDate: prepaid.get('startDate')
          endDate: prepaid.get('endDate')
        }
      }
    }
    if not user.get('role')
      update.$set.role = 'student'
    yield user.update(update)

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
      type: 'course'
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
