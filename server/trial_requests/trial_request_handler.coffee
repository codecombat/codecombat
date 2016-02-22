async = require 'async'
log = require 'winston'
mongoose = require 'mongoose'
Handler = require '../commons/Handler'
TrialRequest = require './TrialRequest'
User = require '../users/User'

TrialRequestHandler = class TrialRequestHandler extends Handler
  modelClass: TrialRequest
  jsonSchema: require '../../app/schemas/models/trial_request.schema'

  hasAccess: (req) ->
    req.method in ['POST'] or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    return false unless document?
    return true if req.user?.isAdmin()
    false

  makeNewInstance: (req) ->
    instance = super(req)
    instance.set 'applicant', req.user._id
    instance.set 'created', new Date()
    instance.set 'status', 'submitted'
    instance
    
  post: (req, res) ->
    return @sendForbiddenError(res) unless req.user?
    if req.user.isAnonymous()
      email = req.body?.properties?.email
      return @sendBadInputError(res, 'email not provided') unless email
      User.findOne({emailLower: req.body.properties.email}).exec (err, user) =>
        return @sendDatabaseError(res, err) if err
        return @sendError(res, 409, 'User with this email already exists.') if user
        super(req, res)
    else
      super(req, res)

  put: (req, res, id) ->
    req.body.reviewDate = new Date()
    req.body.reviewer = req.user.get('_id')
    super(req, res, id)

  getByRelationship: (req, res, args...) ->
    return @getOwn(req, res) if args[1] is 'own'
    super(arguments...)

  getOwn: (req, res) ->
    return @sendForbiddenError(res) unless req.user?
    TrialRequest.find {applicant: req.user.get('_id')}, (err, documents) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, documents)

module.exports = new TrialRequestHandler()
