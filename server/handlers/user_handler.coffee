schema = require '../../app/schemas/models/user'
crypto = require 'crypto'
request = require 'request'
User = require './../models/User'
Handler = require '../commons/Handler'
mongoose = require 'mongoose'
config = require '../../server_config'
errors = require '../commons/errors'
async = require 'async'
log = require 'winston'
moment = require 'moment'
AnalyticsLogEvent = require '../models/AnalyticsLogEvent'
Clan = require '../models/Clan'
CourseInstance = require '../models/CourseInstance'
LevelSession = require '../models/LevelSession'
LevelSessionHandler = require './level_session_handler'
Payment = require '../models/Payment'
SubscriptionHandler = require './subscription_handler'
DiscountHandler = require './discount_handler'
EarnedAchievement = require '../models/EarnedAchievement'
{findStripeSubscription} = require '../lib/utils'
{isID} = require '../lib/utils'
slack = require '../slack'
sendgrid = require '../sendgrid'
Prepaid = require '../models/Prepaid'
UserPollsRecord = require '../models/UserPollsRecord'
EarnedAchievement = require '../models/EarnedAchievement'
facebook = require '../lib/facebook'
middleware = require '../middleware'
co = require 'co'

serverProperties = ['passwordHash', 'emailLower', 'nameLower', 'passwordReset', 'geo']

UserHandler = class UserHandler extends Handler
  modelClass: User

  allowedMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']

  getEditableProperties: (req, document) ->
    props = super req, document
    props.push 'permissions' unless config.isProduction or global.testing
    props.push @privateProperties... if req.user.isAdmin()  # Admins are mad with power
    if not req.user.isAdmin()
      if document.isTeacher() and req.body.role not in User.teacherRoles
        props = _.without props, 'role'
    props

  validateDocumentInput: (input, req) ->
    res = super(input)

    if res.errors and req
      mapper = (error) -> [error.code.toString(),error.dataPath,error.schemaPath].join(':')
      originalErrors = _.map(req.originalErrors, mapper)
      currentErrors = _.map(res.errors, mapper)
      newErrors = _.difference(currentErrors, originalErrors)
      if _.size(newErrors) is 0
        return { valid: true }

    return res

  formatEntity: (req, document, publicOnly=false) =>
    # TODO: Delete. This function is duplicated in server User model toObject transform.
    return null unless document?
    obj = document.toObject()
    delete obj[prop] for prop in User.serverProperties
    includePrivates = not publicOnly and (req.user and (req.user.isAdmin() or req.user._id.equals(document._id) or req.session.amActually is document.id))
    delete obj[prop] for prop in User.privateProperties unless includePrivates
    return obj

  waterfallFunctions: [
    (req, user, callback) ->
      tv4 = require('tv4').tv4
      res = tv4.validateMultiple(user.toObject(), User.jsonSchema)
      req.originalErrors = res.errors
      callback(null, req, user)

    # FB access token checking
    # Check the email is the same as FB reports
    # TODO: Remove deprecated signups on RequestQuoteView, then these waterfall functions
    (req, user, callback) ->
      fbID = req.query.facebookID
      fbAT = req.query.facebookAccessToken
      return callback(null, req, user) unless fbID and fbAT
      facebook.fetchMe(fbAT).catch(callback).then (body) ->
        emailsMatch = req.body.email is body.email
        return callback(res: 'Invalid Facebook Access Token.', code: 422) unless emailsMatch
        callback(null, req, user)

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
        return callback(res: 'Invalid G+ Access Token.', code: 422) unless emailsMatch
        callback(null, req, user)
      )

    # Email setting
    (req, user, callback) ->
      return callback(null, req, user) unless req.body.email?

      emailRegex = /[A-z0-9._%+-]+@[A-z0-9.-]+\.[A-z]{2,63}/
      if not emailRegex.test(req.body.email) and emailRegex.test(user.get('email'))
        # Don't let them remove their email address if it's there already
        # TODO: Send a response that the user can actually see! Mimic schema error?
        if not user.get('role')
          return callback({ res: { message: 'Individual accounts must have a valid email address', code: 422}, code: 422 })
        if user.isTeacher()
          return callback({ res: { message: 'Teacher accounts must have a valid email address', code: 422}, code: 422 })

      # handle unsetting email
      if req.body.email is ''
        user.set('email', req.body.email)
        return callback(null, req, user)

      emailLower = req.body.email.toLowerCase()
      return callback(null, req, user) if emailLower is user.get('emailLower')
      User.findOne({emailLower: emailLower}).exec (err, otherUser) ->
        log.error "Database error setting user email: #{err}" if err
        return callback(res: 'Database error.', code: 500) if err

        if (req.query.gplusID or req.query.facebookID) and otherUser
          # special case, log in as that user
          return req.logIn(otherUser, (err) ->
            return callback(res: 'Facebook user login error.', code: 500) if err
            return callback(null, req, otherUser)
          )
        r = {message: 'is already used by another account', property: 'email', code: 409}
        return callback({res: r, code: 409}) if otherUser
        user.set('email', req.body.email)
        user.set('emailVerified', false)
        callback(null, req, user)

    # Name setting
    (req, user, callback) ->
      return callback(null, req, user) unless req.body.name?

      if req.body.name is ''
        user.set('name', req.body.name)
        return callback(null, req, user)

      nameLower = req.body.name?.toLowerCase()
      return callback(null, req, user) unless nameLower?
      return callback(null, req, user) if user.get 'anonymous' # anonymous users can have any name
      return callback(null, req, user) if nameLower is user.get('nameLower')
      User.findOne({nameLower: nameLower, anonymous: false}).exec (err, otherUser) ->
        log.error "Database error setting user name: #{err}" if err
        return callback(res: 'Database error.', code: 500) if err
        r = {message: 'is already used by another account', property: 'name', code: 409}
        log.info 'Another user exists' if otherUser
        return callback({res: r, code: 409}) if otherUser
        user.set('name', req.body.name)
        callback(null, req, user)

    # Subscription setting
    (req, user, callback) ->
      return callback(null, req, user) unless req.headers['x-change-plan'] # ensure only saves that are targeted at changing the subscription actually affect the subscription
      return callback(null, req, user) unless req.body.stripe
      wantsPlan = req.body.stripe.planID?
      hasPlan = user.get('stripe')?.planID? and not req.body.stripe.prepaidCode?
      return callback(null, req, user) if hasPlan is wantsPlan
      if wantsPlan and not hasPlan
        middleware.subscriptions.subscribeUser(req, user)
        .then(-> callback(null, req, user))
        .catch((err) ->
          if err instanceof errors.NetworkError
            return callback({res: err.message, code: err.code})
          if err.res and err.code
            return callback(err)
          if err.message.indexOf('declined') > -1
            return callback({res: 'Card declined', code: 402})
          SubscriptionHandler.logSubscriptionError(user, 'Subscribe error: '+(err.stack or err.type or err.message))
          callback({res: 'Subscription error.', code: 500})
        )
      else if hasPlan and not wantsPlan
        middleware.subscriptions.unsubscribeUser(req, user)
        .then(-> callback(null, req, user))
        .catch((err) ->
          if err instanceof errors.NetworkError
            return callback({res: err.message, code: err.code})
          if err.res and err.code
            return callback(err)
          SubscriptionHandler.logSubscriptionError(user, 'Unsubscribe error: '+(err.stack or err.type or err.message))
          callback({res: 'Subscription error.', code: 500})
        )

    # Discount setting
    (req, user, callback) ->
      return callback(null, req, user) unless req.body.stripe
      return callback(null, req, user) unless req.user?.isAdmin()
      hasCoupon = user.get('stripe')?.couponID
      wantsCoupon = req.body.stripe.couponID

      return callback(null, req, user) if hasCoupon is wantsCoupon
      if wantsCoupon and (hasCoupon isnt wantsCoupon)
        DiscountHandler.discountUser(req, user, (err) ->
          return callback(err) if err
          return callback(null, req, user)
        )
      else if hasCoupon and not wantsCoupon
        DiscountHandler.removeDiscountFromCustomer(req, user, (err) ->
          return callback(err) if err
          return callback(null, req, user)
        )

    # Update consent history based on user.emails changes
    (req, user, callback) ->
      return callback(null, req, user) unless req.body.emails and user.get('email')
      consentHistory = _.cloneDeep(user.get('consentHistory') or [])
      oldEmails = user.get('emails') ? {}
      newEmails = req.body.emails
      for k, v of newEmails when !!v.enabled isnt !!oldEmails[k]?.enabled
        consentHistory.push
          action: if v.enabled then 'allow' else 'forbid'
          date: new Date()
          type: 'email'
          emailHash: User.hashEmail(user.get('email').toLowerCase())
          description: k
      user.set('consentHistory', consentHistory)
      callback(null, req, user)
  ]

  getById: (req, res, id) ->
    if Handler.isID(id) and req.user?._id.equals(id)
      return @sendSuccess(res, @formatEntity(req, req.user))
    super(req, res, id)

  getByIDs: (req, res) ->
    return @sendForbiddenError(res) unless req.user?.isAdmin()
    User.find {_id: {$in: req.body.ids}}, (err, users) =>
      return @sendDatabaseError(res, err) if err
      cleandocs = (@formatEntity(req, doc) for doc in users)
      @sendSuccess(res, cleandocs)

  getNamesByIDs: (req, res) ->
    ids = req.query.ids or req.body.ids
    returnWizard = req.query.wizard or req.body.wizard
    properties = if returnWizard then 'name wizard' else 'name'
    @getPropertiesFromMultipleDocuments res, User, properties, ids

  nameToID: (req, res, name) ->
    User.findOne({nameLower: unescape(name).toLowerCase(), anonymous: false}).exec (err, otherUser) ->
      res.send(if otherUser then otherUser._id else JSON.stringify(''))
      res.end()

  getSimulatorLeaderboard: (req, res) ->
    queryParameters = @getSimulatorLeaderboardQueryParameters(req)
    leaderboardQuery = User.find(queryParameters.query).select('name simulatedBy simulatedFor').sort({'simulatedBy': queryParameters.sortOrder}).limit(queryParameters.limit)
    leaderboardQuery.cache(10 * 60 * 1000) if req.query.scoreOffset is -1
    leaderboardQuery.exec (err, otherUsers) ->
      otherUsers = _.reject otherUsers, _id: req.user._id if req.query.scoreOffset isnt -1 and req.user
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
      simulatedByQuery[if req.query.order is 1 then '$gt' else '$lte'] = req.query.scoreOffset
      query.simulatedBy = simulatedByQuery
      sortOrder = 1 if req.query.order is 1
    else
      query.simulatedBy = {'$exists': true}
    {query: query, sortOrder: sortOrder, limit: limit}

  validateSimulateLeaderboardRequestParameters: (req) ->
    req.query.order = parseInt(req.query.order) ? -1
    req.query.scoreOffset = parseFloat(req.query.scoreOffset) ? 100000
    req.query.limit = parseInt(req.query.limit) ? 20

  post: (req, res) ->
    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendBadInputError(res, 'Must have an anonymous user to post with.') unless req.user
    return @sendBadInputError(res, 'Existing users cannot create new ones.') if req.user.get('anonymous') is false
    req.body._id = req.user._id if req.user.get('anonymous')
    @put(req, res)

  hasAccessToDocument: (req, document) ->
    if document.isStudent() and not (req.user?._id.equals(document._id) or req.user?.isAdmin() or req.user?.isTeacher())
      return false
    if req.method.toLowerCase() in ['put', 'post', 'patch', 'delete']
      return true if req.user?.isAdmin()
      return req.user?._id.equals(document._id)
    return true

  getByRelationship: (req, res, args...) ->
    return @agreeToCLA(req, res) if args[1] is 'agreeToCLA'
    return @getByIDs(req, res) if args[1] is 'users'
    return @getNamesByIDs(req, res) if args[1] is 'names'
    return @getPrepaidCodes(req, res) if args[1] is 'prepaid_codes'
    return @getSchoolCounts(req, res) if args[1] is 'school_counts'
    return @nameToID(req, res, args[0]) if args[1] is 'nameToID'
    return @getLevelSessionsForEmployer(req, res, args[0]) if args[1] is 'level.sessions' and args[2] is 'employer'
    return @getLevelSessions(req, res, args[0]) if args[1] is 'level.sessions'
    return @getClans(req, res, args[0]) if args[1] is 'clans'
    return @getCourseInstances(req, res, args[0]) if args[1] is 'course_instances'
    return @getSimulatorLeaderboard(req, res, args[0]) if args[1] is 'simulatorLeaderboard'
    return @getMySimulatorLeaderboardRank(req, res, args[0]) if args[1] is 'simulator_leaderboard_rank'
    return @getEarnedAchievements(req, res, args[0]) if args[1] is 'achievements'
    return @getRecentlyPlayed(req, res, args[0]) if args[1] is 'recently_played'
    return @trackActivity(req, res, args[0], args[2], args[3]) if args[1] is 'track' and args[2]
    return @getStripeInfo(req, res, args[0]) if args[1] is 'stripe'
    return @getSubRecipients(req, res) if args[1] is 'sub_recipients'
    return @getSubSponsor(req, res) if args[1] is 'sub_sponsor'
    return @getSubSponsors(req, res) if args[1] is 'sub_sponsors'
    return @sendOneTimeEmail(req, res, args[0]) if args[1] is 'send_one_time_email'
    return @resetProgress(req, res, args[0]) if args[1] is 'reset_progress'
    return @sendNotFoundError(res)
    super(arguments...)

  getStripeInfo: (req, res, handle) ->
    @getDocumentForIdOrSlug handle, (err, user) =>
      return @sendNotFoundError(res) if not user
      return @sendForbiddenError(res) unless req.user and (req.user.isAdmin() or req.user.get('_id').equals(user.get('_id')))
      return @sendNotFoundError(res) if not customerID = user.get('stripe')?.customerID
      stripe.customers.retrieve customerID, (err, customer) =>
        return @sendDatabaseError(res, err) if err
        info = card: customer.sources?.data?[0]
        findStripeSubscription customerID, subscriptionID: user.get('stripe').subscriptionID, (err, subscription) =>
          info.subscription = subscription
          findStripeSubscription customerID, subscriptionID: user.get('stripe').sponsorSubscriptionID, (err, subscription) =>
            info.sponsorSubscription = subscription
            @sendSuccess(res, JSON.stringify(info, null, '\t'))

  getSubRecipients: (req, res) ->
    # Return map of userIDs to name/email/cancel date
    # TODO: Add test for this API

    return @sendSuccess(res, {}) if _.isEmpty(req.user?.get('stripe')?.recipients ? [])
    return @sendSuccess(res, {}) unless req.user.get('stripe')?.customerID?

    # Get recipients User info
    ids = (recipient.userID for recipient in req.user.get('stripe').recipients)
    User.find({'_id': { $in: ids} }, 'name emailLower').exec (err, users) =>
      info = {}
      _.each users, (user) -> info[user.id] = user.toObject()
      customerID = req.user.get('stripe').customerID

      nextBatch = (starting_after, done) ->
        options = limit: 100
        options.starting_after = starting_after if starting_after
        stripe.customers.listSubscriptions customerID, options, (err, subscriptions) ->
          return done(err) if err
          return done() unless subscriptions?.data?.length > 0
          for sub in subscriptions.data
            userID = sub.metadata?.id
            continue unless userID of info
            if sub.cancel_at_period_end and info[userID]['cancel_at_period_end'] isnt false
              info[userID]['cancel_at_period_end'] = new Date(sub.current_period_end * 1000)
            else
              info[userID]['cancel_at_period_end'] = false

          if subscriptions.has_more
            return nextBatch(subscriptions.data[subscriptions.data.length - 1].id, done)
          else
            return done()
      nextBatch null, (err) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res, info)

  getSubSponsor: (req, res) ->
    # TODO: Add test for this API

    return @sendSuccess(res, {}) unless req.user?.get('stripe')?.sponsorID?

    # Get sponsor User info
    User.findById req.user.get('stripe').sponsorID, (err, sponsor) =>
      return @sendDatabaseError(res, err) if err
      return @sendDatabaseError(res, 'No sponsor customerID') unless sponsor?.get('stripe')?.customerID?
      info =
        email: sponsor.get('emailLower')
        name: sponsor.get('name')

      # Get recipient subscription info
      findStripeSubscription sponsor.get('stripe')?.customerID, userID: req.user.id, (err, subscription) =>
        info.subscription = subscription
        @sendDatabaseError(res, 'No sponsored subscription found') unless info.subscription?
        @sendSuccess(res, info)

  getSubSponsors: (req, res) ->
    return @sendForbiddenError(res) unless req.user?.isAdmin()
    Payment.find {$where: 'this.purchaser && this.recipient && this.purchaser.valueOf() != this.recipient.valueOf()'}, (err, payments) =>
      return @sendDatabaseError(res, err) if err
      sponsorIDs = (payment.get('purchaser') for payment in payments)
      User.find {$and: [{_id: {$in: sponsorIDs}}, {"stripe.sponsorSubscriptionID": {$exists: true}}]}, (err, users) =>
        return @sendDatabaseError(res, err) if err
        sponsors = (@formatEntity(req, doc) for doc in users when doc.get('stripe').recipients?.length > 0)
        @sendSuccess(res, sponsors)

  sendOneTimeEmail: (req, res) ->
    # TODO: Should this API be somewhere else?
    # TODO: Where should email types be stored?
    # TODO: How do we schema validate an update db call?

    return @sendForbiddenError(res) unless req.user
    email = req.query.email or req.body.email
    type = req.query.type or req.body.type
    return @sendBadInputError res, 'No email given.' unless email?
    return @sendBadInputError res, 'No type given.' unless type?

    # log.warn "sendOneTimeEmail #{type} #{email}"

    unless type in ['share progress modal parent']
      return @sendBadInputError res, "Unknown one-time email type #{type}"

    sendMail = co.wrap (message) =>
      try
        yield sendgrid.api.send message
      catch err
        console.error "sendgrid one-time email error:", err
        return @sendError res, 500, 'send mail failed.'
      req.user.update {$push: {"emails.oneTimes": {type: type, email: email, sent: new Date()}}}, (err) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res, {result: 'success'})
        AnalyticsLogEvent.logEvent req.user, 'Sent one time email', email: email, type: type

    # Generic email data
    message =
      to:
        email: email
      from:
        email: config.mail.username
        name: 'CodeCombat'
      substitutions:
        userName: req.user.get('name') or ''
    if codeLanguage = req.user.get('aceConfig.language')
      codeLanguage = codeLanguage[0].toUpperCase() + codeLanguage.slice(1)
      codeLanguage = codeLanguage.replace 'script', 'Script'
      message.substitutions.codeLanguage = codeLanguage
    if senderEmail = req.user.get('email')
      message.substitutions.senderEmail = senderEmail

    # Type-specific email data
    if type is 'share progress modal parent'
      message.templateId = sendgrid.templates.share_progress_email

    sendMail message

  getPrepaidCodes: (req, res) ->
    return @sendSuccess(res, []) unless req.user?
    orQuery = [{ creator: req.user._id }, { 'redeemers.userID' :  req.user._id }]
    Prepaid.find({}).or(orQuery).exec (err, documents) =>
      @sendSuccess(res, documents)

  getSchoolCounts: (req, res) ->
    return @sendSuccess(res, []) unless req.user?.isAdmin()
    minCount = req.body.minCount ? 20
    query = {$and: [
        {anonymous: false},
        {schoolName: {$exists: true}},
        {schoolName: {$ne: ''}}
        ]}
    User.find(query, {schoolName: 1}).lean().exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      schoolCountMap = {}
      for doc in documents
        schoolName = doc.schoolName
        schoolCountMap[schoolName] ?= 0;
        schoolCountMap[schoolName]++;
      schoolCounts = []
      for schoolName, count of schoolCountMap
        continue unless count >= minCount
        schoolCounts.push schoolName: schoolName, count: count
      @sendSuccess(res, schoolCounts)
  agreeToCLA: (req, res) ->
    return @sendForbiddenError(res) unless req.user
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
          @sendSuccess(res, {result: 'success'})

  getLevelSessionsForEmployer: (req, res, userID) ->
    return @sendForbiddenError(res) unless req.user
    return @sendForbiddenError(res) unless req.user._id+'' is userID or req.user.isAdmin() or ('employer' in (req.user.get('permissions') ? []))
    query = creator: userID, levelID: {$in: ['criss-cross', 'gridmancer', 'greed', 'dungeon-arena', 'brawlwood', 'gold-rush']}
    projection = 'levelName levelID team playtime codeLanguage submitted code totalScore teamSpells level'
    LevelSession.find(query).select(projection).exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (LevelSessionHandler.formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

  IDify: (idOrSlug, done) ->
    return done null, idOrSlug if Handler.isID idOrSlug
    User.findBySlug idOrSlug, (err, user) -> done err, user?.get '_id'

  getLevelSessions: (req, res, userIDOrSlug) ->
    @IDify userIDOrSlug, (err, userID) =>
      return @sendDatabaseError res, err if err
      return @sendNotFoundError res unless userID?
      query = creator: userID + ''
      isAuthorized = req.user?._id+'' is userID or req.user?.isAdmin()
      projection = {}
      if req.query.project
        projection[field] = 1 for field in req.query.project.split(',') when isAuthorized or not (field in LevelSessionHandler.privateProperties)
      else unless isAuthorized
        projection[field] = 0 for field in LevelSessionHandler.privateProperties

      LevelSession.find(query).select(projection).exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        if req.query.order
          documents = _.sortBy documents, 'changed'
          if req.query.order + '' is '-1'
            documents.reverse()
        documents = (LevelSessionHandler.formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, documents)

  getEarnedAchievements: (req, res, userIDOrSlug) ->
    @IDify userIDOrSlug, (err, userID) =>
      return @sendDatabaseError res, err if err
      return @sendNotFoundError res unless userID?
      query = user: userID + ''
      query.notified = false if req.query.notified is 'false'
      EarnedAchievement.find(query).sort(changed: -1).exec (err, documents) =>
        return @sendDatabaseError(res, err) if err?
        cleandocs = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, cleandocs)

  getRecentlyPlayed: (req, res, userID) ->
    twoWeeksAgo = moment().subtract('days', 14).toDate()
    LevelSession.find(creator: userID, changed: $gt: twoWeeksAgo).sort(changed: -1).exec (err, docs) =>
      return @sendDatabaseError res, err if err?
      cleandocs = (@formatEntity(req, doc) for doc in docs)
      @sendSuccess res, cleandocs

  trackActivity: (req, res, userID, activityName, increment=1) ->
    return @sendMethodNotAllowed res unless req.method is 'POST'
    isMe = userID is req.user?._id + ''
    isAuthorized = isMe or req.user?.isAdmin()
    isAuthorized ||= ('employer' in (req.user?.get('permissions') ? [])) and (activityName in ['viewed_by_employer', 'contacted_by_employer'])
    return @sendForbiddenError res unless isAuthorized
    updateUser = (user) =>
      activity = user.trackActivity activityName, increment
      user.update {activity: activity}, (err) =>
        return @sendDatabaseError res, err if err
        @sendSuccess res, result: 'success'
    if isMe
      updateUser(req.user)
    else
      @getDocumentForIdOrSlug userID, (err, user) =>
        return @sendDatabaseError res, err if err
        return @sendNotFoundError res unless user
        updateUser user

  getClans: (req, res, userIDOrSlug) ->
    @getDocumentForIdOrSlug userIDOrSlug, (err, user) =>
      return @sendNotFoundError(res) unless user
      clanIDs = user.get('clans') ? []
      query = {$and: [{_id: {$in: clanIDs}}]}
      query['$and'].push {type: 'public'} unless req.user?.id is user.id
      Clan.find query, (err, documents) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res, documents)

  getCourseInstances: (req, res, userIDOrSlug) ->
    @getDocumentForIdOrSlug userIDOrSlug, (err, user) =>
      return @sendNotFoundError(res) unless user
      CourseInstance.find {members: {$in: [user.get('_id')]}}, (err, documents) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res, documents)

  resetProgress: (req, res, userID) ->
    return @sendMethodNotAllowed res unless req.method is 'POST'
    return @sendForbiddenError res unless userID and userID is req.user?._id + ''  # Only you can reset your own progress
    return @sendForbiddenError res if req.user?.isAdmin()  # Protect admins from resetting their progress
    @constructor.resetProgressForUser req.user, (err, results) =>
      return @sendDatabaseError res, err if err
      @sendSuccess res, result: 'success'

  @resetProgressForUser: (user, cb) ->
    async.parallel [
      (cb) -> LevelSession.remove {creator: user._id + ''}, cb
      (cb) -> EarnedAchievement.remove {user: user._id + ''}, cb
      (cb) -> UserPollsRecord.remove {user: user._id + ''}, cb
      (cb) -> user.update {points: 0, 'stats.gamesCompleted': 0, 'stats.concepts': {}, 'earned.gems': 0, 'earned.levels': [], 'earned.items': [], 'earned.heroes': [], 'purchased.items': [], 'purchased.heroes': [], spent: 0}, cb
    ], cb

  countEdits = (model, done) ->
    statKey = User.statsMapping.edits[model.modelName]
    return done(new Error 'Could not resolve statKey for model') unless statKey?
    userStream = User.find({anonymous: false}).sort('_id').stream()
    streamFinished = false
    usersTotal = 0
    usersFinished = 0
    numberRunning = 0
    doneWithUser = (err) ->
      log.error err if err?
      ++usersFinished
      --numberRunning
      userStream.resume()
      done?() if streamFinished and usersFinished is usersTotal
    userStream.on 'error', (err) -> log.error err
    userStream.on 'close', -> streamFinished = true
    userStream.on 'data',  (user) ->
      ++usersTotal
      ++numberRunning
      userStream.pause() if numberRunning > 20
      userObjectID = user.get('_id')
      userStringID = userObjectID.toHexString()

      model.count {$or: [creator: userObjectID, creator: userStringID]}, (err, count) ->
        if count
          update = $set: {}
          update.$set[statKey] = count
        else
          update = $unset: {}
          update.$unset[statKey] = ''
        log.info "... updating #{userStringID} patches #{statKey} to #{count}, #{usersTotal} players found so far." if count
        User.findByIdAndUpdate user.get('_id'), update, (err) ->
          log.error err if err?
          doneWithUser()

  # I don't like leaking big variables, could remove this for readability
  # Meant for passing into MongoDB
  {isMiscPatch, isTranslationPatch} = do ->
    deltas = require '../../app/core/deltas'

    isMiscPatch: (obj) ->
      expanded = deltas.flattenDelta obj.get 'delta'
      _.some expanded, (delta) -> 'i18n' not in delta.dataPath
    isTranslationPatch: (obj) ->
      expanded = deltas.flattenDelta obj.get 'delta'
      _.some expanded, (delta) -> 'i18n' in delta.dataPath

  Patch = require '../models/Patch'
  # filter is passed a mongoose document and should return a boolean,
  # determining whether the patch should be counted
  countPatchesByUsersInMemory = (query, filter, statName, done) ->
    updateUser = (user, count, doneUpdatingUser) ->
      method = if count then '$set' else '$unset'
      update = {}
      update[method] = {}
      update[method][statName] = count or ''
      log.info "... updating #{user.get('_id')} patches #{JSON.stringify(query)} #{statName} to #{count}, #{usersTotal} players found so far." if count
      User.findByIdAndUpdate user.get('_id'), update, doneUpdatingUser

    userStream = User.find({anonymous: false}).sort('_id').stream()
    streamFinished = false
    usersTotal = 0
    usersFinished = 0
    numberRunning = 0
    doneWithUser = (err) ->
      log.error err if err?
      ++usersFinished
      --numberRunning
      userStream.resume()
      done?() if streamFinished and usersFinished is usersTotal
    userStream.on 'error', (err) -> log.error err
    userStream.on 'close', -> streamFinished = true
    userStream.on 'data',  (user) ->
      ++usersTotal
      ++numberRunning
      userStream.pause() if numberRunning > 20
      userObjectID = user.get '_id'
      userStringID = userObjectID.toHexString()
      # Extend query with a patch ownership test
      _.extend query, {$or: [{creator: userObjectID}, {creator: userStringID}]}

      count = 0
      stream = Patch.where(query).stream()
      stream.on 'data', (doc) -> ++count if filter doc
      stream.on 'error', (err) ->
        updateUser user, count, doneWithUser
        log.error "Recalculating #{statName} for user #{user} stopped prematurely because of error"
      stream.on 'close', ->
        updateUser user, count, doneWithUser

  countPatchesByUsers = (query, statName, done) ->
    Patch = require '../models/Patch'

    userStream = User.find({anonymous: false}).sort('_id').stream()
    streamFinished = false
    usersTotal = 0
    usersFinished = 0
    numberRunning = 0
    doneWithUser = (err) ->
      log.error err if err?
      ++usersFinished
      --numberRunning
      userStream.resume()
      done?() if streamFinished and usersFinished is usersTotal
    userStream.on 'error', (err) -> log.error err
    userStream.on 'close', -> streamFinished = true
    userStream.on 'data',  (user) ->
      ++usersTotal
      ++numberRunning
      userStream.pause() if numberRunning > 20
      userObjectID = user.get '_id'
      userStringID = userObjectID.toHexString()
      # Extend query with a patch ownership test
      _.extend query, {$or: [{creator: userObjectID}, {creator: userStringID}]}

      Patch.count query, (err, count) ->
        method = if count then '$set' else '$unset'
        update = {}
        update[method] = {}
        update[method][statName] = count or ''
        log.info "... updating #{userStringID} patches #{query} to #{count}, #{usersTotal} players found so far." if count
        User.findByIdAndUpdate user.get('_id'), update, doneWithUser

  statRecalculators:
    gamesCompleted: (done) ->
      LevelSession = require '../models/LevelSession'

      userStream = User.find({anonymous: false}).sort('_id').stream()
      streamFinished = false
      usersTotal = 0
      usersFinished = 0
      numberRunning = 0
      doneWithUser = (err) ->
        log.error err if err?
        ++usersFinished
        --numberRunning
        userStream.resume()
        if streamFinished and usersFinished is usersTotal
          log.info "----------- Finished recalculating statistics for gamesCompleted for #{usersFinished} players. -----------"
          done?()
      userStream.on 'error', (err) -> log.error err
      userStream.on 'close', -> streamFinished = true
      userStream.on 'data',  (user) ->
        ++usersTotal
        ++numberRunning
        userStream.pause() if numberRunning > 20
        userID = user.get('_id').toHexString()

        LevelSession.count {creator: userID, 'state.complete': true}, (err, count) ->
          update = if count then {$set: 'stats.gamesCompleted': count} else {$unset: 'stats.gamesCompleted': ''}
          log.info "... updating #{userID} gamesCompleted to #{count}, #{usersTotal} players found so far." if Math.random() < 0.001
          User.findByIdAndUpdate user.get('_id'), update, doneWithUser

    articleEdits: (done) ->
      Article = require '../models/Article'
      countEdits Article, done

    levelEdits: (done) ->
      Level = require '../models/Level'
      countEdits Level, done

    levelComponentEdits: (done) ->
      LevelComponent = require '../models/LevelComponent'
      countEdits LevelComponent,  done

    levelSystemEdits: (done) ->
      LevelSystem = require '../models/LevelSystem'
      countEdits LevelSystem, done

    thangTypeEdits: (done) ->
      ThangType = require '../models/ThangType'
      countEdits ThangType, done

    patchesContributed: (done) ->
      countPatchesByUsers {'status': 'accepted'}, 'stats.patchesContributed', done

    patchesSubmitted: (done) ->
      countPatchesByUsers {}, 'stats.patchesSubmitted', done

    # The below need functions for filtering and are thus checked in memory
    totalTranslationPatches: (done) ->
      countPatchesByUsersInMemory {}, isTranslationPatch, 'stats.totalTranslationPatches', done

    totalMiscPatches: (done) ->
      countPatchesByUsersInMemory {}, isMiscPatch, 'stats.totalMiscPatches', done

    articleMiscPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'article'}, isMiscPatch, User.statsMapping.misc.article, done

    levelMiscPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'level'}, isMiscPatch, User.statsMapping.misc.level, done

    levelComponentMiscPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'level_component'}, isMiscPatch, User.statsMapping.misc['level.component'], done

    levelSystemMiscPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'level_system'}, isMiscPatch, User.statsMapping.misc['level.system'], done

    thangTypeMiscPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'thang_type'}, isMiscPatch, User.statsMapping.misc['thang.type'], done

    articleTranslationPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'article'}, isTranslationPatch, User.statsMapping.translations.article, done

    levelTranslationPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'level'}, isTranslationPatch, User.statsMapping.translations.level, done

    levelComponentTranslationPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'level_component'}, isTranslationPatch, User.statsMapping.translations['level.component'], done

    levelSystemTranslationPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'level_system'}, isTranslationPatch, User.statsMapping.translations['level.system'], done

    thangTypeTranslationPatches: (done) ->
      countPatchesByUsersInMemory {'target.collection': 'thang_type'}, isTranslationPatch, User.statsMapping.translations['thang.type'], done


  recalculateStats: (statName, done) =>
    done new Error 'Recalculation handler not found' unless statName of @statRecalculators
    @statRecalculators[statName] done

  recalculate: (req, res, statName) ->
    return @sendForbiddenError(res) unless req.user?.isAdmin()
    log.debug 'recalculate'
    return @sendNotFoundError(res) unless statName of @statRecalculators
    @recalculateStats statName
    @sendAccepted res, {}

module.exports = new UserHandler()
