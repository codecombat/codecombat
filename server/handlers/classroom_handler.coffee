async = require 'async'
mongoose = require 'mongoose'
Handler = require '../commons/Handler'
Classroom = require './../models/Classroom'
User = require '../models/User'
utils = require '../lib/utils'
log = require 'winston'
UserHandler = require './user_handler'

ClassroomHandler = class ClassroomHandler extends Handler
  modelClass: Classroom
  jsonSchema: require '../../app/schemas/models/classroom.schema'
  allowedMethods: ['GET', 'PUT', 'DELETE']

  hasAccess: (req) ->
    return false unless req.user
    return true if req.method is 'GET'
    req.method in @allowedMethods or req.user?.isAdmin()

  hasAccessToDocument: (req, document, method=null) ->
    return false unless document?
    return true if req.user?.isAdmin()
    return true if document.get('ownerID')?.equals req.user?._id
    isGet = (method or req.method).toLowerCase() is 'get'
    isMember = _.any(document.get('members') or [], (memberID) -> memberID.equals(req.user.get('_id')))
    return true if isGet and isMember
    false

  getByRelationship: (req, res, args...) ->
    return @getMembersAPI(req, res, args[0]) if args[1] is 'members'
    super(arguments...)

  getMembersAPI: (req, res, classroomID) ->
    Classroom.findById classroomID, (err, classroom) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless classroom
      memberIDs = classroom.get('members') ? []
      User.find {_id: {$in: memberIDs}}, (err, users) =>
        return @sendDatabaseError(res, err) if err
        cleandocs = (UserHandler.formatEntity(req, doc) for doc in users)
        @sendSuccess(res, cleandocs)

  formatEntity: (req, doc) ->
    if req.user?.isAdmin() or req.user?.get('_id').equals(doc.get('ownerID'))
      return doc.toObject()
    return _.omit(doc.toObject(), 'code', 'codeCamel')

  get: (req, res) ->
    if ownerID = req.query.ownerID
      unless req.user and (req.user.isAdmin() or ownerID is req.user.id)
        log.debug "classroom_handler.get: ownerID (#{ownerID}) must be yourself (#{req.user?.id})"
        return @sendForbiddenError(res)
      return @sendBadInputError(res, 'Bad ownerID') unless utils.isID ownerID
      Classroom.find {ownerID: mongoose.Types.ObjectId(ownerID)}, (err, classrooms) =>
        return @sendDatabaseError(res, err) if err
        return @sendSuccess(res, (@formatEntity(req, classroom) for classroom in classrooms))
    else if memberID = req.query.memberID
      unless req.user and (req.user.isAdmin() or memberID is req.user.id)
        log.debug "classroom_handler.get: memberID (#{memberID}) must be yourself (#{req.user?.id})"
        return @sendForbiddenError(res)
      return @sendBadInputError(res, 'Bad memberID') unless utils.isID memberID
      Classroom.find {members: mongoose.Types.ObjectId(memberID)}, (err, classrooms) =>
        return @sendDatabaseError(res, err) if err
        return @sendSuccess(res, (@formatEntity(req, classroom) for classroom in classrooms))
    else if code = req.query.code
      code = code.toLowerCase().replace(/ /g, '')
      Classroom.findOne {code: code}, (err, classroom) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless classroom
        return @sendSuccess(res, @formatEntity(req, classroom))
    else
      super(arguments...)


module.exports = new ClassroomHandler()
