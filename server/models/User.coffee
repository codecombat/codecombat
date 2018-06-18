moment = require 'moment'
mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/user'
crypto = require 'crypto'
{salt, isProduction} = require '../../server_config'
log = require 'winston'
plugins = require '../plugins/plugins'
AnalyticsUsersActive = require './AnalyticsUsersActive'
Classroom = require '../models/Classroom'
languages = require '../routes/languages'
_ = require 'lodash'
errors = require '../commons/errors'
Promise = require 'bluebird'
co = require 'co'
core_utils = require '../../app/core/utils'
mailChimp = require '../lib/mail-chimp'
{ makeHostUrl } = require '../commons/urls'

config = require '../../server_config'
stripe = require('../lib/stripe_utils').api

sendgrid = require '../sendgrid'

countryList = require('country-list')()
geoip = require '@basicer/geoip-lite'

UserSchema = new mongoose.Schema({
  dateCreated:
    type: Date
    'default': Date.now
}, {strict: false})

UserSchema.index({'dateCreated': 1})
UserSchema.index({'emailLower': 1}, {unique: true, sparse: true, name: 'emailLower_1'})
UserSchema.index({'facebookID': 1}, {sparse: true})
UserSchema.index({'gplusID': 1}, {sparse: true})
UserSchema.index({'cleverID': 1}, {sparse: true})
UserSchema.index({'iosIdentifierForVendor': 1}, {name: 'iOS identifier for vendor', sparse: true, unique: true})
UserSchema.index({'mailChimp.leid': 1}, {sparse: true}) # deprecated
UserSchema.index({'mailChimp.email': 1}, {sparse: true})
UserSchema.index({'nameLower': 1}, {sparse: true, name: 'nameLower_1'})
UserSchema.index({'simulatedBy': 1})
UserSchema.index({'slug': 1}, {name: 'slug index', sparse: true, unique: true})
UserSchema.index({'israelId': 1}, {name: 'israelId index', sparse: true, unique: true})
UserSchema.index({'stripe.subscriptionID': 1}, {unique: true, sparse: true})
UserSchema.index({'siteref': 1}, {name: 'siteref index', sparse: true})
UserSchema.index({'schoolName': 1}, {name: 'schoolName index', sparse: true})
UserSchema.index({'country': 1}, {name: 'country index', sparse: true})
UserSchema.index({'role': 1}, {name: 'role index', sparse: true})
UserSchema.index({'coursePrepaid._id': 1}, {name: 'course prepaid id index', sparse: true})
UserSchema.index({'oAuthIdentities.provider': 1, 'oAuthIdentities.id': 1}, {name: 'oauth identities index', unique: true, sparse: true})

UserSchema.methods.broadName = ->
  return '(deleted)' if @get('deleted')
  name = _.filter([@get('firstName'), @get('lastName')]).join(' ')
  return name if name
  name = @get('name')
  return name if name
  [emailName, emailDomain] = @get('email').split('@') if @get('email')
  return emailName if emailName
  return 'Anonymous'

UserSchema.methods.cancelPayPalSubscription = co.wrap ->
  userPayPalData = _.clone(@get('payPal') ? {})
  return unless userPayPalData.billingAgreementID

  delete userPayPalData.billingAgreementID
  userPayPalData.cancelDate = new Date()
  @set('payPal', userPayPalData)

  # Use existing stripe.free end date functionality to run out remainder of cancelled payPal sub
  # Approximating end date via uniform 31-day months
  stripeInfo = _.cloneDeep(@get('stripe') ? {})
  endDate = if userPayPalData.subscribeDate then moment(userPayPalData.subscribeDate) else moment()
  today = moment()
  endDate.add(1, 'M')  while endDate.isBefore(today)
  endDate.add(2, 'd')
  stripeInfo.free = endDate.format().substring(0, 10)
  @set('stripe', stripeInfo)

  yield @save()

UserSchema.methods.isInGodMode = ->
  p = @get('permissions')
  return p and 'godmode' in p

UserSchema.methods.isAdmin = ->
  p = @get('permissions')
  return p and 'admin' in p

UserSchema.methods.isLicensor = ->
  p = @get('permissions')
  return p and 'licensor' in p

UserSchema.methods.isVerifiedTeacher = ->
  return Boolean(@get('verifiedTeacher'))

UserSchema.methods.hasPermission = (neededPermissions) ->
  permissions = @get('permissions') or []
  if _.contains(permissions, 'admin')
    return true
  if _.isString(neededPermissions)
    neededPermissions = [neededPermissions]
  return _.size(_.intersection(permissions, neededPermissions))

UserSchema.methods.isArtisan = ->
  p = @get('permissions')
  return p and 'artisan' in p

UserSchema.methods.isAnonymous = ->
  @get 'anonymous'

UserSchema.statics.teacherRoles = ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent']

UserSchema.methods.isTeacher = ->
  return @get('role') in User.teacherRoles

UserSchema.methods.isStudent = ->
  return @get('role') is 'student'

UserSchema.methods.getUserInfo = ->
  id: @get('_id')
  email: if @get('anonymous') then 'Unregistered User' else @get('email')

UserSchema.methods.inEU = (defaultIfUnknown=true) -> unless @get('country') then defaultIfUnknown else core_utils.inEU(@get('country'))

UserSchema.methods.removeFromClassrooms = ->
  userID = @get('_id')
  yield Classroom.update(
    { members: userID }
    {
      $pull: { members: userID }
    }
    { multi: true }
  )

UserSchema.methods.trackActivity = (activityName, increment) ->
  now = new Date()
  increment ?= parseInt increment or 1
  increment = Math.max increment, 0
  activity = @get('activity') ? {}
  activity[activityName] ?= {first: now, count: 0}
  activity[activityName].count += increment
  activity[activityName].last = now
  @set 'activity', activity
  activity

UserSchema.statics.search = (term, done) ->
  utils = require '../lib/utils'
  if utils.isID(term)
    query = {_id: mongoose.Types.ObjectId(term)}
  else
    term = term.toLowerCase()
    query = $or: [{nameLower: term}, {emailLower: term}]
  return User.findOne(query).exec(done)

UserSchema.statics.findByEmail = (email, done=_.noop) ->
  emailLower = email?.toLowerCase()
  return Promise.resolve(null) if _.isEmpty(emailLower)
  User.findOne({emailLower: emailLower}).exec(done)

UserSchema.statics.findByName = (name, done=_.noop) ->
  nameLower = name?.toLowerCase()
  slug = _.str.slugify(name)
  return Promise.resolve(null) if _.isEmpty(nameLower) and _.isEmpty(slug)
  User.findOne({$or: [{nameLower}, {slug}]}).exec(done)

emailNameMap =
  generalNews: 'announcement'
  adventurerNews: 'tester'
  artisanNews: 'level_creator'
  archmageNews: 'developer'
  scribeNews: 'article_editor'
  diplomatNews: 'translator'
  ambassadorNews: 'support'
  anyNotes: 'notification'
  teacherNews: 'teacher'

UserSchema.methods.setEmailSubscription = (newName, enabled) ->
  oldSubs = _.clone @get('emailSubscriptions')
  if oldSubs and oldName = emailNameMap[newName]
    oldSubs = (s for s in oldSubs when s isnt oldName)
    oldSubs.push(oldName) if enabled
    @set('emailSubscriptions', oldSubs)

  newSubs = _.clone(@get('emails') or _.cloneDeep(jsonschema.properties.emails.default))
  newSubs[newName] ?= {}
  newSubs[newName].enabled = enabled

  consentHistory = _.cloneDeep(@get('consentHistory') or [])
  for k, v of newSubs when !!v.enabled isnt !!@get('emails')?[k]?.enabled
    consentHistory.push
      action: if v.enabled then 'allow' else 'forbid'
      date: new Date()
      type: 'email'
      emailHash: User.hashEmail(@get('email'))
      description: k
  @set('consentHistory', consentHistory)
  @set('emails', newSubs)

UserSchema.methods.gems = ->
  gemsEarned = @get('earned')?.gems ? 0
  gemsEarned = gemsEarned + 100000 if @isInGodMode()
  gemsEarned += 1000 if @get('hourOfCode')
  gemsPurchased = @get('purchased')?.gems ? 0
  gemsSpent = @get('spent') ? 0
  gemsEarned + gemsPurchased - gemsSpent

UserSchema.methods.isEmailSubscriptionEnabled = (newName) ->
  emails = @get 'emails'
  if not emails
    oldSubs = @get('emailSubscriptions')
    oldName = emailNameMap[newName]
    return oldName and oldName in oldSubs if oldSubs
  emails ?= {}
  _.defaults emails, _.cloneDeep(jsonschema.properties.emails.default)
  return emails[newName]?.enabled

UserSchema.methods.emailChanged = -> @originalEmail isnt @get('emailLower')

UserSchema.methods.updateServiceSettings = co.wrap ->
  return unless isProduction or GLOBAL.testing
  return if @updatedMailChimp
  if @emailChanged() and customerID = @get('stripe')?.customerID
    unless stripe?.customers
      console.error('Oh my god, Stripe is not imported correctly-how could we have done this (again)?')
    stripe?.customers?.update customerID, {email:@get('email')}, (err, customer) ->
      console.error('Error updating stripe customer...', err) if err

  newsSubsChanged = not _.isEqual(@get('emails'), @startingEmails)
  if @emailChanged() or newsSubsChanged
    yield @updateMailChimp()


UserSchema.methods.updateMailChimp = co.wrap ->

  # construct interests object for MailChimp
  interests = {}
  for interest in mailChimp.interests
    interests[interest.mailChimpId] = @isEmailSubscriptionEnabled(interest.property)
  anyInterests = _.any(_.values(interests))

  # grab the email this user has registered on MailChimp
  { email: mailChimpEmail } = @get('mailChimp') or {}
  mailChimpEmail = mailChimpEmail.toLowerCase() if mailChimpEmail

  # don't do anything for people who are unsubscribed and never were subscribed
  return unless mailChimpEmail or anyInterests

  # if user's email does not match their mailChimp email, unsubscribe the old email
  if mailChimpEmail and mailChimpEmail isnt @get('emailLower')
    body = {
      email_address: mailChimpEmail
      status: 'unsubscribed'
    }
    yield mailChimp.api.put(mailChimp.makeSubscriberUrl(mailChimpEmail), body)
    yield @update({$unset: {'mailChimp':''}})
    mailChimpEmail = null # from here on, have logic treat this as a new subscriber addition

  # need an email to subscribe!
  email = @get('emailLower')
  return unless email

  # check if email is verified here or there
  emailVerified = @get('emailVerified')
  if mailChimpEmail and not emailVerified
    try
      subscriber = yield mailChimp.api.get(mailChimp.makeSubscriberUrl(mailChimpEmail))
      if subscriber.status is 'subscribed'
        emailVerified = true
    catch e
      console.log 'failed to get mailchimp status', e

  # don't add new users unless their email is verified
  return unless emailVerified or mailChimpEmail

  body = {
    interests
    email_address: email
    status: if anyInterests and emailVerified then 'subscribed' else 'unsubscribed'
    merge_fields:
      FNAME: @get('firstName')
      LNAME: @get('lastName')
  }
  yield mailChimp.api.put(mailChimp.makeSubscriberUrl(email), body)
  yield @update({$set: {mailChimp: {email}}})


UserSchema.statics.statsMapping =
  edits:
    article: 'stats.articleEdits'
    level: 'stats.levelEdits'
    'level.component': 'stats.levelComponentEdits'
    'level_component': 'stats.levelComponentEdits'
    'level.system': 'stats.levelSystemEdits'
    'level_system': 'stats.levelSystemEdits'
    'thang.type': 'stats.thangTypeEdits'
    'thang_type': 'stats.thangTypeEdits'
    'Achievement': 'stats.achievementEdits'
    'achievement': 'stats.achievementEdits'
    'campaign': 'stats.campaignEdits'
    'poll': 'stats.pollEdits'
    'course': 'stats.courseEdits'
  translations:
    article: 'stats.articleTranslationPatches'
    level: 'stats.levelTranslationPatches'
    'level.component': 'stats.levelComponentTranslationPatches'
    'level_component': 'stats.levelComponentTranslationPatches'
    'level.system': 'stats.levelSystemTranslationPatches'
    'level_system': 'stats.levelSystemTranslationPatches'
    'thang.type': 'stats.thangTypeTranslationPatches'
    'thang_type': 'stats.thangTypeTranslationPatches'
    'Achievement': 'stats.achievementTranslationPatches'
    'achievement': 'stats.achievementTranslationPatches'
    'campaign': 'stats.campaignTranslationPatches'
    'poll': 'stats.pollTranslationPatches'
    'course': 'stats.courseTranslationPatches'
  misc:
    article: 'stats.articleMiscPatches'
    level: 'stats.levelMiscPatches'
    'level.component': 'stats.levelComponentMiscPatches'
    'level_component': 'stats.levelComponentMiscPatches'
    'level.system': 'stats.levelSystemMiscPatches'
    'level_system': 'stats.levelSystemMiscPatches'
    'thang.type': 'stats.thangTypeMiscPatches'
    'thang_type': 'stats.thangTypeMiscPatches'
    'Achievement': 'stats.achievementMiscPatches'
    'achievement': 'stats.achievementMiscPatches'
    'campaign': 'stats.campaignMiscPatches'
    'poll': 'stats.pollMiscPatches'
    'course': 'stats.courseMiscPatches'

# TODO: Migrate from incrementStat to incrementStatAsync
UserSchema.statics.incrementStatAsync = Promise.promisify (id, statName, options={}, done) ->
  # A shim over @incrementStat, providing a Promise interface
  if _.isFunction(options)
    done = options
    options = {}
  @incrementStat(id, statName, done, options.inc or 1)

UserSchema.statics.incrementStat = (id, statName, done=_.noop, inc=1) ->
  _id = if _.isString(id) then mongoose.Types.ObjectId(id) else id
  update = {$inc: {}}
  update.$inc[statName] = inc
  @update({_id}, update).exec((err, res) ->
    if not res.nModified
      log.warn "Did not update user stat '#{statName}' for '#{id}'"
    done?()
  )

UserSchema.methods.incrementStat = (statName, done, inc=1) ->
  if /^concepts\./.test statName
    # Concept stats are nested a level deeper.
    concepts = @get('concepts') or {}
    concept = statName.split('.')[1]
    concepts[concept] = (concepts[concept] or 0) + inc
    @set 'concepts', concepts
  else
    @set statName, (@get(statName) or 0) + inc
  @save (err) -> done?(err)

UserSchema.statics.unconflictName = unconflictName = (name, done) ->
  slug = _.str.slugify(name)
  if slug
    query = {slug: slug}
  else
    # For un-sluggable names (like Chinese usernames), check based on nameLower
    query = {nameLower: name.toLowerCase()}
  User.findOne query, (err, otherUser) ->
    return done err if err?
    return done null, name unless otherUser
    nameWithSuffix = name + _.random(0, 9)
    while _.str.slugify(nameWithSuffix).length < 4
      # Skip suggesting really short ones to save queries (they probably wouldn't work)
      nameWithSuffix += _.random(0, 9)
    unconflictName nameWithSuffix, done

UserSchema.statics.unconflictNameAsync = Promise.promisify(unconflictName)

UserSchema.methods.sendWelcomeEmail = co.wrap (req) ->
  return if not @get('email')
  return if core_utils.isSmokeTestEmail(@get('email'))
  templateId = if @isStudent() then sendgrid.templates.welcome_email_student
  else if @isTeacher() then sendgrid.templates.welcome_email_teacher
  else sendgrid.templates.welcome_email_user
  msg =
    to:
      email: @get('emailLower')
      name: @broadName()
    from:
      email: config.mail.username
      name: 'CodeCombat'
    templateId: templateId
    substitutions:
      name: @broadName()
      verify_link: makeHostUrl(req, "/user/#{@_id}/verify/#{@verificationCode((new Date).getTime())}")
      teacher: @isTeacher()
      email: @get('emailLower')
  try
    yield sendgrid.api.send(msg)
  catch err
    log.error "sendgrid post-save error: #{err}"
    log.error "sendgrid post-save error email context:"
    log.error JSON.stringify(msg, null, 2)

UserSchema.methods.hasSubscription = ->
  if payPal = @get('payPal')
    return true if payPal.billingAgreementID
  if stripeObject = @get('stripe')
    return true if stripeObject.sponsorID
    return true if stripeObject.subscriptionID
    return true if stripeObject.free is true
    return true if _.isString(stripeObject.free) and new Date() < new Date(stripeObject.free)
  false


UserSchema.methods.isPremium = ->
  return true if @isInGodMode()
  return true if @isAdmin()
  return true if @hasSubscription()
  return false

UserSchema.methods.isOnPremiumServer = ->
  return true if @get('country') in ['brazil']
  return false

UserSchema.methods.level = ->
  xp = @get('points') or 0
  a = 5
  b = c = 100
  if xp > 0 then Math.floor(a * Math.log((1 / b) * (xp + c))) + 1 else 1

UserSchema.methods.isEnrolled = ->
  coursePrepaid = @get('coursePrepaid')
  return false unless coursePrepaid
  return true unless coursePrepaid.endDate
  return coursePrepaid.endDate > new Date().toISOString()

UserSchema.methods.prepaidType = ->
  # TODO: remove once legacy prepaidIDs are migrated to objects
  return undefined unless @get('coursePrepaid') or @get('coursePrepaidID')
  # NOTE: Default type is 'course' if no type is marked on the user's copy
  return @get('coursePrepaid')?.type or 'course'

UserSchema.methods.prepaidIncludesCourse = (course) ->
  # TODO: Migrate legacy prepaids that just use coursePrepaidID
  return false if not (@get('coursePrepaid') or @get('coursePrepaidID'))
  includedCourseIDs = @get('coursePrepaid')?.includedCourseIDs
  return true if !includedCourseIDs # NOTE: Full licenses implicitly include all courses
  courseID = course.id or course
  return courseID.toString() in includedCourseIDs.map((id)->id.toString())

UserSchema.methods.hasLogInMethod = ->
  return true if _.any([
    @get('facebookID')
    @get('gplusID')
    @get('githubID')
    @get('cleverID')
    _.size(@get('oAuthIdentities'))
    @get('passwordHash')
  ])

UserSchema.statics.saveActiveUser = (id, event, done=null) ->
  # TODO: Disabling this until we know why our app servers CPU grows out of control.
  return done?()
  id = mongoose.Types.ObjectId id if _.isString id
  @findById id, (err, user) ->
    if err?
      log.error err
    else
      user?.saveActiveUser event
    done?()

UserSchema.methods.saveActiveUser = (event, done=null) ->
  # TODO: Disabling this until we know why our app servers CPU grows out of control.
  return done?()
  try
    return done?() if @isAdmin()
    userID = @get('_id')

    # Create if no active user entry for today
    today = new Date()
    minDate = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()))
    AnalyticsUsersActive.findOne({created: {$gte: minDate}, creator: mongoose.Types.ObjectId(userID)}).exec (err, activeUser) ->
      if err?
        log.error "saveActiveUser error retrieving active users: #{err}"
      else if not activeUser
        newActiveUser = new AnalyticsUsersActive()
        newActiveUser.set 'creator', userID
        newActiveUser.set 'event', event
        newActiveUser.save (err) ->
          log.error "Level session saveActiveUser error saving active user: #{err}" if err?
      done?()
  catch err
    log.error err
    done?()

UserSchema.pre('save', (next) ->
  if _.isNaN(@get('purchased')?.gems)
    return next(new errors.InternalServerError('Attempting to save NaN to user'))
  Classroom = require './Classroom'
  if @isTeacher() and not @wasTeacher
    Classroom.update({members: @_id}, {$pull: {members: @_id}}, {multi: true}).exec (err, res) ->

  if email = @get('email')
    @set('emailLower', email.toLowerCase())
  else
    @set('email', undefined)
    @set('emailLower', undefined)
  if name = @get('name')
    if not @allowEmailNames # for testing
      filter = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,63}$/i  # https://news.ycombinator.com/item?id=5763990
      if filter.test(name)
        return next(new errors.UnprocessableEntity('Username may not be an email'))

    @set('nameLower', name.toLowerCase())
  else
    @set('name', undefined)
    @set('nameLower', undefined)

  if _.isEmpty(@get('firstName'))
    @set('firstName', undefined)
  if _.isEmpty(@get('lastName'))
    @set('lastName', undefined)

  unless email or name or @get('anonymous') or @get('deleted')
    return next(new errors.UnprocessableEntity('User needs a username or email address'))

  pwd = @get('password')
  if @get('password')
    @set('passwordHash', User.hashPassword(pwd))
    @set('password', undefined)

  if @hasLogInMethod() and @get('anonymous')
    @set('anonymous', false)

  if _.size(@get('birthday')) > 7
    @set('birthday', @get('birthday').slice(0,7)) # Limit to year/month

  if email and (@get('consentHistory') ? []).length is 0
    # Initialize consentHistory if needed (new user account, or old one before we saved this)
    consentHistory = []
    for k, v of (@get('emails') ? {}) when v.enabled
      consentHistory.push
        action: 'allow'
        date: new Date()
        type: 'email'
        emailHash: User.hashEmail(email)
        description: k
    @set('consentHistory', consentHistory) if consentHistory.length

  next()
)

UserSchema.post 'save', co.wrap ->
  try
    yield @updateServiceSettings()
  catch e
    console.error 'User Post Save Error:', e.stack


UserSchema.post 'init', ->
  @set('anonymous', false) if @get('email') # TODO: Remove once User handler waterfall-signup system is removed, and we make sure all signup methods set anonymous to false
  @originalEmail = @get('emailLower')
  @wasTeacher = @isTeacher()
  @startingEmails = _.cloneDeep(@get('emails'))
  if @get('coursePrepaidID') and not @get('coursePrepaid')
    Prepaid = require './Prepaid'
    @set('coursePrepaid', {
      _id: @get('coursePrepaidID')
      startDate: Prepaid.DEFAULT_START_DATE
      endDate: Prepaid.DEFAULT_END_DATE
    })
    @set('coursePrepaidID', undefined)

UserSchema.statics.hashPassword = (password) ->
  password = password.toLowerCase()
  shasum = crypto.createHash('sha512')
  shasum.update(salt + password)
  shasum.digest('hex')

UserSchema.statics.hashEmail = (email) ->
  email = email.toLowerCase()
  shasum = crypto.createHash('sha512')
  shasum.update(salt + email)
  shasum.digest('hex')

UserSchema.methods.verificationCode = (timestamp) ->
  { _id, email } = this.toObject()
  shasum = crypto.createHash('sha256')
  hash = shasum.update(timestamp + salt + _id + email).digest('hex')
  return "#{timestamp}:#{hash}"

UserSchema.statics.privateProperties = [
  'permissions', 'email', 'mailChimp', 'firstName', 'lastName', 'gender', 'facebookID',
  'gplusID', 'music', 'volume', 'aceConfig',
  'emailSubscriptions', 'emails', 'activity', 'stripe', 'stripeCustomerID',
  'schoolName', 'ageRange', 'role', 'enrollmentRequestSent', 'oAuthIdentities',
  'coursePrepaid', 'coursePrepaidID', 'lastAnnouncementSeen'
]
UserSchema.statics.jsonSchema = jsonschema
UserSchema.statics.editableProperties = [
  'name', 'photoURL', 'password', 'anonymous', 'wizardColor1', 'volume',
  'firstName', 'lastName', 'gender', 'ageRange', 'facebookID', 'gplusID', 'emails',
  'testGroupNumber', 'music', 'hourOfCode', 'hourOfCodeComplete', 'preferredLanguage',
  'wizard', 'aceConfig', 'autocastDelay', 'lastLevel',
  'heroConfig', 'iosIdentifierForVendor', 'siteref', 'referrer', 'schoolName', 'role', 'birthday',
  'enrollmentRequestSent', 'israelId', 'school', 'lastAnnouncementSeen', 'unsubscribedFromMarketingEmails'
]
UserSchema.statics.adminEditableProperties = [
  'purchased'
]

UserSchema.statics.serverProperties = ['passwordHash', 'emailLower', 'nameLower', 'passwordReset', 'consentHistory', 'geo']

UserSchema.set('toObject', {
  transform: (doc, ret, options) ->
    if ret.preferredLanguage is null
      # some users get preferredLanguage of null and it breaks the app for them. Have mongoose replace nulls
      ret.preferredLanguage = 'en-US'
    req = options.req
    return ret unless req
    publicOnly = options.publicOnly
    delete ret[prop] for prop in User.serverProperties
    includePrivates = not publicOnly and (req.user and (req.user.isAdmin() or req.user._id.equals(doc._id) or req.session.amActually is doc.id))
    if options.includedPrivates
      excludedPrivates = _.reject User.privateProperties, (prop) ->
        prop in options.includedPrivates
    else
      excludedPrivates = User.privateProperties
    delete ret[prop] for prop in excludedPrivates unless includePrivates
    return ret
})

UserSchema.statics.makeNew = (req) ->
  user = new User({anonymous: true})
  if global.testing
    # allows tests some control over user id creation
    newID = _.pad((User.idCounter++).toString(16), 24, '0')
    user.set('_id', newID)
  user.set 'testGroupNumber', Math.floor(Math.random() * 256)  # also in app/core/auth
  lang = languages.languageCodeFromRequest req
  { preferredLanguage } = req.query
  if preferredLanguage and _.contains(languages.languageCodes, preferredLanguage)
    user.set({ preferredLanguage })
  user.set 'preferredLanguage', lang if lang[...2] isnt 'en'
  user.set 'preferredLanguage', 'pt-BR' if not user.get('preferredLanguage') and /br\.codecombat\.com/.test(req.get('host'))
  user.set 'preferredLanguage', 'zh-HANS' if not user.get('preferredLanguage') and /cn\.codecombat\.com/.test(req.get('host'))
  if ip = (req.headers['x-forwarded-for'] or req.connection.remoteAddress)?.split(/,? /)[0]
    geo = geoip.lookup(ip)
    if geo
      userGeo = {}
      userGeo.country = geo.country
      if country = geo.country
          userGeo.countryName = countryList.getName(country)
      userGeo.region = geo.region
      userGeo.city = geo.city
      userGeo.ll = geo.ll
      userGeo.metro = geo.metro
      userGeo.zip = geo.zip
      user.set 'geo', userGeo
  if req.country                        # Storing the country name again since user.country is being used in various other files
    user.set 'country', req.country
  else if userGeo?.countryName
    user.set 'country', userGeo.countryName
  user.set 'createdOnHost', req.headers.host
  user


UserSchema.plugin plugins.NamedPlugin

UserSchema.virtual('subscription').get ->
  subscription = {
    active: @hasSubscription()
  }

  { free } = @get('stripe') ? {}
  if _.isString(free)
    subscription.ends = new Date(free).toISOString()

  return subscription

UserSchema.virtual('license').get ->
  license = {
    active: @isEnrolled()
  }
  { endDate } = @get('coursePrepaid') ? {}
  license.ends = endDate if endDate
  return license

module.exports = User = mongoose.model('User', UserSchema)
User.idCounter = 0

AchievablePlugin = require '../plugins/achievements'
UserSchema.plugin(AchievablePlugin)
