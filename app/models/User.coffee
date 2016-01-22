GRAVATAR_URL = 'https://www.gravatar.com/'
cache = {}
CocoModel = require './CocoModel'
util = require 'core/utils'
ThangType = require './ThangType'
Level = require './Level'

module.exports = class User extends CocoModel
  @className: 'User'
  @schema: require 'schemas/models/user'
  urlRoot: '/db/user'
  notyErrors: false

  isAdmin: -> 'admin' in @get('permissions', true)
  isArtisan: -> 'artisan' in @get('permissions', true)
  isInGodMode: -> 'godmode' in @get('permissions', true)
  isAnonymous: -> @get('anonymous', true)
  displayName: -> @get('name', true)
  broadName: ->
    name = @get('name')
    return name if name
    name = _.filter([@get('firstName'), @get('lastName')]).join(' ')
    return name if name
    email = @get('email')
    return email if email
    return 'Anoner'

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
      cache: false
      success: (data) -> done data.name
      statusCode: 409: (data) ->
        response = JSON.parse data.responseText
        done response.name

  getEnabledEmails: ->
    (emailName for emailName, emailDoc of @get('emails', true) when emailDoc.enabled)

  setEmailSubscription: (name, enabled) ->
    newSubs = _.clone(@get('emails')) or {}
    (newSubs[name] ?= {}).enabled = enabled
    @set 'emails', newSubs

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

  @tierFromLevel: (level) ->
    # TODO: math
    # For now, just eyeball it.
    tiersByLevel[Math.min(level, tiersByLevel.length - 1)]

  @levelForTier: (tier) ->
    # TODO: math
    for tierThreshold, level in tiersByLevel
      return level if tierThreshold >= tier

  level: ->
    totalPoint = @get('points')
    totalPoint = totalPoint + 1000000 if me.isInGodMode()
    User.levelFromExp(totalPoint)

  tier: ->
    User.tierFromLevel @level()

  gems: ->
    gemsEarned = @get('earned')?.gems ? 0
    gemsEarned = gemsEarned + 100000 if me.isInGodMode()
    gemsPurchased = @get('purchased')?.gems ? 0
    gemsSpent = @get('spent') ? 0
    Math.floor gemsEarned + gemsPurchased - gemsSpent

  heroes: ->
    heroes = (me.get('purchased')?.heroes ? []).concat([ThangType.heroes.captain, ThangType.heroes.knight])
    #heroes = _.values ThangType.heroes if me.isAdmin()
    heroes
  items: -> (me.get('earned')?.items ? []).concat(me.get('purchased')?.items ? []).concat([ThangType.items['simple-boots']])
  levels: -> (me.get('earned')?.levels ? []).concat(me.get('purchased')?.levels ? []).concat(Level.levels['dungeons-of-kithgard'])
  ownsHero: (heroOriginal) -> me.isInGodMode() || heroOriginal in @heroes()
  ownsItem: (itemOriginal) -> itemOriginal in @items()
  ownsLevel: (levelOriginal) -> levelOriginal in @levels()

  getHeroClasses: ->
    idsToSlugs = _.invert ThangType.heroes
    myHeroSlugs = (idsToSlugs[id] for id in @heroes())
    myHeroClasses = []
    myHeroClasses.push heroClass for heroClass, heroSlugs of ThangType.heroClasses when _.intersection(myHeroSlugs, heroSlugs).length
    myHeroClasses

  getAnnouncesActionAudioGroup: ->
    return @announcesActionAudioGroup if @announcesActionAudioGroup
    group = me.get('testGroupNumber') % 4
    @announcesActionAudioGroup = switch group
      when 0 then 'all-audio'
      when 1 then 'no-audio'
      when 2 then 'just-take-damage'
      when 3 then 'without-take-damage'
    @announcesActionAudioGroup = 'all-audio' if me.isAdmin()
    application.tracker.identify announcesActionAudioGroup: @announcesActionAudioGroup unless me.isAdmin()
    @announcesActionAudioGroup

  # Signs and Portents was receiving updates after test started, and also had a big bug on March 4, so just look at test from March 5 on.
  # ... and stopped working well until another update on March 10, so maybe March 11+...
  # ... and another round, and then basically it just isn't completing well, so we pause the test until we can fix it.
  getFourthLevelGroup: ->
    return 'forgetful-gemsmith'
    return @fourthLevelGroup if @fourthLevelGroup
    group = me.get('testGroupNumber') % 8
    @fourthLevelGroup = switch group
      when 0, 1, 2, 3 then 'signs-and-portents'
      when 4, 5, 6, 7 then 'forgetful-gemsmith'
    @fourthLevelGroup = 'signs-and-portents' if me.isAdmin()
    application.tracker.identify fourthLevelGroup: @fourthLevelGroup unless me.isAdmin()
    @fourthLevelGroup

  getVideoTutorialStylesIndex: (numVideos=0)->
    # A/B Testing video tutorial styles
    # Not a constant number of videos available (e.g. could be 0, 1, 3, or 4 currently)
    return 0 unless numVideos > 0
    return me.get('testGroupNumber') % numVideos

  hasSubscription: ->
    return false unless stripe = @get('stripe')
    return true if stripe.sponsorID
    return true if stripe.subscriptionID
    return true if stripe.free is true
    return true if _.isString(stripe.free) and new Date() < new Date(stripe.free)

  isPremium: ->
    return true if me.isInGodMode()
    return true if me.isAdmin()
    return true if me.hasSubscription()
    return false

  isOnPremiumServer: ->
    me.get('country') in ['china', 'brazil']

tiersByLevel = [-1, 0, 0.05, 0.14, 0.18, 0.32, 0.41, 0.5, 0.64, 0.82, 0.91, 1.04, 1.22, 1.35, 1.48, 1.65, 1.78, 1.96, 2.1, 2.24, 2.38, 2.55, 2.69, 2.86, 3.03, 3.16, 3.29, 3.42, 3.58, 3.74, 3.89, 4.04, 4.19, 4.32, 4.47, 4.64, 4.79, 4.96,
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15
]
