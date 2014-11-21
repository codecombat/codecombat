GRAVATAR_URL = 'https://www.gravatar.com/'
cache = {}
CocoModel = require './CocoModel'
util = require 'lib/utils'
ThangType = require './ThangType'

module.exports = class User extends CocoModel
  @className: 'User'
  @schema: require 'schemas/models/user'
  urlRoot: '/db/user'
  notyErrors: false

  onLoaded:  ->
    CocoModel.pollAchievements() # Check for achievements on login
    super arguments...

  isAdmin: -> 'admin' in @get('permissions', true)
  isAnonymous: -> @get('anonymous', true)
  displayName: -> @get('name', true)

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
    User.levelFromExp(@get('points'))

  tier: ->
    User.tierFromLevel @level()

  gems: ->
    gemsEarned = @get('earned')?.gems ? 0
    gemsPurchased = @get('purchased')?.gems ? 0
    gemsSpent = @get('spent') ? 0
    gemsEarned + gemsPurchased - gemsSpent

  heroes: ->
    heroes = (me.get('earned')?.heroes ? []).concat(me.get('purchased')?.heroes ? []).concat([ThangType.heroes.captain, ThangType.heroes.knight])
    heroes = _.values ThangType.heroes if me.isAdmin()
    heroes
  items: -> (me.get('earned')?.items ? []).concat(me.get('purchased')?.items ? []).concat([ThangType.items['simple-boots']])
  levels: -> (me.get('earned')?.levels ? []).concat(me.get('purchased')?.levels ? [])
  ownsHero: (heroOriginal) -> heroOriginal in @heroes()
  ownsItem: (itemOriginal) -> itemOriginal in @items()
  ownsLevel: (levelOriginal) -> levelOriginal in @levels()

  getBranchingGroup: ->
    return @branchingGroup if @branchingGroup
    group = me.get('testGroupNumber') % 4
    @branchingGroup = switch group
      when 0 then 'no-practice'
      when 1 then 'all-practice'
      when 2 then 'choice-explicit'
      when 3 then 'choice-implicit'
    @branchingGroup = 'choice-explicit' if me.isAdmin()
    @branchingGroup = 'no-practice'  # paused A/B test
    #application.tracker.identify branchingGroup: @branchingGroup unless me.isAdmin()  # paused A/B test
    @branchingGroup

  getCastButtonTextGroup: ->
    # Group 0 is original behavior
    unless @castButtonTextGroup?
      if me.isAdmin()
        @castButtonTextGroup = 0
      else
        @castButtonTextGroup = me.get('testGroupNumber') % 7
        application.tracker.identify castButtonTextGroup: @castButtonTextGroup
    @castButtonTextGroup

tiersByLevel = [-1, 0, 0.05, 0.14, 0.18, 0.32, 0.41, 0.5, 0.64, 0.82, 0.91, 1.04, 1.22, 1.35, 1.48, 1.65, 1.78, 1.96, 2.1, 2.24, 2.38, 2.55, 2.69, 2.86, 3.03, 3.16, 3.29, 3.42, 3.58, 3.74, 3.89, 4.04, 4.19, 4.32, 4.47, 4.64, 4.79, 4.96]
