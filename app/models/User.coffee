GRAVATAR_URL = 'https://www.gravatar.com/'
cache = {}
CocoModel = require './CocoModel'
util = require 'lib/utils'

module.exports = class User extends CocoModel
  @className: 'User'
  @schema: require 'schemas/models/user'
  urlRoot: '/db/user'
  notyErrors: false

  defaults:
    points: 0

  initialize: ->
    super()
    @migrateEmails()

  onLoaded:  ->
    CocoModel.pollAchievements() # Check for achievements on login
    super arguments...

  isAdmin: ->
    permissions = @attributes['permissions'] or []
    return 'admin' in permissions

  isAnonymous: ->
    @get 'anonymous'

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

  getSlugOrID: -> @get('slug') or @get('_id')

  set: ->
    if arguments[0] is 'jobProfileApproved' and @get("jobProfileApproved") is false and not @get("jobProfileApprovedDate")
      @set "jobProfileApprovedDate", (new Date()).toISOString()
    super arguments...

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
  b = 100
  c = b

  # y = a * ln(1/b * (x + c)) + 1
  @levelFromExp: (xp) ->
    if xp > 0 then Math.floor(a * Math.log((1/b) * (xp + c))) + 1 else 1

  # x = b * e^((y-1)/a) - c
  @expForLevel: (level) ->
    if level > 1 then Math.ceil Math.exp((level - 1)/ a) * b - c else 0

  level: ->
    User.levelFromExp(@get('points'))
