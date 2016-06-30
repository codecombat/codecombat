mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/user'
crypto = require 'crypto'
{salt, isProduction} = require '../../server_config'
mail = require '../commons/mail'
log = require 'winston'
plugins = require '../plugins/plugins'
AnalyticsUsersActive = require './AnalyticsUsersActive'
Classroom = require '../models/Classroom'
languages = require '../routes/languages'
_ = require 'lodash'
errors = require '../commons/errors'

config = require '../../server_config'
stripe = require('stripe')(config.stripe.secretKey)

sendwithus = require '../sendwithus'

UserSchema = new mongoose.Schema({
  dateCreated:
    type: Date
    'default': Date.now
}, {strict: false})

UserSchema.index({'dateCreated': 1})
UserSchema.index({'emailLower': 1}, {unique: true, sparse: true, name: 'emailLower_1'})
UserSchema.index({'facebookID': 1}, {sparse: true})
UserSchema.index({'gplusID': 1}, {sparse: true})
UserSchema.index({'iosIdentifierForVendor': 1}, {name: 'iOS identifier for vendor', sparse: true, unique: true})
UserSchema.index({'mailChimp.leid': 1}, {sparse: true})
UserSchema.index({'nameLower': 1}, {sparse: true, name: 'nameLower_1'})
UserSchema.index({'simulatedBy': 1})
UserSchema.index({'slug': 1}, {name: 'slug index', sparse: true, unique: true})
UserSchema.index({'stripe.subscriptionID': 1}, {unique: true, sparse: true})
UserSchema.index({'siteref': 1}, {name: 'siteref index', sparse: true})
UserSchema.index({'schoolName': 1}, {name: 'schoolName index', sparse: true})
UserSchema.index({'country': 1}, {name: 'country index', sparse: true})
UserSchema.index({'role': 1}, {name: 'role index', sparse: true})
UserSchema.index({'coursePrepaid._id': 1}, {name: 'course prepaid id index', sparse: true})

UserSchema.post('init', ->
  @set('anonymous', false) if @get('email')
)

UserSchema.methods.broadName = ->
  return '(deleted)' if @get('deleted')
  name = @get('name')
  return name if name
  name = _.filter([@get('firstName'), @get('lastName')]).join(' ')
  return name if name
  [emailName, emailDomain] = @get('email').split('@')
  return emailName if emailName
  return 'Anonymous'

UserSchema.methods.isInGodMode = ->
  p = @get('permissions')
  return p and 'godmode' in p

UserSchema.methods.isAdmin = ->
  p = @get('permissions')
  return p and 'admin' in p
  
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
  
UserSchema.methods.removeFromClassrooms = ->
  userID = @get('_id')
  yield Classroom.update(
    { members: userID }
    {
      $addToSet: { deletedMembers: userID }
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
  emailLower = email.toLowerCase()
  User.findOne({emailLower: emailLower}).exec(done)

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
  @set('emails', newSubs)
  @newsSubsChanged = true if newName in mail.NEWS_GROUPS

UserSchema.methods.gems = ->
  gemsEarned = @get('earned')?.gems ? 0
  gemsEarned = gemsEarned + 100000 if @isInGodMode()
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

UserSchema.statics.updateServiceSettings = (doc, callback) ->
  return callback?() unless isProduction or GLOBAL.testing
  return callback?() if doc.updatedMailChimp
  return callback?() unless doc.get('email')
  return callback?() unless doc.get('dateCreated')
  accountAgeMinutes = (new Date().getTime() - doc.get('dateCreated').getTime?() ? 0) / 1000 / 60
  return callback?() unless accountAgeMinutes > 30 or GLOBAL.testing
  existingProps = doc.get('mailChimp')
  emailChanged = (not existingProps) or existingProps?.email isnt doc.get('email')

  if emailChanged and customerID = doc.get('stripe')?.customerID
    unless stripe?.customers
      console.error('Oh my god, Stripe is not imported correctly-how could we have done this (again)?')
    stripe?.customers?.update customerID, {email:doc.get('email')}, (err, customer) ->
      console.error('Error updating stripe customer...', err) if err

  return callback?() unless emailChanged or doc.newsSubsChanged

  newGroups = []
  for [mailchimpEmailGroup, emailGroup] in _.zip(mail.MAILCHIMP_GROUPS, mail.NEWS_GROUPS)
    newGroups.push(mailchimpEmailGroup) if doc.isEmailSubscriptionEnabled(emailGroup)

  if (not existingProps) and newGroups.length is 0
    return callback?() # don't add totally unsubscribed people to the list

  params = {}
  params.id = mail.MAILCHIMP_LIST_ID
  params.email = if existingProps then {leid: existingProps.leid} else {email: doc.get('email')}
  params.merge_vars = {
    groupings: [{id: mail.MAILCHIMP_GROUP_ID, groups: newGroups}]
    'new-email': doc.get('email')
  }
  params.update_existing = true

  onSuccess = (data) ->
    data.email = doc.get('email')  # Make sure that we don't spam opt-in emails even if MailChimp doesn't update the email it gets in this object until they have confirmed.
    doc.set('mailChimp', data)
    doc.updatedMailChimp = true
    doc.save()
    callback?()

  onFailure = (error) ->
    log.error 'failed to subscribe', error, callback?
    doc.updatedMailChimp = true
    callback?()

  mc?.lists.subscribe params, onSuccess, onFailure

UserSchema.statics.statsMapping =
  edits:
    article: 'stats.articleEdits'
    level: 'stats.levelEdits'
    'level.component': 'stats.levelComponentEdits'
    'level.system': 'stats.levelSystemEdits'
    'thang.type': 'stats.thangTypeEdits'
    'Achievement': 'stats.achievementEdits'
    'campaign': 'stats.campaignEdits'
    'poll': 'stats.pollEdits'
  translations:
    article: 'stats.articleTranslationPatches'
    level: 'stats.levelTranslationPatches'
    'level.component': 'stats.levelComponentTranslationPatches'
    'level.system': 'stats.levelSystemTranslationPatches'
    'thang.type': 'stats.thangTypeTranslationPatches'
    'Achievement': 'stats.achievementTranslationPatches'
    'campaign': 'stats.campaignTranslationPatches'
    'poll': 'stats.pollTranslationPatches'
  misc:
    article: 'stats.articleMiscPatches'
    level: 'stats.levelMiscPatches'
    'level.component': 'stats.levelComponentMiscPatches'
    'level.system': 'stats.levelSystemMiscPatches'
    'thang.type': 'stats.thangTypeMiscPatches'
    'Achievement': 'stats.achievementMiscPatches'
    'campaign': 'stats.campaignMiscPatches'
    'poll': 'stats.pollMiscPatches'

UserSchema.statics.incrementStat = (id, statName, done, inc=1) ->
  id = mongoose.Types.ObjectId id if _.isString id
  @findById id, (err, user) ->
    log.error err if err?
    err = new Error "Could't find user with id '#{id}'" unless user or err
    return done() if err?
    user.incrementStat statName, done, inc

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
  User.findOne {slug: _.str.slugify(name)}, (err, otherUser) ->
    return done err if err?
    return done null, name unless otherUser
    suffix = _.random(0, 9) + ''
    unconflictName name + suffix, done

UserSchema.methods.sendWelcomeEmail = ->
  { welcome_email_student, welcome_email_user } = sendwithus.templates
  timestamp = (new Date).getTime()
  data =
    email_id: if @isStudent() then welcome_email_student else welcome_email_user
    recipient:
      address: @get('email')
      name: @broadName()
    email_data:
      name: @broadName()
      verify_link: "http://codecombat.com/user/#{@_id}/verify/#{@verificationCode(timestamp)}"
  sendwithus.api.send data, (err, result) ->
    log.error "sendwithus post-save error: #{err}, result: #{result}" if err

UserSchema.methods.hasSubscription = ->
  return false unless stripeObject = @get('stripe')
  return true if stripeObject.sponsorID
  return true if stripeObject.subscriptionID
  return true if stripeObject.free is true
  return true if _.isString(stripeObject.free) and new Date() < new Date(stripeObject.free)

UserSchema.methods.isPremium = ->
  return true if @isInGodMode()
  return true if @isAdmin()
  return true if @hasSubscription()
  return false

UserSchema.methods.isOnPremiumServer = ->
  @get('country') in ['china', 'brazil']

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
  if name = @get('name')
    @set('nameLower', name.toLowerCase())
  pwd = @get('password')
  if @get('password')
    @set('passwordHash', User.hashPassword(pwd))
    @set('password', undefined)
  next()
)

UserSchema.post 'save', (doc) ->
  doc.newsSubsChanged = not _.isEqual(_.pick(doc.get('emails'), mail.NEWS_GROUPS), _.pick(doc.startingEmails, mail.NEWS_GROUPS))
  UserSchema.statics.updateServiceSettings(doc)

  
UserSchema.post 'init', (doc) ->
  doc.wasTeacher = doc.isTeacher()
  doc.startingEmails = _.cloneDeep(doc.get('emails'))
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

UserSchema.methods.verificationCode = (timestamp) ->
  { _id, email } = this.toObject()
  shasum = crypto.createHash('sha256')
  hash = shasum.update(timestamp + salt + _id + email).digest('hex')
  return "#{timestamp}:#{hash}"

UserSchema.statics.privateProperties = [
  'permissions', 'email', 'mailChimp', 'firstName', 'lastName', 'gender', 'facebookID',
  'gplusID', 'music', 'volume', 'aceConfig', 'employerAt', 'signedEmployerAgreement',
  'emailSubscriptions', 'emails', 'activity', 'stripe', 'stripeCustomerID', 'chinaVersion', 'country',
  'schoolName', 'ageRange', 'role', 'enrollmentRequestSent'
]
UserSchema.statics.jsonSchema = jsonschema
UserSchema.statics.editableProperties = [
  'name', 'photoURL', 'password', 'anonymous', 'wizardColor1', 'volume',
  'firstName', 'lastName', 'gender', 'ageRange', 'facebookID', 'gplusID', 'emails',
  'testGroupNumber', 'music', 'hourOfCode', 'hourOfCodeComplete', 'preferredLanguage',
  'wizard', 'aceConfig', 'autocastDelay', 'lastLevel', 'jobProfile', 'savedEmployerFilterAlerts',
  'heroConfig', 'iosIdentifierForVendor', 'siteref', 'referrer', 'schoolName', 'role', 'birthday',
  'enrollmentRequestSent'
]

UserSchema.statics.serverProperties = ['passwordHash', 'emailLower', 'nameLower', 'passwordReset', 'lastIP']
UserSchema.statics.candidateProperties = [ 'jobProfile', 'jobProfileApproved', 'jobProfileNotes']

UserSchema.set('toObject', {
  transform: (doc, ret, options) ->
    req = options.req
    return ret unless req # TODO: Make deleting properties the default, but the consequences are far reaching
    publicOnly = options.publicOnly
    delete ret[prop] for prop in User.serverProperties
    includePrivates = not publicOnly and (req.user and (req.user.isAdmin() or req.user._id.equals(doc._id) or req.session.amActually is doc.id))
    if options.includedPrivates
      excludedPrivates = _.reject User.privateProperties, (prop) ->
        prop in options.includedPrivates
    else
      excludedPrivates = User.privateProperties
    delete ret[prop] for prop in excludedPrivates unless includePrivates
    delete ret[prop] for prop in User.candidateProperties
    return ret
})

UserSchema.statics.makeNew = (req) ->
  user = new User({anonymous: true})
  if global.testing
    # allows tests some control over user id creation
    newID = _.pad((User.idCounter++).toString(16), 24, '0')
    user.set('_id', newID)
  user.set 'testGroupNumber', Math.floor(Math.random() * 256)  # also in app/core/auth
  lang = languages.languageCodeFromAcceptedLanguages req.acceptedLanguages
  user.set 'preferredLanguage', lang if lang[...2] isnt 'en'
  user.set 'preferredLanguage', 'pt-BR' if not user.get('preferredLanguage') and /br\.codecombat\.com/.test(req.get('host'))
  user.set 'preferredLanguage', 'zh-HANS' if not user.get('preferredLanguage') and /cn\.codecombat\.com/.test(req.get('host'))
  user.set 'lastIP', (req.headers['x-forwarded-for'] or req.connection.remoteAddress)?.split(/,? /)[0]
  user.set 'country', req.country if req.country
  user


UserSchema.plugin plugins.NamedPlugin

module.exports = User = mongoose.model('User', UserSchema)
User.idCounter = 0

AchievablePlugin = require '../plugins/achievements'
UserSchema.plugin(AchievablePlugin)
