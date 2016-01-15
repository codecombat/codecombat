async = require 'async'
mongoose = require 'mongoose'
Handler = require '../commons/Handler'
Classroom = require './Classroom'
User = require '../users/User'
sendwithus = require '../sendwithus'
utils = require '../lib/utils'
UserHandler = require '../users/user_handler'

ClassroomHandler = class ClassroomHandler extends Handler
  modelClass: Classroom
  jsonSchema: require '../../app/schemas/models/classroom.schema'
  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE']

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

  makeNewInstance: (req) ->
    instance = super(req)
    instance.set 'ownerID', req.user._id
    instance.set 'members', []
    instance

  getByRelationship: (req, res, args...) ->
    method = req.method.toLowerCase()
    return @inviteStudents(req, res, args[0]) if args[1] is 'invite-members'
    return @joinClassroomAPI(req, res, args[0]) if method is 'post' and args[1] is 'members'
    return @removeMember(req, res, args[0]) if req.method is 'DELETE' and args[1] is 'members'
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

  joinClassroomAPI: (req, res, classroomID) ->
    return @sendBadInputError(res, 'Need an object with a code') unless req.body?.code
    code = req.body.code.toLowerCase()
    Classroom.findOne {code: code}, (err, classroom) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) if not classroom
      members = _.clone(classroom.get('members'))
      if _.any(members, (memberID) -> memberID.equals(req.user.get('_id')))
        return @sendSuccess(res, @formatEntity(req, classroom))
      update = { $push: { members : req.user.get('_id')}}
      classroom.update update, (err) =>
        return @sendDatabaseError(res, err) if err
        members.push req.user.get('_id')
        classroom.set('members', members)
        return @sendSuccess(res, @formatEntity(req, classroom))

  removeMember: (req, res, classroomID) ->
    userID = req.body.userID
    return @sendBadInputError(res, 'Input must be a MongoDB ID') unless utils.isID(userID)
    Classroom.findById classroomID, (err, classroom) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res, 'Classroom referenced by course instance not found') unless classroom
      return @sendForbiddenError(res) unless _.any(classroom.get('members'), (memberID) -> memberID.toString() is userID)
      ownsClassroom = classroom.get('ownerID').equals(req.user.get('_id'))
      removingSelf = userID is req.user.id
      return @sendForbiddenError(res) unless ownsClassroom or removingSelf
      alreadyNotInClassroom = not _.any classroom.get('members') or [], (memberID) -> memberID.toString() is userID
      return @sendSuccess(res, @formatEntity(req, classroom)) if alreadyNotInClassroom
      members = _.clone(classroom.get('members'))
      members = (m for m in members when m.toString() isnt userID)
      classroom.set('members', members)
      classroom.save (err, classroom) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res, @formatEntity(req, classroom))

  formatEntity: (req, doc) ->
    if req.user?.isAdmin() or req.user?.get('_id').equals(doc.get('ownerID'))
      return doc.toObject()
    return _.omit(doc.toObject(), 'code', 'codeCamel')

  inviteStudents: (req, res, classroomID) ->
    if not req.body.emails
      return @sendBadInputError(res, 'Emails not included')

    Classroom.findById classroomID, (err, classroom) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless classroom
      return @sendForbiddenError(res) unless classroom.get('ownerID').equals(req.user.get('_id'))

      for email in req.body.emails
        context =
          email_id: sendwithus.templates.course_invite_email
          recipient:
            address: email
          email_data:
            class_name: classroom.get('name')
            join_link: "https://codecombat.com/courses?_cc=" + (classroom.get('codeCamel') or classroom.get('code'))
        sendwithus.api.send context, _.noop
      return @sendSuccess(res, {})

  get: (req, res) ->
    if ownerID = req.query.ownerID
      return @sendForbiddenError(res) unless req.user and (req.user.isAdmin() or ownerID is req.user.id)
      return @sendBadInputError(res, 'Bad ownerID') unless utils.isID ownerID
      Classroom.find {ownerID: mongoose.Types.ObjectId(ownerID)}, (err, classrooms) =>
        return @sendDatabaseError(res, err) if err
        return @sendSuccess(res, (@formatEntity(req, classroom) for classroom in classrooms))
    else if memberID = req.query.memberID
      return @sendForbiddenError(res) unless req.user and (req.user.isAdmin() or memberID is req.user.id)
      return @sendBadInputError(res, 'Bad memberID') unless utils.isID memberID
      Classroom.find {members: mongoose.Types.ObjectId(memberID)}, (err, classrooms) =>
        return @sendDatabaseError(res, err) if err
        return @sendSuccess(res, (@formatEntity(req, classroom) for classroom in classrooms))
    else if code = req.query.code
      code = code.toLowerCase()
      Classroom.findOne {code: code}, (err, classroom) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless classroom
        return @sendSuccess(res, @formatEntity(req, classroom))
    else
      super(arguments...)


module.exports = new ClassroomHandler()
