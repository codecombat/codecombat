GRAVATAR_URL = 'https://www.gravatar.com/'
cache = {}
CocoModel = require './CocoModel'
ThangType = require './ThangType'
Level = require './Level'
utils = require 'core/utils'

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
    return '(deleted)' if @get('deleted')
    name = _.filter([@get('firstName'), @get('lastName')]).join(' ')
    return name if name
    name = @get('name')
    return name if name
    [emailName, emailDomain] = @get('email')?.split('@') or []
    return emailName if emailName
    return 'Anonymous'

  getPhotoURL: (size=80, useJobProfilePhoto=false, useEmployerPageAvatar=false) ->
    photoURL = if useJobProfilePhoto then @get('jobProfile')?.photoURL else null
    photoURL ||= @get('photoURL')
    if photoURL
      prefix = if photoURL.search(/\?/) is -1 then '?' else '&'
      return "#{photoURL}#{prefix}s=#{size}" if photoURL.search('http') isnt -1  # legacy
      return "/file/#{photoURL}#{prefix}s=#{size}"
    return "/db/user/#{@id}/avatar?s=#{size}&employerPageAvatar=#{useEmployerPageAvatar}"

  getRequestVerificationEmailURL: ->
    @url() + "/request-verify-email"

  getSlugOrID: -> @get('slug') or @get('_id')

  set: ->
    if arguments[0] is 'jobProfileApproved' and @get("jobProfileApproved") is false and not @get("jobProfileApprovedDate")
      @set "jobProfileApprovedDate", (new Date()).toISOString()
    super arguments...

  @getUnconflictedName: (name, done) ->
    # deprecate in favor of @checkNameConflicts, which uses Promises and returns the whole response
    $.ajax "/auth/name/#{encodeURIComponent(name)}",
      cache: false
      success: (data) -> done(data.suggestedName)

  @checkNameConflicts: (name) ->
    new Promise (resolve, reject) ->
      $.ajax "/auth/name/#{encodeURIComponent(name)}",
        cache: false
        success: resolve
        error: (jqxhr) -> reject(jqxhr.responseJSON)

  @checkEmailExists: (email) ->
    new Promise (resolve, reject) ->
      $.ajax "/auth/email/#{encodeURIComponent(email)}",
        cache: false
        success: resolve
        error: (jqxhr) -> reject(jqxhr.responseJSON)

  getEnabledEmails: ->
    (emailName for emailName, emailDoc of @get('emails', true) when emailDoc.enabled)

  setEmailSubscription: (name, enabled) ->
    newSubs = _.clone(@get('emails')) or {}
    (newSubs[name] ?= {}).enabled = enabled
    @set 'emails', newSubs

  isEmailSubscriptionEnabled: (name) -> (@get('emails') or {})[name]?.enabled

  isStudent: -> @get('role') is 'student'

  isTeacher: ->
    return @get('role') in ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent']

  isSessionless: ->
    # TODO: Fix old users who got mis-tagged as teachers
    # TODO: Should this just be isTeacher, eventually?
    Boolean((utils.getQueryVariable('dev', false) or me.isTeacher()) and utils.getQueryVariable('course', false))

  setRole: (role, force=false) ->
    oldRole = @get 'role'
    return if oldRole is role or (oldRole and not force)
    @set 'role', role
    @patch()
    application.tracker?.updateRole()
    return @get 'role'

  a = 5
  b = 100
  c = b

  # y = a * ln(1/b * (x + c)) + 1
  @levelFromExp: (xp) ->
    if xp > 0 then Math.floor(a * Math.log((1 / b) * (xp + c))) + 1 else 1

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
    heroes = (me.get('purchased')?.heroes ? []).concat([ThangType.heroes.captain, ThangType.heroes.knight, ThangType.heroes.champion, ThangType.heroes.duelist])
    heroes.push ThangType.heroes['code-ninja'] if window.serverConfig.codeNinjas
    #heroes = _.values ThangType.heroes if me.isAdmin()
    heroes
  items: -> (me.get('earned')?.items ? []).concat(me.get('purchased')?.items ? []).concat([ThangType.items['simple-boots']])
  levels: -> (me.get('earned')?.levels ? []).concat(me.get('purchased')?.levels ? []).concat(Level.levels['dungeons-of-kithgard'])
  ownsHero: (heroOriginal) -> me.isInGodMode() || heroOriginal in @heroes()
  #ownsItem: (itemOriginal) -> itemOriginal in @items()  # See redefinition while getDungeonLevelsGroup test is active
  #ownsLevel: (levelOriginal) -> levelOriginal in @levels()  # See redefinition while getDungeonLevelsGroup test is active

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

  getCampaignAdsGroup: ->
    return @campaignAdsGroup if @campaignAdsGroup
    # group = me.get('testGroupNumber') % 2
    # @campaignAdsGroup = switch group
    #   when 0 then 'no-ads'
    #   when 1 then 'leaderboard-ads'
    @campaignAdsGroup = 'leaderboard-ads'
    @campaignAdsGroup = 'no-ads' if me.isAdmin()
    application.tracker.identify campaignAdsGroup: @campaignAdsGroup unless me.isAdmin()
    @campaignAdsGroup

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

  getDefaultLanguageGroup: ->
    # A/B test default programming language in home version
    return @defaultLanguageGroup if @defaultLanguageGroup
    group = me.get('testGroupNumber') % 2
    @defaultLanguageGroup = switch group
      when 0 then 'javascript'
      when 1 then 'python'
    application.tracker.identify defaultLanguageGroup: @defaultLanguageGroup unless me.isAdmin()
    @defaultLanguageGroup

  getVideoTutorialStylesIndex: (numVideos=0)->
    # A/B Testing video tutorial styles
    # Not a constant number of videos available (e.g. could be 0, 1, 3, or 4 currently)
    return 0 unless numVideos > 0
    return me.get('testGroupNumber') % numVideos

  getDungeonLevelsGroup: ->
    # Fully dismantle this after Hour of Code week is done
    return @dungeonLevelsGroup if @dungeonLevelsGroup
    @dungeonLevelsGroup = 'none'
    @dungeonLevelsHidden = ['cell-commentary', 'kithgard-librarian', 'loop-da-loop', 'haunted-kithmaze', 'dread-door', 'closing-the-distance']
    skipTest = me.isAdmin() or me.isPremium() or features.freeOnly or me.isOnPremiumServer()
    if skipTest
      [@dungeonLevelsGroup, @dungeonLevelsHidden] = ['control', []]
    @dungeonLevelsGroup

  getDungeonLevelsHidden: ->
    @getDungeonLevelsGroup()
    @dungeonLevelsHidden

  dungeonLevelSlugsToOriginals:
    'cell-commentary': '57aa1bd5e5636725008854c0'
    'kithgard-librarian': '5604169b60537b8705386a59'
    'loop-da-loop': '565ce2291b940587057366dd'
    'haunted-kithmaze': '545a5914d820eb0000f6dc0a'
    'dread-door': '5418d40f4c16460000ab9ac2'
    'closing-the-distance': '541b288e1ccc8eaae19f3c25'
    'fire-dancing': '55ca293b9bc1892c835b0136'
    'the-second-kithmaze': '5418cf256bae62f707c7e1c3'
    'descending-further': '5452a84d57e83800009730e4'
    'known-enemy': '5452adea57e83800009730ee'
    'cupboards-of-kithgard': '54e0cdefe308cb510555a7f5'
    'a-mayhem-of-munchkins': '55ca29439bc1892c835b0137'
    'tactical-strike': '5452cfa706a59e000067e4f5'

  dungeonItemSlugsToOriginals:
    'programmaticon-i': '53e4108204c00d4607a89f78'
    'wooden-shield': '53e22aa153457600003e3ef5'

  dungeonLevelUnlocksToRewrite: [
    {levels: ['kithgard-librarian'], unlockedInsteadOf: 'cell-commentary', groups: ['kithgard-librarian']}
    {levels: ['fire-dancing'], item: 'programmaticon-i', unlockedInsteadOf: 'cell-commentary', groups: ['loop-da-loop', 'haunted-kithmaze', 'none']}
    {levels: ['fire-dancing'], item: 'programmaticon-i', unlockedInsteadOf: 'kithgard-librarian', groups: ['cell-commentary']}
    {levels: ['haunted-kithmaze'], unlockedInsteadOf: 'loop-da-loop', groups: ['haunted-kithmaze']}
    {levels: ['the-second-kithmaze', 'descending-further'], unlockedInsteadOf: 'haunted-kithmaze', groups: ['conservative', 'loop-da-loop']}
    {levels: ['the-second-kithmaze', 'descending-further'], unlockedInsteadOf: 'loop-da-loop', groups: ['cell-commentary', 'kithgard-librarian', 'none']}
    {levels: ['known-enemy', 'cupboards-of-kithgard'], unlockedInsteadOf: 'dread-door', groups: ['conservative', 'cell-commentary', 'kithgard-librarian', 'loop-da-loop', 'haunted-kithmaze', 'none']}
    {levels: ['a-mayhem-of-munchkins', 'tactical-strike'], item: 'wooden-shield', unlockedInsteadOf: 'closing-the-distance', groups: ['conservative', 'cell-commentary', 'kithgard-librarian', 'loop-da-loop', 'haunted-kithmaze', 'none']}
  ]

  ownsLevel: (levelOriginal) ->
    # Temporary hack; revert to simpler ownsLevel above when test is concluded
    return true if levelOriginal in @levels()
    @dungeonLevelOriginalsToSlugs ?= _.invert @dungeonLevelSlugsToOriginals
    levelSlug = @dungeonLevelOriginalsToSlugs[levelOriginal]
    return false unless levelSlug
    for levelUnlockRewrite in @dungeonLevelUnlocksToRewrite when @getDungeonLevelsGroup() in levelUnlockRewrite.groups
      if levelSlug in levelUnlockRewrite.levels
        return @ownsLevel @dungeonLevelSlugsToOriginals[levelUnlockRewrite.unlockedInsteadOf]
    false

  ownsItem: (itemOriginal) ->
    # Temporary hack; revert to simpler ownsItem above when test is concluded
    return true if itemOriginal in @items()
    @dungeonItemOriginalsToSlugs ?= _.invert @dungeonItemSlugsToOriginals
    itemSlug = @dungeonItemOriginalsToSlugs[itemOriginal]
    return false unless itemSlug
    for levelUnlockRewrite in @dungeonLevelUnlocksToRewrite when @getDungeonLevelsGroup() in levelUnlockRewrite.groups
      if itemSlug is levelUnlockRewrite.item
        return @ownsLevel @dungeonLevelSlugsToOriginals[levelUnlockRewrite.unlockedInsteadOf]
    false

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
    return true if me.get('country') in ['brazil']
    return true if me.get('country') in ['china'] and (me.isPremium() or me.get('stripe'))
    return false

  sendVerificationCode: (code) ->
    $.ajax({
      method: 'POST'
      url: "/db/user/#{@id}/verify/#{code}"
      success: (attributes) =>
        this.set attributes
        @trigger 'email-verify-success'
      error: =>
        @trigger 'email-verify-error'
    })

  isEnrolled: -> @prepaidStatus() is 'enrolled'

  prepaidStatus: -> # 'not-enrolled', 'enrolled', 'expired'
    coursePrepaid = @get('coursePrepaid')
    return 'not-enrolled' unless coursePrepaid
    return 'enrolled' unless coursePrepaid.endDate
    return if coursePrepaid.endDate > new Date().toISOString() then 'enrolled' else 'expired'

  prepaidType: ->
    # TODO: remove once legacy prepaidIDs are migrated to objects
    return undefined unless @get('coursePrepaid') or @get('coursePrepaidID')
    # NOTE: Default type is 'course' if no type is marked on the user's copy
    return @get('coursePrepaid')?.type or 'course'

  prepaidIncludesCourse: (course) ->
    return false unless @get('coursePrepaid') or @get('coursePrepaidID')
    includedCourseIDs = @get('coursePrepaid')?.includedCourseIDs
    courseID = course.id or course
    # NOTE: Full licenses implicitly include all courses
    return !includedCourseIDs or courseID in includedCourseIDs

  # Function meant for "me"

  spy: (user, options={}) ->
    user = user.id or user # User instance, user ID, email or username
    options.url = '/auth/spy'
    options.type = 'POST'
    options.data ?= {}
    options.data.user = user
    @fetch(options)

  stopSpying: (options={}) ->
    options.url = '/auth/stop-spying'
    options.type = 'POST'
    @fetch(options)

  logout: (options={}) ->
    options.type = 'POST'
    options.url = '/auth/logout'
    FB?.logout?()
    options.success ?= ->
      location = _.result(currentView, 'logoutRedirectURL')
      if location
        window.location = location
      else
        window.location.reload()
    @fetch(options)

  signupWithPassword: (name, email, password, options={}) ->
    options.url = _.result(@, 'url') + '/signup-with-password'
    options.type = 'POST'
    options.data ?= {}
    _.extend(options.data, {name, email, password})
    options.contentType = 'application/json'
    options.data = JSON.stringify(options.data)
    jqxhr = @fetch(options)
    jqxhr.then ->
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'CodeCombat'
    return jqxhr

  signupWithFacebook: (name, email, facebookID, options={}) ->
    options.url = _.result(@, 'url') + '/signup-with-facebook'
    options.type = 'POST'
    options.data ?= {}
    _.extend(options.data, {name, email, facebookID, facebookAccessToken: application.facebookHandler.token()})
    options.contentType = 'application/json'
    options.data = JSON.stringify(options.data)
    jqxhr = @fetch(options)
    jqxhr.then ->
      window.tracker?.trackEvent 'Facebook Login', category: "Signup", label: 'Facebook'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'Facebook'
    return jqxhr

  signupWithGPlus: (name, email, gplusID, options={}) ->
    options.url = _.result(@, 'url') + '/signup-with-gplus'
    options.type = 'POST'
    options.data ?= {}
    _.extend(options.data, {name, email, gplusID, gplusAccessToken: application.gplusHandler.token()})
    options.contentType = 'application/json'
    options.data = JSON.stringify(options.data)
    jqxhr = @fetch(options)
    jqxhr.then ->
      window.tracker?.trackEvent 'Google Login', category: "Signup", label: 'GPlus'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'GPlus'
    return jqxhr

  fetchGPlusUser: (gplusID, options={}) ->
    options.data ?= {}
    options.data.gplusID = gplusID
    options.data.gplusAccessToken = application.gplusHandler.token()
    @fetch(options)

  loginGPlusUser: (gplusID, options={}) ->
    options.url = '/auth/login-gplus'
    options.type = 'POST'
    options.data ?= {}
    options.data.gplusID = gplusID
    options.data.gplusAccessToken = application.gplusHandler.token()
    @fetch(options)

  fetchFacebookUser: (facebookID, options={}) ->
    options.data ?= {}
    options.data.facebookID = facebookID
    options.data.facebookAccessToken = application.facebookHandler.token()
    @fetch(options)

  loginFacebookUser: (facebookID, options={}) ->
    options.url = '/auth/login-facebook'
    options.type = 'POST'
    options.data ?= {}
    options.data.facebookID = facebookID
    options.data.facebookAccessToken = application.facebookHandler.token()
    @fetch(options)

  loginPasswordUser: (usernameOrEmail, password, options={}) ->
    options.url = '/auth/login'
    options.type = 'POST'
    options.data ?= {}
    _.extend(options.data, { username: usernameOrEmail, password })
    @fetch(options)

  makeCoursePrepaid: ->
    coursePrepaid = @get('coursePrepaid')
    return null unless coursePrepaid
    Prepaid = require 'models/Prepaid'
    return new Prepaid(coursePrepaid)

  # TODO: Probably better to denormalize this into the user
  getLeadPriority: ->
    request = $.get('/db/user/-/lead-priority')
    request.then ({ priority }) ->
      application.tracker.identify({ priority })
    request

  becomeStudent: (options={}) ->
    options.url = '/db/user/-/become-student'
    options.type = 'PUT'
    @fetch(options)

  remainTeacher: (options={}) ->
    options.url = '/db/user/-/remain-teacher'
    options.type = 'PUT'
    @fetch(options)

  destudent: (options={}) ->
    options.url = _.result(@, 'url') + '/destudent'
    options.type = 'POST'
    @fetch(options)

  deteacher: (options={}) ->
    options.url = _.result(@, 'url') + '/deteacher'
    options.type = 'POST'
    @fetch(options)

  checkForNewAchievement: (options={}) ->
    options.url = _.result(@, 'url') + '/check-for-new-achievement'
    options.type = 'POST'
    jqxhr = @fetch(options)

    # Setting @loading to false because otherwise, if the user tries to edit their settings while checking
    # for new achievements, the changes won't be saved. This is because AccountSettingsView relies on
    # hasLocalChanges, and that is only true if, when set is called, the model isn't "loading".
    @loading = false

    return jqxhr
    
  finishedAnyLevels: -> Boolean((@get('stats') or {}).gamesCompleted)

  isFromUk: -> @get('country') is 'united-kingdom'

tiersByLevel = [-1, 0, 0.05, 0.14, 0.18, 0.32, 0.41, 0.5, 0.64, 0.82, 0.91, 1.04, 1.22, 1.35, 1.48, 1.65, 1.78, 1.96, 2.1, 2.24, 2.38, 2.55, 2.69, 2.86, 3.03, 3.16, 3.29, 3.42, 3.58, 3.74, 3.89, 4.04, 4.19, 4.32, 4.47, 4.64, 4.79, 4.96,
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15
]
