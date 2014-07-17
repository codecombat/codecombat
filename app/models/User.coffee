GRAVATAR_URL = 'https://www.gravatar.com/'
cache = {}
CocoModel = require './CocoModel'
util = require 'lib/utils'

module.exports = class User extends CocoModel
  @className: 'User'
  @schema: require 'schemas/models/user'
  urlRoot: '/db/user'
  notyErrors: false

  initialize: ->
    super()
    @migrateEmails()

  isAdmin: ->
    permissions = @attributes['permissions'] or []
    return 'admin' in permissions

  displayName: ->
    @get('name') or 'Anoner'

  lang: ->
    @get('preferredLanguage') or 'en-US'

  getPhotoURL: (size=80, useJobProfilePhoto=false, useEmployerPageAvatar=false) ->
    photoURL = if useJobProfilePhoto then @get('jobProfile')?.photoURL else null
    photoURL ||= @get('photoURL')
    if photoURL
      prefix = if photoURL.search(/\?/) is -1 then '?' else '&'
      return "#{photoURL}#{prefix}s=#{size}" if photoURL.search('http') isnt -1  # legacy
      return "/file/#{photoURL}#{prefix}s=#{size}"
    return "/db/user/#{@id}/avatar?s=#{size}&employerPageAvatar=#{useEmployerPageAvatar}"

  @getByID = (id, properties, force) ->
    {me} = require 'lib/auth'
    return me if me.id is id
    user = cache[id] or new module.exports({_id: id})
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
  set: ->
    if arguments[0] is 'jobProfileApproved' and @get("jobProfileApproved") is false and not @get("jobProfileApprovedDate")
      @set "jobProfileApprovedDate", (new Date()).toISOString()
    super arguments...

  # callbacks can be either success or error
  @getByIDOrSlug: (idOrSlug, force, callbacks={}) ->
    {me} = require 'lib/auth'
    isID = util.isID idOrSlug
    if me.id is idOrSlug or me.slug is idOrSlug
      callbacks.success me if callbacks.success?
      return me
    cached = cache[idOrSlug]
    user = cached or new @ _id: idOrSlug
    if force or not cached
      user.loading = true
      user.fetch
        success: ->
          user.loading = false
          Backbone.Mediator.publish 'user:fetched'
          callbacks.success user if callbacks.success?
        error: ->
          user.loading = false
          callbacks.error user if callbacks.error?
    cache[idOrSlug] = user
    user

  @getUnconflictedName: (name, done) ->
    $.ajax "/auth/name/#{name}",
      success: (data) -> done data.name
      statusCode: 409: (data) ->
        response = JSON.parse data.responseText
        done response.name

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
    newSubs[newSubName] = {enabled: oldSubName in oldSubs} for oldSubName, newSubName of @emailMap
    @set('emails', newSubs)

  isEmailSubscriptionEnabled: (name) -> (@get('emails') or {})[name]?.enabled

  a = 5
  b = 40

  # y = a * ln(1/b * (x + b)) + 1
  @levelFromExp: (xp) ->
    if xp > 0 then Math.floor(a * Math.log((1/b) * (xp + b))) + 1 else 1

  # x = (e^((y-1)/a) - 1) * b
  @expForLevel: (level) ->
    Math.ceil((Math.exp((level - 1)/ a) - 1) * b)

  level: ->
    User.levelFromExp(@get('points'))

  levelFromExp: (xp) -> User.levelFromExp(xp)

  expForLevel: (level) -> User.expForLevel(level)
