_ = require 'lodash'
co = require 'co'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
parse = require '../commons/parse'
request = require 'request'
mongoose = require 'mongoose'
User = require '../models/User'
Classroom = require '../models/Classroom'


module.exports =
  fetchByGPlusID: wrap (req, res, next) ->
    gpID = req.query.gplusID
    gpAT = req.query.gplusAccessToken
    return next() unless gpID and gpAT

    dbq = User.find()
    dbq.select(parse.getProjectFromReq(req))
    url = "https://www.googleapis.com/oauth2/v2/userinfo?access_token=#{gpAT}"
    [googleRes, body] = yield request.getAsync(url, {json: true})
    idsMatch = gpID is body.id
    throw new errors.UnprocessableEntity('Invalid G+ Access Token.') unless idsMatch
    user = yield User.findOne({gplusID: gpID})
    throw new errors.NotFound('No user with that G+ ID') unless user
    res.status(200).send(user.toObject({req: req}))

  fetchByFacebookID: wrap (req, res, next) ->
    fbID = req.query.facebookID
    fbAT = req.query.facebookAccessToken
    return next() unless fbID and fbAT

    dbq = User.find()
    dbq.select(parse.getProjectFromReq(req))
    url = "https://graph.facebook.com/me?access_token=#{fbAT}"
    [facebookRes, body] = yield request.getAsync(url, {json: true})
    idsMatch = fbID is body.id
    throw new errors.UnprocessableEntity('Invalid Facebook Access Token.') unless idsMatch
    user = yield User.findOne({facebookID: fbID})
    throw new errors.NotFound('No user with that Facebook ID') unless user
    res.status(200).send(user.toObject({req: req}))

  removeFromClassrooms: wrap (req, res, next) ->
    yield req.user.removeFromClassrooms()
    next()

  remainTeacher: wrap (req, res, next) ->
    yield req.user.removeFromClassrooms()
    user = yield User.findById req.user.id
    res.status(200).send(user.toObject({req: req}))

  becomeStudent: wrap (req, res, next) ->
    userID = mongoose.Types.ObjectId(req.user.id)
    yield Classroom.remove({ ownerID: userID }, false)
    userID = mongoose.Types.ObjectId(req.user.id)
    yield User.update({ _id: userID }, { $set: { "role": "student" } })
    user = yield User.findById req.user.id
    res.status(200).send(user.toObject({req: req}))
