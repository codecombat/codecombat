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
    @set(prop, sch.default) if sch.default?
  @set('permissions', ['admin']) if not isProduction
  next()
)

UserSchema.post('init', ->
  @set('anonymous', false) if @get('email')
  @currentSubscriptions = JSON.stringify(@get('emailSubscriptions'))
)

UserSchema.methods.isAdmin = ->
  p = @get('permissions')
  return p and 'admin' in p

UserSchema.statics.updateMailChimp = (doc, callback) ->
  return callback?() unless isProduction
  return callback?() if doc.updatedMailChimp
  return callback?() unless doc.get('email')
  existingProps = doc.get('mailChimp')
  emailChanged = (not existingProps) or existingProps?.email isnt doc.get('email')
  emailSubs = doc.get('emailSubscriptions')
  gm = mail.MAILCHIMP_GROUP_MAP
  newGroups = (gm[name] for name in emailSubs when gm[name]?)
  if (not existingProps) and newGroups.length is 0
    return callback?() # don't add totally unsubscribed people to the list
  subsChanged = doc.currentSubscriptions isnt JSON.stringify(emailSubs)
  return callback?() unless emailChanged or subsChanged

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
    data =
      email_id: sendwithus.templates.welcome_email
      recipient:
        address: @get 'email'
    sendwithus.api.send data, (err, result) ->
      log.error 'error', err, 'result', result if err
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
