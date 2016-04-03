_ = require 'lodash'
utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
Classroom = require '../classrooms/Classroom'
parse = require '../commons/parse'
LevelSession = require '../levels/sessions/LevelSession'
User = require '../users/User'

module.exports =
  getByOwner: wrap (req, res, next) ->
    options = req.query
    ownerID = options.ownerID
    return next() unless ownerID
    throw new errors.UnprocessableEntity('Bad ownerID') unless utils.isID ownerID
    throw new errors.Unauthorized() unless req.user
    throw new errors.Forbidden('"ownerID" must be yourself') unless req.user.isAdmin() or ownerID is req.user.id
    sanitizedOptions = {}
    unless _.isUndefined(options.archived)
      # Handles when .archived is true, vs false-or-null
      sanitizedOptions.archived = { $ne: not (options.archived is 'true') }
      console.log sanitizedOptions
    dbq = Classroom.find _.merge sanitizedOptions, { ownerID: mongoose.Types.ObjectId(ownerID) }
    dbq.select(parse.getProjectFromReq(req))
    classrooms = yield dbq
    classrooms = (classroom.toObject({req: req}) for classroom in classrooms)
    res.status(200).send(classrooms)

  fetchMemberSessions: wrap (req, res, next) ->
    throw new errors.Unauthorized() unless req.user
    memberLimit = parse.getLimitFromReq(req, {default: 10, max: 100, param: 'memberLimit'})
    memberSkip = parse.getSkipFromReq(req, {param: 'memberSkip'})
    classroom = yield database.getDocFromHandle(req, Classroom)
    throw new errors.NotFound('Classroom not found.') if not classroom
    throw new errors.Forbidden('You do not own this classroom.') unless req.user.isAdmin() or classroom.get('ownerID').equals(req.user._id)
    members = classroom.get('members') or []
    members = members.slice(memberSkip, memberLimit)
    dbqs = []
    select = 'state.complete level creator playtime'
    for member in members
      dbqs.push(LevelSession.find({creator: member.toHexString(), team: {$exists: false}}).select(select).exec())
    results = yield dbqs
    sessions = _.flatten(results)
    res.status(200).send(sessions)
    
  fetchMembers: wrap (req, res, next) ->
    throw new errors.Unauthorized() unless req.user
    memberLimit = parse.getLimitFromReq(req, {default: 10, max: 100, param: 'memberLimit'})
    memberSkip = parse.getSkipFromReq(req, {param: 'memberSkip'})
    classroom = yield database.getDocFromHandle(req, Classroom)
    throw new errors.NotFound('Classroom not found.') if not classroom
    throw new errors.Forbidden('You do not own this classroom.') unless req.user.isAdmin() or classroom.get('ownerID').equals(req.user._id)
    memberIDs = classroom.get('members') or []
    memberIDs = memberIDs.slice(memberSkip, memberLimit)
    
    members = yield User.find({ _id: { $in: memberIDs }}).select(parse.getProjectFromReq(req))
    memberObjects = (member.toObject({ req: req, includedPrivates: ["name", "email"] }) for member in members)
    
    res.status(200).send(memberObjects)
