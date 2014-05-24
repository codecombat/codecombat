GRAVATAR_URL = 'https://www.gravatar.com/'
cache = {}
CocoModel = require('./CocoModel')

module.exports = class User extends CocoModel
  @className: "User"
  @schema: require 'schemas/models/user'
  urlRoot: "/db/user"

  initialize: ->
    super()
    @migrateEmails()

  isAdmin: ->
    permissions = @attributes['permissions'] or []
    return 'admin' in permissions

  displayName: ->
    @get('name') or "Anoner"

  lang: ->
    @get('preferredLanguage') or "en-US"

  getPhotoURL: (size=80, useJobProfilePhoto=false) ->
    photoURL = if useJobProfilePhoto then @get('jobProfile')?.photoURL else null
    photoURL ||= @get('photoURL')
    if photoURL
      prefix = if photoURL.search(/\?/) is -1 then "?" else "&"
      return "#{photoURL}#{prefix}s=#{size}" if photoURL.search('http') isnt -1  # legacy
      return "/file/#{photoURL}#{prefix}s=#{size}"
    return "/db/user/#{@id}/avatar?s=#{size}"

  @getByID = (id, properties, force) ->
    {me} = require('lib/auth')
    return me if me.id is id
    user = cache[id] or new module.exports({_id:id})
    if force or not cache[id]
      user.loading = true
      user.fetch(
        success: ->
          user.loading = false
          Backbone.Mediator.publish('user:fetched')
          #user.trigger 'sync'   # needed?
      )
    cache[id] = user
    user
    
  getEnabledEmails: ->
    @migrateEmails()
    emails = _.clone(@get('emails')) or {}
    emails = _.defaults emails, @schema().properties.emails.default
    (emailName for emailName, emailDoc of emails when emailDoc.enabled)
    
  setEmailSubscription: (name, enabled) ->
    newSubs = _.clone(@get('emails')) or {}
    (newSubs[name] ?= {}).enabled = enabled
    @set 'emails', newSubs
    
  emailMap:
    announcement: 'generalNews'
    developer: 'archmageNews'
    tester: 'adventurerNews'
    level_creator: 'artisanNews'
    article_editor: 'scribeNews'
    translator: 'diplomatNews'
    support: 'ambassadorNews'
    notification: 'anyNotes'

  migrateEmails: ->
    return if @attributes.emails or not @attributes.emailSubscriptions
    oldSubs = @get('emailSubscriptions') or []
    newSubs = {}
    newSubs[newSubName] = { enabled: oldSubName in oldSubs } for oldSubName, newSubName of @emailMap
    @set('emails', newSubs)
    
  isEmailSubscriptionEnabled: (name) -> (@get('emails') or {})[name]?.enabled
