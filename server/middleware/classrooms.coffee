utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
Classroom = require '../classrooms/Classroom'
parse = require '../commons/parse'
LevelSession = require '../levels/sessions/LevelSession'

module.exports =
  getByOwner: wrap (req, res, next) ->
    ownerID = req.query.ownerID
    return next() unless ownerID
    throw new errors.UnprocessableEntity('Bad ownerID') unless utils.isID ownerID
    throw new errors.Unauthorized() unless req.user
    throw new errors.Forbidden('"ownerID" must be yourself') unless req.user.isAdmin() or ownerID is req.user.id
    dbq = Classroom.find { ownerID: mongoose.Types.ObjectId(ownerID) }
    dbq.select(parse.getProjectFromReq(req))
    classrooms = yield dbq.exec()
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
    select = 'state.complete level creator'
    for member in members
      dbqs.push(LevelSession.find({creator: member}).select(select).exec())
    results = yield dbqs
    sessions = _.flatten(results)
    res.status(200).send(sessions)
    
    