mongoose = require('mongoose')
jsonschema = require('../schemas/user')
crypto = require('crypto')
{salt} = require('../../server_config')

UserSchema = new mongoose.Schema({
  dateCreated:
    type: Date
    'default': Date.now
}, {strict: false})

UserSchema.pre('init', (next) ->
  return next() unless jsonschema.properties?
  for prop, sch of jsonschema.properties
    @set(prop, sch.default) if sch.default?
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
  return callback?() if doc.updatedMailChimp
  return callback?() unless doc.get('email')
  existingProps = doc.get('mailChimp')
  emailChanged = (not existingProps) or existingProps?.email isnt doc.get('email')
  emailSubs = doc.get('emailSubscriptions')
  newGroups = (groupingMap[name] for name in emailSubs)
  if (not existingProps) and newGroups.length is 0
    return callback?() # don't add totally unsubscribed people to the list
  subsChanged = doc.currentSubscriptions isnt JSON.stringify(emailSubs)
  return callback?() unless emailChanged or subsChanged
  
  params = {}
  params.id = MAILCHIMP_LIST_ID
  params.email = if existingProps then {leid:existingProps.leid} else {email:doc.get('email')}
  params.merge_vars = { groupings: [ {id: MAILCHIMP_GROUP_ID, groups: newGroups} ] }
  params.update_existing = true
  
  onSuccess = (data) ->
    doc.set('mailChimp', data)
    doc.updatedMailChimp = true
    doc.save()
    callback?()
    
  onFailure = (error) ->
    console.error 'failed to subscribe', error, callback?
    doc.updatedMailChimp = true
    callback?()
  
  mc.lists.subscribe params, onSuccess, onFailure


UserSchema.pre('save', (next) ->
  @set('emailLower', @get('email')?.toLowerCase())
  @set('nameLower', @get('name')?.toLowerCase())
  pwd = @get('password')
  if @get('password')
    @set('passwordHash', User.hashPassword(pwd))
    @set('password', undefined)
  @set('anonymous', false) if @get('email')
  next()
)

MAILCHIMP_LIST_ID = 'e9851239eb'
MAILCHIMP_GROUP_ID = '4529'

groupingMap =
  announcement: 'Announcements'
  tester: 'Adventurers'
  level_creator: 'Artisans'
  developer: 'Archmages'
  article_editor: 'Scribes'
  translator: 'Diplomats'
  support: 'Ambassadors'

UserSchema.post 'save', (doc) ->
  UserSchema.statics.updateMailChimp(doc)

UserSchema.statics.hashPassword = (password) ->
  password = password.toLowerCase()
  shasum = crypto.createHash('sha512')
  shasum.update(salt + password)
  shasum.digest('hex')

module.exports = User = mongoose.model('User', UserSchema)