schema = require '../../app/schemas/models/user'
crypto = require 'crypto'
request = require 'request'
User = require './User'
Handler = require '../commons/Handler'
mongoose = require 'mongoose'
config = require '../../server_config'
errors = require '../commons/errors'
async = require 'async'
log = require 'winston'
LevelSession = require('../levels/sessions/LevelSession')
LevelSessionHandler = require '../levels/sessions/level_session_handler'
EarnedAchievement = require '../achievements/EarnedAchievement'

serverProperties = ['passwordHash', 'emailLower', 'nameLower', 'passwordReset']
privateProperties = [
  'permissions', 'email', 'firstName', 'lastName', 'gender', 'facebookID',
  'gplusID', 'music', 'volume', 'aceConfig', 'employerAt', 'signedEmployerAgreement'
]
candidateProperties = [
  'jobProfile', 'jobProfileApproved', 'jobProfileNotes'
]

UserHandler = class UserHandler extends Handler
  modelClass: User

  editableProperties: [
    'name', 'photoURL', 'password', 'anonymous', 'wizardColor1', 'volume',
    'firstName', 'lastName', 'gender', 'facebookID', 'gplusID', 'emails',
    'testGroupNumber', 'music', 'hourOfCode', 'hourOfCodeComplete', 'preferredLanguage',
    'wizard', 'aceConfig', 'autocastDelay', 'lastLevel', 'jobProfile'
  ]

  jsonSchema: schema

  constructor: ->
    super(arguments...)
    @editableProperties.push('permissions') unless config.isProduction

  getEditableProperties: (req, document) ->
    props = super req, document
    props.push 'jobProfileApproved', 'jobProfileNotes' if req.user.isAdmin()
    props

  formatEntity: (req, document) ->
    return null unless document?
    obj = document.toObject()
    delete obj[prop] for prop in serverProperties
    includePrivates = req.user and (req.user.isAdmin() or req.user._id.equals(document._id))
    delete obj[prop] for prop in privateProperties unless includePrivates
    includeCandidate = includePrivates or (obj.jobProfileApproved and req.user and ('employer' in (req.user.get('permissions') ? [])) and @employerCanViewCandidate req.user, obj)
    delete obj[prop] for prop in candidateProperties unless includeCandidate
    return obj

  waterfallFunctions: [
    # FB access token checking
    # Check the email is the same as FB reports
    (req, user, callback) ->
      fbID = req.query.facebookID
      fbAT = req.query.facebookAccessToken
      return callback(null, req, user) unless fbID and fbAT
      url = "https://graph.facebook.com/me?access_token=#{fbAT}"
      request(url, (err, response, body) ->
        log.warn "Error grabbing FB token: #{err}" if err
        body = JSON.parse(body)
        emailsMatch = req.body.email is body.email
        return callback(res:'Invalid Facebook Access Token.', code:422) unless emailsMatch
        callback(null, req, user)
      )

    # GPlus access token checking
    (req, user, callback) ->
      gpID = req.query.gplusID
      gpAT = req.query.gplusAccessToken
      return callback(null, req, user) unless gpID and gpAT
      url = "https://www.googleapis.com/oauth2/v2/userinfo?access_token=#{gpAT}"
      request(url, (err, response, body) ->
        log.warn "Error grabbing G+ token: #{err}" if err
        body = JSON.parse(body)
        emailsMatch = req.body.email is body.email
        return callback(res:'Invalid G+ Access Token.', code:422) unless emailsMatch
        callback(null, req, user)
      )

    # Email setting
    (req, user, callback) ->
      return callback(null, req, user) unless req.body.email?
      emailLower = req.body.email.toLowerCase()
      return callback(null, req, user) if emailLower is user.get('emailLower')
      User.findOne({emailLower:emailLower}).exec (err, otherUser) ->
        log.error "Database error setting user email: #{err}" if err
        return callback(res:'Database error.', code:500) if err

        if (req.query.gplusID or req.query.facebookID) and otherUser
          # special case, log in as that user
          return req.logIn(otherUser, (err) ->
            return callback(res:'Facebook user login error.', code:500) if err
            return callback(null, req, otherUser)
          )
        r = {message:'is already used by another account', property:'email'}
        return callback({res:r, code:409}) if otherUser
        user.set('email', req.body.email)
        callback(null, req, user)

    # Name setting
    (req, user, callback) ->
      return callback(null, req, user) unless req.body.name
      nameLower = req.body.name?.toLowerCase()
      return callback(null, req, user) unless nameLower
      return callback(null, req, user) if nameLower is user.get('nameLower') and not user.get('anonymous')
      User.findOne({nameLower:nameLower,anonymous:false}).exec (err, otherUser) ->
        log.error "Database error setting user name: #{err}" if err
        return callback(res:'Database error.', code:500) if err
        r = {message:'is already used by another account', property:'name'}
        console.log 'Another user exists' if otherUser
        return callback({res:r, code:409}) if otherUser
        user.set('name', req.body.name)
        callback(null, req, user)
  ]

  getById: (req, res, id) ->
    if req.user?._id.equals(id)
      return @sendSuccess(res, @formatEntity(req, req.user, 256))
    super(req, res, id)

  getNamesByIDs: (req, res) ->
    ids = req.query.ids or req.body.ids
    returnWizard = req.query.wizard or req.body.wizard
    properties = if returnWizard then "name wizard" else "name"
    @getPropertiesFromMultipleDocuments res, User, properties, ids

  nameToID: (req, res, name) ->
    User.findOne({nameLower:name.toLowerCase(),anonymous:false}).exec (err, otherUser) ->
      res.send(if otherUser then otherUser._id else JSON.stringify(''))
      res.end()

  getSimulatorLeaderboard: (req, res) ->
    queryParameters = @getSimulatorLeaderboardQueryParameters(req)
    leaderboardQuery = User.find(queryParameters.query).select("name simulatedBy simulatedFor").sort({"simulatedBy":queryParameters.sortOrder}).limit(queryParameters.limit)
    leaderboardQuery.exec (err, otherUsers) ->
        otherUsers = _.reject otherUsers, _id: req.user._id if req.query.scoreOffset isnt -1
        otherUsers ?= []
        res.send(otherUsers)
        res.end()

  getMySimulatorLeaderboardRank: (req, res) ->
    req.query.order = 1
    queryParameters = @getSimulatorLeaderboardQueryParameters(req)
    User.count queryParameters.query, (err, count) =>
      return @sendDatabaseError(res, err) if err
      res.send JSON.stringify(count + 1)

   getSimulatorLeaderboardQueryParameters: (req) ->
    @validateSimulateLeaderboardRequestParameters(req)

    query = {}
    sortOrder = -1
    limit = if req.query.limit > 30 then 30 else req.query.limit
    if req.query.scoreOffset isnt -1
      simulatedByQuery = {}
      simulatedByQuery[if req.query.order is 1 then "$gt" else "$lte"] = req.query.scoreOffset
      query.simulatedBy = simulatedByQuery
      sortOrder = 1 if req.query.order is 1
    else
      query.simulatedBy = {"$exists": true}
    {query: query, sortOrder: sortOrder, limit: limit}

  validateSimulateLeaderboardRequestParameters: (req) ->
    req.query.order = parseInt(req.query.order) ? -1
    req.query.scoreOffset = parseFloat(req.query.scoreOffset) ? 100000
    req.query.limit = parseInt(req.query.limit) ? 20

  post: (req, res) ->
    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendBadInputError(res, 'Must have an anonymous user to post with.') unless req.user
    return @sendBadInputError(res, 'Existing users cannot create new ones.') unless req.user.get('anonymous')
    req.body._id = req.user._id if req.user.get('anonymous')
    @put(req, res)

  hasAccessToDocument: (req, document) ->
    if req.route.method in ['put', 'post', 'patch']
      return true if req.user?.isAdmin()
      return req.user?._id.equals(document._id)
    return true

  getByRelationship: (req, res, args...) ->
    return @agreeToCLA(req, res) if args[1] is 'agreeToCLA'
    return @agreeToEmployerAgreement(req,res) if args[1] is 'agreeToEmployerAgreement'
    return @avatar(req, res, args[0]) if args[1] is 'avatar'
    return @getNamesByIDs(req, res) if args[1] is 'names'
    return @nameToID(req, res, args[0]) if args[1] is 'nameToID'
    return @getLevelSessions(req, res, args[0]) if args[1] is 'level.sessions'
    return @getCandidates(req, res) if args[1] is 'candidates'
    return @getSimulatorLeaderboard(req, res, args[0]) if args[1] is 'simulatorLeaderboard'
    return @getMySimulatorLeaderboardRank(req, res, args[0]) if args[1] is 'simulator_leaderboard_rank'
    return @getEarnedAchievements(req, res, args[0]) if args[1] is 'achievements'
    return @sendNotFoundError(res)
    super(arguments...)

  agreeToCLA: (req, res) ->
    return @sendUnauthorizedError(res) unless req.user
    doc =
      user: req.user._id+''
      email: req.user.get 'email'
      name: req.user.get 'name'
      githubUsername: req.body.githubUsername
      created: new Date()+''
    collection = mongoose.connection.db.collection 'cla.submissions', (err, collection) =>
      return @sendDatabaseError(res, err) if err
      collection.insert doc, (err) =>
        return @sendDatabaseError(res, err) if err
        req.user.set('signedCLA', doc.created)
        req.user.save (err) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res, {result:'success'})

  avatar: (req, res, id) ->
    @modelClass.findById(id).exec (err, document) =>
      return @sendDatabaseError(res, err) if err
      photoURL = document?.get('photoURL')
      if photoURL
        photoURL = "/file/#{photoURL}"
      else
        photoURL = @buildGravatarURL document, req.query.s, req.query.fallback
      res.redirect photoURL
      res.end()

  getLevelSessions: (req, res, userID) ->
    return @sendUnauthorizedError(res) unless req.user._id+'' is userID or req.user.isAdmin()
    query = {'creator': userID}
    projection = null
    if req.query.project
      projection = {}
      projection[field] = 1 for field in req.query.project.split(',')
    LevelSession.find(query).select(projection).exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (LevelSessionHandler.formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

  getEarnedAchievements: (req, res, userID) ->
    query = EarnedAchievement.find(user: userID)
    query.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err?
      documents = (@formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

  agreeToEmployerAgreement: (req, res) ->
    userIsAnonymous = req.user?.get('anonymous')
    if userIsAnonymous then return errors.unauthorized(res, "You need to be logged in to agree to the employer agreeement.")
    profileData = req.body
    #TODO: refactor this bit to make it more elegant
    if not profileData.id or not profileData.positions or not profileData.emailAddress or not profileData.firstName or not profileData.lastName
      return errors.badInput(res, "You need to have a more complete profile to sign up for this service.")
    @modelClass.findById(req.user.id).exec (err, user) =>
      if user.get('employerAt') or user.get('signedEmployerAgreement') or "employer" in user.get('permissions')
        return errors.conflict(res, "You already have signed the agreement!")
      #TODO: Search for the current position
      employerAt = _.filter(profileData.positions.values,"isCurrent")[0]?.company.name ? "Not available"
      signedEmployerAgreement =
        linkedinID: profileData.id
        date: new Date()
        data: profileData
      updateObject =
        "employerAt": employerAt
        "signedEmployerAgreement": signedEmployerAgreement
        $push: "permissions":'employer'

      User.update {"_id": req.user.id}, updateObject, (err, result) =>
        if err? then return errors.serverError(res, "There was an issue updating the user object to reflect employer status: #{err}")
        res.send({"message": "The agreement was successful."})
        res.end()

  getCandidates: (req, res) ->
    authorized = req.user.isAdmin() or ('employer' in req.user.get('permissions'))
    since = (new Date((new Date()) - 2 * 30.4 * 86400 * 1000)).toISOString()
    #query = {'jobProfile.active': true, 'jobProfile.updated': {$gt: since}}
    query = {'jobProfile.updated': {$gt: since}}
    query.jobProfileApproved = true unless req.user.isAdmin()
    query['jobProfile.active'] = true unless req.user.isAdmin()
    selection = 'jobProfile'
    selection += ' email' if authorized
    selection += ' jobProfileApproved' if req.user.isAdmin()
    User.find(query).select(selection).exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      candidates = (candidate for candidate in documents when @employerCanViewCandidate req.user, candidate.toObject())
      candidates = (@formatCandidate(authorized, candidate) for candidate in candidates)
      @sendSuccess(res, candidates)

  formatCandidate: (authorized, document) ->
    fields = if authorized then ['jobProfile', 'jobProfileApproved', 'photoURL', '_id'] else ['jobProfile']
    obj = _.pick document.toObject(), fields
    obj.photoURL ||= obj.jobProfile.photoURL if authorized
    subfields = ['country', 'city', 'lookingFor', 'jobTitle', 'skills', 'experience', 'updated', 'active']
    if authorized
      subfields = subfields.concat ['name']
    obj.jobProfile = _.pick obj.jobProfile, subfields
    obj

  employerCanViewCandidate: (employer, candidate) ->
    return true if employer.isAdmin()
    for job in candidate.jobProfile?.work ? []
      # TODO: be smarter about different ways to write same company names to ensure privacy.
      # We'll have to manually pay attention to how we set employer names for now.
      if job.employer?.toLowerCase() is employer.get('employerAt')?.toLowerCase()
        log.info "#{employer.get('name')} at #{employer.get('employerAt')} can't see #{candidate.jobProfile.name} because s/he worked there."
      return false if job.employer?.toLowerCase() is employer.get('employerAt')?.toLowerCase()
    true

  buildGravatarURL: (user, size, fallback) ->
    emailHash = @buildEmailHash user
    fallback ?= "http://codecombat.com/file/db/thang.type/52a00d55cf1818f2be00000b/portrait.png"
    fallback = "http://codecombat.com#{fallback}" unless /^http/.test fallback
    "https://www.gravatar.com/avatar/#{emailHash}?s=#{size}&default=#{fallback}"

  buildEmailHash: (user) ->
    # emailHash is used by gravatar
    hash = crypto.createHash('md5')
    if user.get('email')
      hash.update(_.trim(user.get('email')).toLowerCase())
    else
      hash.update(user.get('_id') + '')
    hash.digest('hex')

module.exports = new UserHandler()
