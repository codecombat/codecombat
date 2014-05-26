mongoose = require('mongoose')
jsonschema = require('../../app/schemas/models/user')
crypto = require('crypto')
{salt, isProduction} = require('../../server_config')
mail = require '../commons/mail'
log = require 'winston'

sendwithus = require '../sendwithus'

UserSchema = new mongoose.Schema({
  dateCreated:
    type: Date
    'default': Date.now
}, {strict: false})

UserSchema.pre('init', (next) ->
  return next() unless jsonschema.properties?
  for prop, sch of jsonschema.properties
    continue if prop is 'emails' # defaults may change, so don't carry them over just yet
    @set(prop, sch.default) if sch.default?
  next()
)

UserSchema.post('init', ->
  @set('anonymous', false) if @get('email')
)

UserSchema.methods.isAdmin = ->
  p = @get('permissions')
  return p and 'admin' in p

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

UserSchema.methods.isEmailSubscriptionEnabled = (newName) ->
  emails = @get 'emails'
  if not emails
    oldSubs = @get('emailSubscriptions')
    oldName = emailNameMap[newName]
    return oldName and oldName in oldSubs if oldSubs
  emails ?= {}
  _.defaults emails, _.cloneDeep(jsonschema.properties.emails.default)
  return emails[newName]?.enabled

UserSchema.statics.updateMailChimp = (doc, callback) ->
  return callback?() unless isProduction or GLOBAL.testing
  return callback?() if doc.updatedMailChimp
  return callback?() unless doc.get('email')
  existingProps = doc.get('mailChimp')
  emailChanged = (not existingProps) or existingProps?.email isnt doc.get('email')
  return callback?() unless emailChanged or doc.newsSubsChanged

  newGroups = []
  for [mailchimpEmailGroup, emailGroup] in _.zip(mail.MAILCHIMP_GROUPS, mail.NEWS_GROUPS)
    newGroups.push(mailchimpEmailGroup) if doc.isEmailSubscriptionEnabled(emailGroup)

  if (not existingProps) and newGroups.length is 0
    return callback?() # don't add totally unsubscribed people to the list

  params = {}
  params.id = mail.MAILCHIMP_LIST_ID
  params.email = if existingProps then {leid:existingProps.leid} else {email:doc.get('email')}
  params.merge_vars = { groupings: [ {id: mail.MAILCHIMP_GROUP_ID, groups: newGroups} ] }
  params.update_existing = true
  params.double_optin = false

  onSuccess = (data) ->
    doc.set('mailChimp', data)
    doc.updatedMailChimp = true
    doc.save()
    callback?()

  onFailure = (error) ->
    log.error 'failed to subscribe', error, callback?
    doc.updatedMailChimp = true
    callback?()

  mc?.lists.subscribe params, onSuccess, onFailure


UserSchema.pre('save', (next) ->
  @set('emailLower', @get('email')?.toLowerCase())
  @set('nameLower', @get('name')?.toLowerCase())
  pwd = @get('password')
  if @get('password')
    @set('passwordHash', User.hashPassword(pwd))
    @set('password', undefined)
  if @get('email') and @get('anonymous')
    @set('anonymous', false)
    @set('permissions', ['admin']) if not isProduction
    data =
      email_id: sendwithus.templates.welcome_email
      recipient:
        address: @get 'email'
    sendwithus.api.send data, (err, result) ->
      log.error "sendwithus post-save error: #{err}, result: #{result}" if err
  next()
)

UserSchema.post 'save', (doc) ->
  UserSchema.statics.updateMailChimp(doc)

UserSchema.statics.hashPassword = (password) ->
  password = password.toLowerCase()
  shasum = crypto.createHash('sha512')
  shasum.update(salt + password)
  shasum.digest('hex')

module.exports = User = mongoose.model('User', UserSchema)
