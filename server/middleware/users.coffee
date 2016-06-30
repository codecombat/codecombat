_ = require 'lodash'
co = require 'co'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
parse = require '../commons/parse'
request = require 'request'
mongoose = require 'mongoose'
sendwithus = require '../sendwithus'
User = require '../models/User'
Classroom = require '../models/Classroom'
facebook = require '../lib/facebook'
gplus = require '../lib/gplus'

module.exports =
  fetchByGPlusID: wrap (req, res, next) ->
    gpID = req.query.gplusID
    gpAT = req.query.gplusAccessToken
    return next() unless gpID and gpAT

    googleResponse = yield gplus.fetchMe(gpAT)
    idsMatch = gpID is googleResponse.id
    throw new errors.UnprocessableEntity('Invalid G+ Access Token.') unless idsMatch

    dbq = User.find()
    dbq.select(parse.getProjectFromReq(req))
    user = yield User.findOne({gplusID: gpID})
    throw new errors.NotFound('No user with that G+ ID') unless user
    res.status(200).send(user.toObject({req: req}))

  fetchByFacebookID: wrap (req, res, next) ->
    fbID = req.query.facebookID
    fbAT = req.query.facebookAccessToken
    return next() unless fbID and fbAT

    facebookResponse = yield facebook.fetchMe(fbAT)
    idsMatch = fbID is facebookResponse.id
    throw new errors.UnprocessableEntity('Invalid Facebook Access Token.') unless idsMatch
    
    dbq = User.find()
    dbq.select(parse.getProjectFromReq(req))
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

  verifyEmailAddress: wrap (req, res, next) ->
    user = yield User.findOne({ _id: mongoose.Types.ObjectId(req.params.userID) })
    [timestamp, hash] = req.params.verificationCode.split(':')
    unless user
      throw new errors.UnprocessableEntity('User not found')
    unless req.params.verificationCode is user.verificationCode(timestamp)
      throw new errors.UnprocessableEntity('Verification code does not match')
    yield User.update({ _id: user.id }, { emailVerified: true })
    res.status(200).send({ role: user.get('role') })

  resetEmailVerifiedFlag: wrap (req, res, next) ->
    newEmail = req.body.email
    _id = mongoose.Types.ObjectId(req.body._id)
    if newEmail
      user = yield User.findOne({ _id })
      oldEmail = user.get('email')
      if newEmail isnt oldEmail
        yield User.update({ _id }, { $set: { emailVerified: false } })
    next()

  sendVerificationEmail: wrap (req, res, next) ->
    user = yield User.findById(req.params.userID)
    timestamp = (new Date).getTime()
    if not user
      throw new errors.NotFound('User not found')
    context =
      email_id: sendwithus.templates.verify_email
      recipient:
        address: user.get('email')
        name: user.broadName()
      email_data:
        name: user.broadName()
        verify_link: "http://codecombat.com/user/#{user._id}/verify/#{user.verificationCode(timestamp)}"
    sendwithus.api.send context, (err, result) ->
    res.status(200).send({})

  getStudents: wrap (req, res, next) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    students = yield User.find({$and: [{schoolName: {$exists: true}}, {schoolName: {$ne: ''}}, {anonymous: false}]}).select('schoolName').lean()
    res.status(200).send(students)

  getTeachers: wrap (req, res, next) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    teacherRoles = ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent']
    teachers = yield User.find(anonymous: false, role: {$in: teacherRoles}).select('').lean()
    res.status(200).send(teachers)
    
  signupWithPassword: wrap (req, res) ->
    unless req.user.isAnonymous()
      throw new errors.Forbidden('You are already signed in.')
      
    { password, email } = req.body
    unless _.all([password, email])
      throw new errors.UnprocessableEntity('Requires password and email')

    if yield User.findByEmail(email)
      throw new errors.Conflict('Email already taken')

    req.user.set({ password, email, anonymous: false })
    try
      yield req.user.save()
    catch e
      if e.code is 11000 # Duplicate key error
        throw new errors.Conflict('Email already taken')
      else
        throw e

    req.user.sendWelcomeEmail()
    res.status(200).send(req.user.toObject({req: req}))
    
  signupWithFacebook: wrap (req, res) ->
    unless req.user.isAnonymous()
      throw new errors.Forbidden('You are already signed in.')
    
    { facebookID, facebookAccessToken, email } = req.body
    unless _.all([facebookID, facebookAccessToken, email])
      throw new errors.UnprocessableEntity('Requires facebookID, facebookAccessToken and email')
    
    facebookResponse = yield facebook.fetchMe(facebookAccessToken)
    emailsMatch = email is facebookResponse.email
    idsMatch = facebookID is facebookResponse.id
    unless emailsMatch and idsMatch
      throw new errors.UnprocessableEntity('Invalid facebookAccessToken')
    
    req.user.set({ facebookID, email, anonymous: false })
    try
      yield req.user.save()
    catch e
      if e.code is 11000 # Duplicate key error
        throw new errors.Conflict('Email already taken')
      else
        throw e
        
    req.user.sendWelcomeEmail()
    res.status(200).send(req.user.toObject({req: req}))

  signupWithGPlus: wrap (req, res) ->
    unless req.user.isAnonymous()
      throw new errors.Forbidden('You are already signed in.')
    
    { gplusID, gplusAccessToken, email } = req.body
    unless _.all([gplusID, gplusAccessToken, email])
      throw new errors.UnprocessableEntity('Requires gplusID, gplusAccessToken and email')
    
    gplusResponse = yield gplus.fetchMe(gplusAccessToken)
    emailsMatch = email is gplusResponse.email
    idsMatch = gplusID is gplusResponse.id
    
    unless emailsMatch and idsMatch
      throw new errors.UnprocessableEntity('Invalid gplusAccessToken')
    
    req.user.set({ gplusID, email, anonymous: false })
    try
      yield req.user.save()
    catch e
      if e.code is 11000 # Duplicate key error
        throw new errors.Conflict('Email already taken')
      else
        throw e

    req.user.sendWelcomeEmail()
    res.status(200).send(req.user.toObject({req: req}))
