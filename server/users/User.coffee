mongoose = require 'mongoose'
jsonschema = require '../../app/schemas/models/user'
crypto = require 'crypto'
{salt, isProduction} = require '../../server_config'
mail = require '../commons/mail'
log = require 'winston'
plugins = require '../plugins/plugins'
AnalyticsUsersActive = require '../analytics/AnalyticsUsersActive'

config = require '../../server_config'
stripe = require('stripe')(config.stripe.secretKey)

sendwithus = require '../sendwithus'
delighted = require '../delighted'

UserSchema = new mongoose.Schema({
  dateCreated:
    type: Date
    'default': Date.now
  currentCourse: {
    courseID: mongoose.Schema.Types.ObjectId
    courseInstanceID: mongoose.Schema.Types.ObjectId
  }
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

UserSchema.post('init', ->
  @set('anonymous', false) if @get('email')
)

UserSchema.methods.isInGodMode = ->
  p = @get('permissions')
  return p and 'godmode' in p

UserSchema.methods.isAdmin = ->
  p = @get('permissions')
  return p and 'admin' in p

UserSchema.methods.isArtisan = ->
  p = @get('permissions')
  return p and 'artisan' in p

UserSchema.methods.isAnonymous = ->
  @get 'anonymous'

UserSchema.methods.getUserInfo = ->
  id: @get('_id')
  email: if @get('anonymous') then 'Unregistered User' else @get('email')

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

emailNameMap =
  generalNews: 'announcement'
  adventurerNews: 'tester'
  artisanNews: 'level_creator'
  archmageNews: 'developer'
  scribeNews: 'article_editor'
  diplomatNews: 'translator'
  ambassadorNews: 'support'
  anyNotes: 'notification'

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

  mc?.lists.subscribe params, onSuccess, onFailure unless config.unittest

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

UserSchema.methods.register = (done) ->
  @set('anonymous', false)
  if (name = @get 'name')? and name isnt ''
    unconflictName name, (err, uniqueName) =>
      return done err if err
      @set 'name', uniqueName
      done()
  else done()
  if @isEmailSubscriptionEnabled 'generalNews'
    data =
      email_id: sendwithus.templates.welcome_email
      recipient:
        address: @get 'email'
    sendwithus.api.send data, (err, result) ->
      log.error "sendwithus post-save error: #{err}, result: #{result}" if err
    delighted.addDelightedUser @
  @saveActiveUser 'register'

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
  if xp > 0 then Math.floor(a * Math.log((1/b) * (xp + c))) + 1 else 1

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
  if email = @get('email')
    @set('emailLower', email.toLowerCase())
  if name = @get('name')
    @set('nameLower', name.toLowerCase())
  pwd = @get('password')
  if @get('password')
    @set('passwordHash', User.hashPassword(pwd))
    @set('password', undefined)
  if @get('email') and @get('anonymous') # a user registers
    @register next
  else
    next()
)

UserSchema.post 'save', (doc) ->
  doc.newsSubsChanged = not _.isEqual(_.pick(doc.get('emails'), mail.NEWS_GROUPS), _.pick(doc.startingEmails, mail.NEWS_GROUPS))
  UserSchema.statics.updateServiceSettings(doc)

UserSchema.post 'init', (doc) ->
  doc.startingEmails = _.cloneDeep(doc.get('emails'))

UserSchema.statics.hashPassword = (password) ->
  password = password.toLowerCase()
  shasum = crypto.createHash('sha512')
  shasum.update(salt + password)
  shasum.digest('hex')

UserSchema.statics.privateProperties = [
  'permissions', 'email', 'mailChimp', 'firstName', 'lastName', 'gender', 'facebookID',
  'gplusID', 'music', 'volume', 'aceConfig', 'employerAt', 'signedEmployerAgreement',
  'emailSubscriptions', 'emails', 'activity', 'stripe', 'stripeCustomerID', 'chinaVersion', 'country'
]
UserSchema.statics.jsonSchema = jsonschema
UserSchema.statics.editableProperties = [
  'name', 'photoURL', 'password', 'anonymous', 'wizardColor1', 'volume',
  'firstName', 'lastName', 'gender', 'ageRange', 'facebookID', 'gplusID', 'emails',
  'testGroupNumber', 'music', 'hourOfCode', 'hourOfCodeComplete', 'preferredLanguage',
  'wizard', 'aceConfig', 'autocastDelay', 'lastLevel', 'jobProfile', 'savedEmployerFilterAlerts',
  'heroConfig', 'iosIdentifierForVendor', 'siteref', 'referrer', 'currentCourse'
]

UserSchema.plugin plugins.NamedPlugin

module.exports = User = mongoose.model('User', UserSchema)

AchievablePlugin = require '../plugins/achievements'
UserSchema.plugin(AchievablePlugin)
