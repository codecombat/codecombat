_ = require 'lodash'
co = require 'co'
countryList = require('country-list')()
errors = require '../commons/errors'
geoip = require '@basicer/geoip-lite'
wrap = require 'co-express'
Promise = require 'bluebird'
parse = require '../commons/parse'
request = require 'request'
mongoose = require 'mongoose'
database = require '../commons/database'
sendwithus = require '../sendwithus'
User = require '../models/User'
Classroom = require '../models/Classroom'
CourseInstance = require '../models/CourseInstance'
facebook = require '../lib/facebook'
gplus = require '../lib/gplus'
TrialRequest = require '../models/TrialRequest'
Achievement = require '../models/Achievement'
UserPollsRecord = require '../models/UserPollsRecord'
EarnedAchievement = require '../models/EarnedAchievement'
log = require 'winston'
LocalMongo = require '../../app/lib/LocalMongo'
LevelSession = require '../models/LevelSession'
config = require '../../server_config'
utils = require '../lib/utils'
CLASubmission = require '../models/CLASubmission'
Prepaid = require '../models/Prepaid'

module.exports =
  fetchByAge: wrap (req, res, next) ->
    # Uses classroom ageRangeMin/Max fields to restrict age
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    minAge = parseInt(req.query.minAge) if req.query.minAge
    maxAge = parseInt(req.query.maxAge) if req.query.maxAge
    if minAge?
      whereStatement = "parseInt(this.ageRangeMin) >= #{minAge}"
      if maxAge?
        whereStatement += "&& parseInt(this.ageRangeMax) <= #{maxAge}"
    else if maxAge?
      whereStatement = "parseInt(this.ageRangeMax) <= #{maxAge}"
    else
      throw new errors.UnprocessableEntity("minAge or maxAge required.")
    classrooms = yield Classroom.find({$and: [{ageRangeMin: {$exists: true}}, {ageRangeMax: {$exists: true}}, {$where: whereStatement}]}, {members: 1}).lean()
    userIds = []
    for c in classrooms
      for id in c.members
        userIds.push(id.toString())
    res.status(200).send(userIds)

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

  fetchByEmail: wrap (req, res, next) ->
    email = req.query.email
    return next() unless email
    if req.user?.isAdmin()
      user = yield User.findOne({ emailLower: email.toLowerCase() })
      throw new errors.NotFound('No user with that email', { errorID: 'no-user-with-that-email' }) unless user
      res.status(200).send(user.toObject({req}))
    else if req.user?.isTeacher()
      user = yield User.findOne({ emailLower: email.toLowerCase() })
      throw new errors.NotFound('No user with that email', { errorID: 'no-user-with-that-email' }) unless user
      throw new errors.Forbidden('Teacher Accounts can only look up other Teacher Accounts.', { errorID: 'cant-fetch-nonteacher-by-email' }) unless user.isTeacher()
      trimUser = _.pick(user.toObject(), ['_id', 'email', 'firstName', 'lastName', 'name'])
      res.status(200).send(trimUser)
    else
      throw new errors.Forbidden('Only admins and teachers can search by email')

  delete: wrap (req, res, userID) ->
    middleware = require '../middleware' # Require here to prevent failed circular definition
    userToDelete = yield database.getDocFromHandle(req, User)
    if not userToDelete
      throw new errors.NotFound('User not found.')
    unless req.user?.isAdmin() or req.user?._id.equals(userToDelete._id)
      throw new errors.Forbidden("Can't delete this user.")

    yield userToDelete.removeFromClassrooms()

    # Delete personal subscription
    if userToDelete.get('stripe.subscriptionID')
      yield middleware.subscriptions.unsubscribeUser(req, userToDelete, false)
    if userToDelete.get('payPal.billingAgreementID')
      yield middleware.subscriptions.cancelPayPalBillingAgreementInternal(req)

    # Delete recipient subscription
    sponsorID = userToDelete.get('stripe.sponsorID')
    if sponsorID
      sponsor = yield User.findById(sponsorID)
      if not sponsor
        throw new errors.UnprocessableEntity("Couldn't find subscription sponsor #{userToDelete.get('stripe.sponsorID')} of user #{userToDelete._id} to delete")
      sponsorObject = sponsor.toObject()
      sponsorObject.stripe.unsubscribeEmail = userToDelete.get('email')
      yield middleware.subscriptions.unsubscribeRecipientAsync(req, res, sponsor, userToDelete)

    # Delete all the user's attributes
    obj = userToDelete.toObject()
    for prop, val of obj
      userToDelete.set(prop, undefined) unless prop is '_id'
    userToDelete.set('dateDeleted', new Date())
    userToDelete.set('deleted', true)

    # Hack to get saving of Users to work. Probably should replace these props with strings
    # so that validation doesn't get hung up on Date objects in the documents.
    delete obj.dateCreated

    yield userToDelete.save()
    res.status(204).send()

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
    yield user.update({ emailVerified: true })
    user.set({ emailVerified: true })
    yield user.updateMailChimp()
    res.status(200).send({ role: user.get('role') })

  sendVerificationEmail: wrap (req, res, next) ->
    user = yield User.findById(req.params.userID)
    timestamp = (new Date).getTime()
    if not user
      throw new errors.NotFound('User not found')
    if not user.get('email')
      throw new errors.UnprocessableEntity('User must have an email address to receive a verification email')
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
    query = $or: [{role: 'student'}, {$and: [{schoolName: {$exists: true}}, {schoolName: {$ne: ''}}, {anonymous: false}]}]
    users = yield User.find(query).select('lastIP').lean()
    for user in users
      if ip = user.lastIP
        user.geo = geoip.lookup(ip)
        if country = user.geo?.country
          user.geo.countryName = countryList.getName(country)
    res.status(200).send(users)

  getTeachers: wrap (req, res, next) ->
    throw new errors.Unauthorized('You must be an administrator.') unless req.user?.isAdmin()
    teacherRoles = ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent']
    users = yield User.find(anonymous: false, role: {$in: teacherRoles}).select('lastIP').lean()
    for user in users
      if ip = user.lastIP
        user.geo = geoip.lookup(ip)
        if country = user.geo?.country
          user.geo.countryName = countryList.getName(country)
    res.status(200).send(users)

  getLeadPriority: wrap (req, res, next) ->
    trialRequest = yield TrialRequest.findOne(applicant: mongoose.Types.ObjectId(req.user.id))
    if trialRequest
      nces_district_students = trialRequest.get('properties').nces_district_students
      numStudents = trialRequest.get('properties').numStudents
      if numStudents in ['101-200', '201-500', '501-1000', '1000+']
        return res.status(200).send({ priority: 'high' })
      else if numStudents in ['11-50', '51-100']
        return res.status(200).send({ priority: 'medium' })
      else if numStudents in ['1-10']
        # this is the only outcome specifically used; determines if we try to sell them starter licenses
        return res.status(200).send({ priority: 'low' })
    return res.status(200).send({ priority: undefined })

  signupWithPassword: wrap (req, res) ->
    unless req.user.isAnonymous()
      throw new errors.Forbidden('You are already signed in.')

    { name, email, password } = req.body
    unless password
      throw new errors.UnprocessableEntity('Requires password')
    if _.isEmpty(name) and _.isEmpty(email)
      throw new errors.UnprocessableEntity('Requires username or email')

    if yield User.findByEmail(email)
      throw new errors.Conflict('Email already taken', { i18n: 'server_error.email_taken' })
    if yield User.findByName(name)
      throw new errors.Conflict('Username already taken', { i18n: 'server_error.username_taken' })

    req.user.set({ name, email, password, anonymous: false })
    yield module.exports.finishSignup(req, res)

  signupWithFacebook: wrap (req, res) ->
    unless req.user.isAnonymous()
      throw new errors.Forbidden('You are already signed in.')

    { facebookID, facebookAccessToken, email, name } = req.body
    unless _.all([facebookID, facebookAccessToken, not _.isEmpty(email)])
      throw new errors.UnprocessableEntity('Requires facebookID, facebookAccessToken, and email')

    if name and yield User.findByName(name)
      throw new errors.Conflict('Username already taken', { i18n: 'server_error.username_taken' })

    facebookResponse = yield facebook.fetchMe(facebookAccessToken)
    emailsMatch = email is facebookResponse.email
    idsMatch = facebookID is facebookResponse.id
    unless emailsMatch and idsMatch
      throw new errors.UnprocessableEntity('Invalid facebookAccessToken')

    user = yield User.findByEmail(email)
    if user
      throw new errors.Conflict('Email already taken', { i18n: 'server_error.email_taken' })

    userData = { facebookID, email, anonymous: false }
    userData.name = name if name
    req.user.set(userData)
    yield module.exports.finishSignup(req, res)

  signupWithGPlus: wrap (req, res) ->
    unless req.user.isAnonymous()
      throw new errors.Forbidden('You are already signed in.')

    { gplusID, gplusAccessToken, email, name } = req.body
    unless _.all([gplusID, gplusAccessToken, not _.isEmpty(email)])
      throw new errors.UnprocessableEntity('Requires gplusID, gplusAccessToken, and email')

    if name and yield User.findByName(name)
      throw new errors.Conflict('Username already taken', { i18n: 'server_error.username_taken' })

    gplusResponse = yield gplus.fetchMe(gplusAccessToken)
    emailsMatch = email is gplusResponse.email
    idsMatch = gplusID is gplusResponse.id

    unless emailsMatch and idsMatch
      throw new errors.UnprocessableEntity('Invalid gplusAccessToken')

    user = yield User.findByEmail(email)
    if user
      throw new errors.Conflict('Email already taken', { i18n: 'server_error.email_taken' })

    userData = { gplusID, email, anonymous: false }
    userData.name = name if name
    req.user.set(userData)
    yield module.exports.finishSignup(req, res)

  finishSignup: co.wrap (req, res) ->
    try
      yield req.user.save()
    catch e
      if e.code is 11000 # Duplicate key error
        throw new errors.Conflict('Email already taken', { i18n: 'server_error.email_taken' })
      else
        throw e

    # post-successful account signup tasks

    req.user.sendWelcomeEmail()

    # If person A creates a trial request without creating an account, then person B uses that computer
    # to create an account, then person A's trial request is associated with person B's account. To prevent
    # this, we check that the signup email matches the trial request email, for every signup. If they do
    # not match, the trial request applicant field is cleared, disassociating the trial request from this
    # account.
    trialRequest = yield TrialRequest.findOne({applicant: req.user._id})
    if trialRequest
      email = trialRequest.get('properties')?.email or ''
      emailLower = email.toLowerCase()
      if emailLower and emailLower isnt req.user.get('emailLower')
        log.warn('User submitted trial request and created account with different emails. Disassociating trial request.')
        yield trialRequest.update({$unset: {applicant: ''}})

    res.status(200).send(req.user.toObject({req: req}))

  destudent: wrap (req, res) ->
    user = yield database.getDocFromHandle(req, User)
    if not user
      throw new errors.NotFound('User not found.')

    if not user.isStudent()
      return res.status(200).send(user.toObject({req: req}))

    yield Classroom.update(
      { members: user._id },
      { $pull: {members: user._id} },
      { multi: true }
    )

    yield CourseInstance.update(
      { members: user._id },
      { $pull: {members: user._id} },
      { multi: true }
    )

    yield user.update({ $unset: {role: ''}})
    user.set('role', undefined)
    return res.status(200).send(user.toObject({req: req}))


  deteacher: wrap (req, res) ->
    user = yield database.getDocFromHandle(req, User)
    if not user
      throw new errors.NotFound('User not found.')

    if not user.isTeacher()
      return res.status(200).send(user.toObject({req: req}))

    yield TrialRequest.remove(
      { applicant: user._id },
    )

    yield user.update({ $unset: {role: ''}})
    user.set('role', undefined)
    return res.status(200).send(user.toObject({req: req}))


  checkForNewAchievement: wrap (req, res) ->
    user = req.user
    lastAchievementChecked = user.get('lastAchievementChecked') or user._id.getTimestamp().toISOString()
    checkTimestamp = new Date().toISOString()
    achievement = yield Achievement.findOne({ updated: { $gt: lastAchievementChecked }}).sort({updated:1})

    if not achievement
      userUpdate = { 'lastAchievementChecked': checkTimestamp }
      yield user.update({$set: userUpdate}).exec()
      return res.send(userUpdate)

    userUpdate = { 'lastAchievementChecked': achievement.get('updated') }

    query = achievement.get('query')
    collection = achievement.get('collection')
    if collection is 'users'
      triggers = [user]
    else if collection is 'level.sessions' and query['level.original']
      triggers = yield LevelSession.find({
        'level.original': query['level.original']
        creator: user.id
      })
    else
      yield user.update({$set: userUpdate}).exec()
      return res.send(userUpdate)

    trigger = _.find(triggers, (trigger) -> LocalMongo.matchesQuery(trigger.toObject(), query))

    if not trigger
      yield user.update({$set: userUpdate}).exec()
      return res.send(userUpdate)

    earned = yield EarnedAchievement.findOne({ achievement: achievement.id, user: req.user.id })
    yield EarnedAchievement.upsertFor(achievement, trigger, earned, req.user)
    yield user.update({$set: userUpdate})
    user = yield User.findById(user.id).select({points: 1, earned: 1})
    return res.send(_.assign({}, userUpdate, user.toObject()))


  adminSearch: wrap (req, res, next) ->
    { adminSearch } = req.query
    return next() unless adminSearch

    unless req.user
      throw new errors.Unauthorized()
    unless req.user.isAdmin()
      throw new errors.Forbidden()

    projection = name: 1, email: 1, dateCreated: 1, role: 1

    search = adminSearch
    query = {
      anonymous: false,
      $or: [
        {emailLower: search.toLowerCase()}
        {nameLower: search.toLowerCase()}
        {slug: _.str.slugify(search)}
      ]
    }
    query.$or.push {_id: mongoose.Types.ObjectId(search)} if utils.isID search

    if req.query.role?
      query.role = req.query.role

    # TODO: Surface on the Admin page when users match these submissions
    githubSubmission = yield CLASubmission.findOne({githubUsername: adminSearch})
    if githubSubmission
      query.$or.push { _id: mongoose.Types.ObjectId(githubSubmission.get('user')) }
      query.$or = [{ _id: mongoose.Types.ObjectId(githubSubmission.get('user')) }]

    users = yield User.find(query).select(projection)

    sphinxIds = null
    if config.sphinxServer
      try
        timeout = new Promise((resolve) ->
          f = -> resolve([])
          setTimeout(f, 5000)
        )
        sphinxIds = yield Promise.any([module.exports.sphinxSearch(req, adminSearch), timeout])
        sphinxUsers = yield User.find({_id: {$in: sphinxIds}}).select(projection)

        sortedSphinxUsers = _.filter _.map sphinxIds, (id) => _.find(sphinxUsers, (u) -> u._id.equals(id))
        users = users.concat(sortedSphinxUsers)
      catch e
        log.warn('Sphinx error:', e.stack)

    else if search.length > 5
      searchParts = search.split(/[.+@]/)
      if searchParts.length > 1
        users = users.concat(yield User.find({emailLower: {$regex: '^' + searchParts[0]}}).limit(50).select(projection))

    users = _.uniq(users, false, (u) -> u.id)

    res.send(users)


  sphinxSearch: co.wrap (req, search) ->
    mysql = require('mysql');
    connection = mysql.createConnection
      host: config.sphinxServer
      port: 9306
    connection.connect()

    q = search
    params = []
    filters = []
    if utils.isID q
      params.push q
      filters.push 'mongoid = ?'
    else
      params.push q
      filters.push 'MATCH(?)'

    if req.query.role?
      params.push req.query.role
      filters.push 'role = ?'

    mysqlq = "SELECT *, WEIGHT() as skey FROM user WHERE #{filters.join(' AND ')}  LIMIT 100;"
    connection.queryAsync = Promise.promisify(connection.query, {multiArgs:true})
    [rows, fields] = yield connection.queryAsync(mysqlq, params)
    ids = rows.map (r) -> mongoose.Types.ObjectId(r.mongoid)
    connection.end()
    return ids

  resetProgress: wrap (req, res) ->
    unless req.user
      throw new errors.Unauthorized()
    if req.params.handle isnt req.user.id
      throw new errors.Forbidden('Users may only delete themselves')
    if req.user.isAdmin()
      throw new errors.Forbidden('Admins cannot reset progress') # as a precaution
    yield [
      LevelSession.remove({creator: req.user.id})
      EarnedAchievement.remove({user: req.user.id})
      UserPollsRecord.remove({user: req.user.id}) # so that gems can be re-awarded
      req.user.update({
        $set: {
          points: 0,
          'stats.gamesCompleted': 0,
          'stats.concepts': {},
          'earned.gems': 0,
          'earned.levels': [],
          'earned.items': [],
          'earned.heroes': [],
          'purchased.items': [],
          'purchased.heroes': [],
          spent: 0
        }
        $unset: {
          'heroConfig': ''
        }
      })
    ]
    return res.sendStatus(200)
