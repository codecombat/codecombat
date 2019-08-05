cache = {}
CocoModel = require './CocoModel'
ThangTypeConstants = require 'lib/ThangTypeConstants'
LevelConstants = require 'lib/LevelConstants'
utils = require 'core/utils'
api = require 'core/api'
co = require 'co'

# Pure functions for use in Vue
# First argument is always a raw User.attributes
# Accessible via eg. `User.broadName(userObj)`
UserLib = {
  broadName: (user) ->
    return '(deleted)' if user.deleted
    name = _.filter([user.firstName, user.lastName]).join(' ')
    return name if name
    name = user.name
    return name if name
    [emailName, emailDomain] = user.email?.split('@') or []
    return emailName if emailName
    return 'Anonymous'
  isSmokeTestUser: (user) -> utils.isSmokeTestEmail(user.email)
}

module.exports = class User extends CocoModel
  @className: 'User'
  @schema: require 'schemas/models/user'
  urlRoot: '/db/user'
  notyErrors: false
  PERMISSIONS: {
    COCO_ADMIN: 'admin',
    SCHOOL_ADMINISTRATOR: 'schoolAdministrator',
    ARTISAN: 'artisan',
    GOD_MODE: 'godmode',
    LICENSOR: 'licensor'
  }

  isAdmin: -> @PERMISSIONS.COCO_ADMIN in @get('permissions', true)
  isLicensor: -> @PERMISSIONS.LICENSOR in @get('permissions', true)
  isArtisan: -> @PERMISSIONS.ARTISAN in @get('permissions', true)
  isInGodMode: -> @PERMISSIONS.GOD_MODE in @get('permissions', true)
  isSchoolAdmin: -> @PERMISSIONS.SCHOOL_ADMINISTRATOR in @get('permissions', true)
  isAnonymous: -> @get('anonymous', true)
  isSmokeTestUser: -> User.isSmokeTestUser(@attributes)

  displayName: -> @get('name', true)
  broadName: -> User.broadName(@attributes)

  inEU: (defaultIfUnknown=true) -> unless @get('country') then defaultIfUnknown else utils.inEU(@get('country'))

  getPhotoURL: (size=80) ->
    return '' if application.testing
    return "/db/user/#{@id}/avatar?s=#{size}"

  getRequestVerificationEmailURL: ->
    @url() + "/request-verify-email"

  getSlugOrID: -> @get('slug') or @get('_id')

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

  isCreatedByClient: -> @get('clientCreator')?

  isTeacher: (includePossibleTeachers=false) ->
    return true if includePossibleTeachers and @get('role') is 'possible teacher'  # They maybe haven't created an account but we think they might be a teacher based on behavior
    return @get('role') in ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent']

  isPaidTeacher: ->
    return false unless @isTeacher()
    return @isCreatedByClient() or (/@codeninjas.com$/i.test me.get('email'))

  isTeacherOf: co.wrap ({ classroom, classroomId, courseInstance, courseInstanceId }) ->
    if not me.isTeacher()
      return false

    if classroomId and not classroom
      Classroom = require 'models/Classroom'
      classroom = new Classroom({ _id: classroomId })
      yield classroom.fetch()

    if classroom
      return true if @get('_id') == classroom.get('ownerID')

    if courseInstanceId and not courseInstance
      CourseInstance = require 'models/CourseInstance'
      courseInstance = new CourseInstance({ _id: courseInstanceId })
      yield courseInstance.fetch()

    if courseInstance
      return true if @get('id') == courseInstance.get('ownerID')

    return false

  isSchoolAdminOf: co.wrap ({ classroom, classroomId, courseInstance, courseInstanceId }) ->
    if not me.isSchoolAdmin()
      return false

    if classroomId and not classroom
      Classroom = require 'models/Classroom'
      classroom = new Classroom({ _id: classroomId })
      yield classroom.fetch()

    if classroom
      return true if classroom.get('ownerID') in @get('administratedTeachers')

    if courseInstanceId and not courseInstance
      CourseInstance = require 'models/CourseInstance'
      courseInstance = new CourseInstance({ _id: courseInstanceId })
      yield courseInstance.fetch()

    if courseInstance
      return true if courseInstance.get('ownerID') in @get('administratedTeachers')

    return false

  isSessionless: ->
    Boolean((utils.getQueryVariable('dev', false) or me.isTeacher()) and utils.getQueryVariable('course', false) and not utils.getQueryVariable('course-instance'))

  getClientCreatorPermissions: ->
    clientID = @get('clientCreator')
    if !clientID
      clientID = utils.getApiClientIdFromEmail(@get('email'))
    if clientID
      api.apiClients.getByHandle(clientID)
      .then((apiClient) =>
        @clientPermissions = apiClient.permissions
      )
      .catch((e) =>
        console.error(e)
      )

  canManageLicensesViaUI: -> @clientPermissions?.manageLicensesViaUI ? true

  canRevokeLicensesViaUI: ->
    if !@clientPermissions or (@clientPermissions.manageLicensesViaUI and @clientPermissions.revokeLicensesViaUI)
      return true
    return false

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
    gemsEarned += 1000 if me.get('hourOfCode')
    gemsPurchased = @get('purchased')?.gems ? 0
    gemsSpent = @get('spent') ? 0
    Math.floor gemsEarned + gemsPurchased - gemsSpent

  heroes: ->
    heroes = (me.get('purchased')?.heroes ? []).concat([ThangTypeConstants.heroes.captain, ThangTypeConstants.heroes.knight, ThangTypeConstants.heroes.champion, ThangTypeConstants.heroes.duelist])
    heroes.push ThangTypeConstants.heroes['code-ninja'] if window.serverConfig.codeNinjas
    #heroes = _.values ThangTypeConstants.heroes if me.isAdmin()
    heroes
  items: -> (me.get('earned')?.items ? []).concat(me.get('purchased')?.items ? []).concat([ThangTypeConstants.items['simple-boots']])
  levels: -> (me.get('earned')?.levels ? []).concat(me.get('purchased')?.levels ? []).concat(LevelConstants.levels['dungeons-of-kithgard'])
  ownsHero: (heroOriginal) -> me.isInGodMode() || heroOriginal in @heroes()
  ownsItem: (itemOriginal) -> itemOriginal in @items()
  ownsLevel: (levelOriginal) -> levelOriginal in @levels()

  getHeroClasses: ->
    idsToSlugs = _.invert ThangTypeConstants.heroes
    myHeroSlugs = (idsToSlugs[id] for id in @heroes())
    myHeroClasses = []
    myHeroClasses.push heroClass for heroClass, heroSlugs of ThangTypeConstants.heroClasses when _.intersection(myHeroSlugs, heroSlugs).length
    myHeroClasses

  validate: ->
    errors = super()
    if errors and @_revertAttributes

      # Do not return errors if they were all present when last marked to revert.
      # This is so that if a user has an invalid property, that does not prevent
      # them from editing their settings.
      definedAttributes = _.pick @_revertAttributes, (v) -> v isnt undefined
      oldResult = tv4.validateMultiple(definedAttributes, @constructor.schema or {})
      mapper = (error) -> [error.code.toString(),error.dataPath,error.schemaPath].join(':')
      originalErrors = _.map(oldResult.errors, mapper)
      currentErrors = _.map(errors, mapper)
      newErrors = _.difference(currentErrors, originalErrors)
      if _.size(newErrors) is 0
        return
    return errors

  # TODO move to app/core/experiments when updated
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

  # TODO: full removal of sub modal test
  # TODO move to app/core/experiments when updated
  getSubModalGroup: () ->
    return @subModalGroup if @subModalGroup
    @subModalGroup = 'both-subs'
    @subModalGroup
  setSubModalGroup: (val) ->
    @subModalGroup = if me.isAdmin() then 'both-subs' else val
    @subModalGroup

  # Signs and Portents was receiving updates after test started, and also had a big bug on March 4, so just look at test from March 5 on.
  # ... and stopped working well until another update on March 10, so maybe March 11+...
  # ... and another round, and then basically it just isn't completing well, so we pause the test until we can fix it.
  # TODO move to app/core/experiments when updated
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

  # TODO move to app/core/experiments when updated
  getHomePageTestGroup: () ->
    return  # ending A/B test on homepage for now.
    return unless me.get('country') == 'united-states'
    # testGroupNumberUS is a random number from 0-255, use it to run A/B tests for US users.

  hasSubscription: ->
    return false if me.isStudent() or me.isTeacher()
    if payPal = @get('payPal')
      return true if payPal.billingAgreementID
    if stripe = @get('stripe')
      return true if stripe.sponsorID
      return true if stripe.subscriptionID
      return true if stripe.free is true
      return true if _.isString(stripe.free) and new Date() < new Date(stripe.free)
    false

  isPremium: ->
    return true if me.isInGodMode()
    return true if me.isAdmin()
    return true if me.hasSubscription()
    return false

  isForeverPremium: ->
    return @get('stripe')?.free is true

  isOnPremiumServer: ->
    return true if me.get('country') in ['brazil']
    return true if me.get('country') in ['china'] and (me.isPremium() or me.get('stripe'))
    return true if features?.china
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

  sendKeepMeUpdatedVerificationCode: (code) ->
    $.ajax({
      method: 'POST'
      url: "/db/user/#{@id}/keep-me-updated/#{code}"
      success: (attributes) =>
        this.set attributes
        @trigger 'user-keep-me-updated-success'
      error: =>
        @trigger 'user-keep-me-updated-error'
    })

  sendNoDeleteEUVerificationCode: (code) ->
    $.ajax({
      method: 'POST'
      url: "/db/user/#{@id}/no-delete-eu/#{code}"
      success: (attributes) =>
        this.set attributes
        @trigger 'user-no-delete-eu-success'
      error: =>
        @trigger 'user-no-delete-eu-error'
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

  fetchCreatorOfPrepaid: (prepaid) ->
    @fetch({url: "/db/prepaid/#{prepaid.id}/creator"})

  fetchNameForClassmate: (options={}) ->
    options.method = 'GET'
    options.contentType = 'application/json'
    options.url = "/db/user/#{@id}/name-for-classmate"
    $.ajax options

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
      location = _.result(window.currentView, 'logoutRedirectURL')
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

  isFromUk: -> @get('country') is 'united-kingdom' or @get('preferredLanguage') is 'en-GB'
  isFromIndia: -> @get('country') is 'india'
  setToGerman: -> _.string.startsWith((@get('preferredLanguage') or ''), 'de')
  setToSpanish: -> _.string.startsWith((@get('preferredLanguage') or ''), 'es')

  freeOnly: ->
    return features.freeOnly and not me.isPremium()

  subscribe: (token, options={}) ->
    stripe = _.clone(@get('stripe') ? {})
    stripe.planID = 'basic'
    stripe.token = token.id
    stripe.couponID = options.couponID if options.couponID
    @set({stripe})
    return me.patch({headers: {'X-Change-Plan': 'true'}}).then =>
      unless utils.isValidEmail(@get('email'))
        @set({email: token.email})
        me.patch()
      return Promise.resolve()

  unsubscribe: ->
    stripe = _.clone(@get('stripe') ? {})
    return unless stripe.planID
    delete stripe.planID
    @set({stripe})
    return me.patch({headers: {'X-Change-Plan': 'true'}})

  unsubscribeRecipient: (id, options={}) ->
    options.url = _.result(@, 'url') + "/stripe/recipients/#{id}"
    options.method = 'DELETE'
    return $.ajax(options)

  # Feature Flags
  # Abstract raw settings away from specific UX changes
  allowStudentHeroPurchase: -> features?.classroomItems ? false and @isStudent()
  canBuyGems: -> not (features?.chinaUx ? false)
  constrainHeroHealth: -> features?.classroomItems ? false and @isStudent()
  promptForClassroomSignup: -> not (features?.chinaUx ? false or window.serverConfig?.codeNinjas ? false or features?.brainPop ? false)
  showAvatarOnStudentDashboard: -> not (features?.classroomItems ? false) and @isStudent()
  showGearRestrictionsInClassroom: -> features?.classroomItems ? false and @isStudent()
  showGemsAndXp: -> features?.classroomItems ? false and @isStudent()
  showHeroAndInventoryModalsToStudents: -> features?.classroomItems and @isStudent()
  skipHeroSelectOnStudentSignUp: -> features?.classroomItems ? false
  useDexecure: -> not (features?.chinaInfra ? false)
  useSocialSignOn: -> not ((features?.chinaUx ? false) or (features?.china ? false))
  isTarena: -> features?.Tarena ? false
  useTarenaLogo: -> @isTarena()
  hideTopRightNav: -> @isTarena()
  hideFooter: -> @isTarena()
  useGoogleClassroom: -> not (features?.chinaUx ? false) and me.get('gplusID')?   # if signed in using google SSO
  useGoogleAnalytics: -> not ((features?.china ? false) or (features?.chinaInfra ? false))
  # features.china is set globally for our China server
  showChinaVideo: -> (features?.china ? false) or (features?.chinaInfra ? false)
  canAccessCampaignFreelyFromChina: (campaignID) -> campaignID == "55b29efd1cd6abe8ce07db0d" # teacher can only access CS1 freely in China
  isCreatedByTarena: -> @get('clientCreator') == "5c80a2a0d78b69002448f545"   #ClientID of Tarena2 on koudashijie.com
  showForumLink: -> not (features?.china ? false)
  showGithubLink: -> not (features?.china ? false)
  showChinaICPinfo: -> features?.china ? false
  showChinaResourceInfo: -> features?.china ? false
  # Special flag to detect whether we're temporarily showing static html while loading full site
  showingStaticPagesWhileLoading: -> false
  showIndividualRegister: -> not (features?.china ? false)
  hideDiplomatModal: -> features?.china ? false
  showChinaRemindToast: -> features?.china ? false

  # Ozaria flags
  showOzariaCampaign: -> @isAdmin()
  hasCinematicAccess: -> @isAdmin()
  hasCharCustomizationAccess: -> @isAdmin()
  hasAvatarSelectorAccess: -> @isAdmin()
  hasCutsceneAccess: -> @isAdmin()
  hasInteractiveAccess: -> @isAdmin()
  hasIntroLevelAccess: -> @isAdmin()


tiersByLevel = [-1, 0, 0.05, 0.14, 0.18, 0.32, 0.41, 0.5, 0.64, 0.82, 0.91, 1.04, 1.22, 1.35, 1.48, 1.65, 1.78, 1.96, 2.1, 2.24, 2.38, 2.55, 2.69, 2.86, 3.03, 3.16, 3.29, 3.42, 3.58, 3.74, 3.89, 4.04, 4.19, 4.32, 4.47, 4.64, 4.79, 4.96,
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15
]

# Make UserLib accessible via eg. User.broadName(userObj)
_.assign(User, UserLib)

