utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
Classroom = require '../classrooms/Classroom'
parse = require '../commons/parse'

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
