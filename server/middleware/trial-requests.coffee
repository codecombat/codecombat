config = require '../../server_config'
utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
TrialRequest = require '../models/TrialRequest'
User = require '../models/User'
delighted = require '../delighted'

module.exports =
  post: wrap (req, res) ->
    if req.user.isAnonymous()
      email = req.body?.properties?.email
      throw new errors.UnprocessableEntity('Email not provided.') unless email
      email = email.toLowerCase()
      user = yield User.findOne({emailLower: email})
      throw new errors.Conflict('User with this email already exists.', { i18n: 'server_error.email_taken' }) if user

    trialRequest = yield TrialRequest.findOne({applicant: req.user._id})
    if not trialRequest
      trialRequest = database.initDoc(req, TrialRequest)
      trialRequest.set 'applicant', req.user._id
      trialRequest.set 'created', new Date()
    trialRequest.set 'status', 'submitted'
    attrs = _.pick req.body, 'properties', 'type'
    # Grab name from user if we have it on user and not already recorded
    attrs.properties.firstName ||= firstName if firstName = req.user.get('firstName')
    attrs.properties.lastName ||= lastName if lastName = req.user.get('lastName')
    trialRequest.set 'properties', _.extend {}, trialRequest.get('properties'), attrs.properties
    trialRequest.set 'type', attrs.type
    database.validateDoc(trialRequest)
    trialRequest = yield trialRequest.save()
    res.status(201).send(trialRequest.toObject({req: req}))

  put: wrap (req, res) ->
    trialRequest = yield database.getDocFromHandle(req, TrialRequest)
    throw new errors.NotFound('Trial Request not found.') if not trialRequest
    database.assignBody(req, trialRequest)
    trialRequest.set('reviewDate', new Date())
    trialRequest.set('reviewer', req.user.get('_id'))
    database.validateDoc(trialRequest)
    trialRequest = yield trialRequest.save()
    res.status(200).send(trialRequest.toObject({req: req}))

  fetchByApplicant: wrap (req, res, next) ->
    applicantID = req.query.applicant
    return next() unless applicantID
    throw new errors.UnprocessableEntity('Bad applicant id') unless utils.isID(applicantID)
    throw new errors.Forbidden('May not fetch for anyone but yourself') unless req.user?.id is applicantID or req.user?.isAdmin()
    trialRequests = yield TrialRequest.find({applicant: mongoose.Types.ObjectId(applicantID)})
    trialRequests = (tr.toObject({req: req}) for tr in trialRequests)
    res.status(200).send(trialRequests)

  getUsers: wrap (req, res, next) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    limit = parseInt(req.query.options?.limit ? 0)
    query = {status: {$ne: 'denied'}}
    if req.query.options?.beforeId
      beforeId = mongoose.Types.ObjectId(req.query.options.beforeId)
      query = {$and: [{_id: {$lt: beforeId}}, query]}
    trialRequests = yield TrialRequest.find(query).sort({_id: -1}).limit(limit).select('applicant properties').lean()
    res.status(200).send(trialRequests)
