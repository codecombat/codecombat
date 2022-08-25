cache = {}
CocoModel = require './CocoModel'
ThangTypeConstants = require 'lib/ThangTypeConstants'
LevelConstants = require 'lib/LevelConstants'
utils = require 'core/utils'
api = require 'core/api'
co = require 'co'
storage = require 'core/storage'
globalVar = require 'core/globalVar'
fetchJson = require 'core/api/fetch-json'
userUtils = require 'lib/user-utils'

# Pure functions for use in Vue
# First argument is always a raw User.attributes
# Accessible via eg. `User.broadName(userObj)`
UserLib = {
  broadName: (user) ->
    return '(deleted)' if user.deleted
    name = _.filter([user.firstName, user.lastName]).join(' ')
    if features?.china
      name = user.firstName
    unless /[a-z]/.test name
      name = _.string.titleize name  # Rewrite all-uppercase names to title-case for display
    return name if name
    name = user.name
    return name if name
    [emailName, emailDomain] = user.email?.split('@') or []
    return emailName if emailName
    return 'Anonymous'
  isSmokeTestUser: (user) -> utils.isSmokeTestEmail(user.email)
  isTeacher: (user, includePossibleTeachers=false) ->
    return true if includePossibleTeachers and user.role is 'possible teacher'  # They maybe haven't created an account but we think they might be a teacher based on behavior
    return user.role in ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent']
}

module.exports = class User extends CocoModel
  @className: 'User'
  @schema: require 'schemas/models/user'
  urlRoot: '/db/user'
  notyErrors: false
  @PERMISSIONS: {
    COCO_ADMIN: 'admin',
    SCHOOL_ADMINISTRATOR: 'schoolAdministrator',
    ARTISAN: 'artisan',
    GOD_MODE: 'godmode',
    LICENSOR: 'licensor',
    API_CLIENT: 'apiclient',
    ONLINE_TEACHER: 'onlineTeacher'
  }

  get: (attr, withDefault=false) ->
    prop = super(attr, withDefault)
    if attr == 'products'
      return prop ? []
    prop

  isAdmin: -> @constructor.PERMISSIONS.COCO_ADMIN in @get('permissions', true)
  isLicensor: -> @constructor.PERMISSIONS.LICENSOR in @get('permissions', true)
  isArtisan: -> @constructor.PERMISSIONS.ARTISAN in @get('permissions', true)
  isOnlineTeacher: -> @constructor.PERMISSIONS.ONLINE_TEACHER in @get('permissions', true)
  isInGodMode: -> @constructor.PERMISSIONS.GOD_MODE in @get('permissions', true) or @constructor.PERMISSIONS.ONLINE_TEACHER in @get('permissions', true)
  isSchoolAdmin: -> @constructor.PERMISSIONS.SCHOOL_ADMINISTRATOR in @get('permissions', true)
  isAPIClient: -> @constructor.PERMISSIONS.API_CLIENT in @get('permissions', true)
  isAnonymous: -> @get('anonymous', true)
  isSmokeTestUser: -> User.isSmokeTestUser(@attributes)
  isIndividualUser: -> not @isStudent() and not User.isTeacher(@attributes)

  isInternal: ->
    email = @get('email')
    return false unless email
    return email.endsWith('@codecombat.com') or email.endsWith('@ozaria.com')

  displayName: -> @get('name', true)
  broadName: -> User.broadName(@attributes)

  inEU: (defaultIfUnknown=true) -> unless @get('country') then defaultIfUnknown else utils.inEU(@get('country'))
  addressesIncludeAdministrativeRegion: (defaultIfUnknown=true) -> unless @get('country') then defaultIfUnknown else utils.addressesIncludeAdministrativeRegion(@get('country'))

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

  isHomeUser: -> not @get('role')

  isStudent: -> @get('role') is 'student'

  isCreatedByClient: -> @get('clientCreator')?

  isTeacher: (includePossibleTeachers=false) -> User.isTeacher(@attributes, includePossibleTeachers)

  isPaidTeacher: ->
    # TODO: this doesn't actually check to see if they are paid (having prepaids), confusing
    return false unless @isTeacher()
    return @isCreatedByClient() or (/@codeninjas.com$/i.test @get('email'))

  isTeacherOf: co.wrap ({ classroom, classroomId, courseInstance, courseInstanceId }) ->
    if not @isTeacher()
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
    if not @isSchoolAdmin()
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

  getHocCourseInstanceId: () ->
    courseInstanceIds = me.get('courseInstances') || []
    return if courseInstanceIds.length == 0
    courseInstancePromises = []
    courseInstanceIds.forEach((id) =>
      courseInstancePromises.push(api.courseInstances.get({ courseInstanceID: id }))
    )

    Promise.all(courseInstancePromises)
    .then (courseInstances) =>
      courseInstancesHoc = courseInstances.filter((c) => c.courseID == utils.hourOfCodeOptions.courseId)
      return if (courseInstancesHoc.length == 0)
      return courseInstancesHoc[0]._id if (courseInstancesHoc.length == 1)
      # return the latest course instance id if there are multiple
      courseInstancesHoc = _.sortBy(courseInstancesHoc, (c) -> c._id)
      return _.last(courseInstancesHoc)._id
    .catch (err) => console.error("Error in fetching hoc course instance", err)

  isSessionless: ->
    Boolean((utils.getQueryVariable('dev', false) or @isTeacher()) and utils.getQueryVariable('course', false) and not utils.getQueryVariable('course-instance'))

  isInHourOfCode: ->
    return false unless @get('hourOfCode')
    daysElapsed = (new Date() - new Date @get('dateCreated')) / (86400 * 1000)
    return false if daysElapsed > 7  # Disable special HoC handling after a week, treat as normal users after that point
    return false if daysElapsed > 1 and @get('hourOfCodeComplete')  # ... or one day, if they're already done with it
    true

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
    application.tracker.identify()
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
    totalPoint = totalPoint + 1000000 if @isInGodMode()
    User.levelFromExp(totalPoint)

  tier: ->
    User.tierFromLevel @level()

  gems: ->
    gemsEarned = @get('earned')?.gems ? 0
    gemsEarned = gemsEarned + 100000 if @isInGodMode()
    gemsEarned += 1000 if @get('hourOfCode')
    gemsPurchased = @get('purchased')?.gems ? 0
    gemsSpent = @get('spent') ? 0
    Math.floor gemsEarned + gemsPurchased - gemsSpent

  heroes: ->
    heroes = (@get('purchased')?.heroes ? []).concat([ThangTypeConstants.heroes.captain, ThangTypeConstants.heroes.knight, ThangTypeConstants.heroes.champion, ThangTypeConstants.heroes.duelist])
    heroes.push ThangTypeConstants.heroes['code-ninja'] if window.serverConfig.codeNinjas
    for clanHero in utils.clanHeroes when clanHero.clanId in (@get('clans') ? [])
      heroes.push clanHero.thangTypeOriginal
    heroes

  items: -> (@get('earned')?.items ? []).concat(@get('purchased')?.items ? []).concat([ThangTypeConstants.items['simple-boots']])
  levels: -> (@get('earned')?.levels ? []).concat(@get('purchased')?.levels ? []).concat(LevelConstants.levels['dungeons-of-kithgard'])
  ownsHero: (heroOriginal) -> @isInGodMode() || heroOriginal in @heroes()
  ownsItem: (itemOriginal) -> itemOriginal in @items()
  ownsLevel: (levelOriginal) -> levelOriginal in @levels()

  getHeroClasses: ->
    idsToSlugs = _.invert ThangTypeConstants.heroes
    myHeroSlugs = (idsToSlugs[id] for id in @heroes())
    myHeroClasses = []
    myHeroClasses.push heroClass for heroClass, heroSlugs of ThangTypeConstants.heroClasses when _.intersection(myHeroSlugs, heroSlugs).length
    myHeroClasses

  getHeroPoseImage: co.wrap ->
    heroOriginal = @get('heroConfig')?.thangType ? ThangTypeConstants.heroes.captain
    heroThangType = yield fetchJson("/db/thang.type/#{heroOriginal}/version?project=poseImage")
    return '/file/' + heroThangType.poseImage

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

  hasSubscription: ->
    return false if @isStudent() or @isTeacher()
    if payPal = @get('payPal')
      return true if payPal.billingAgreementID
    if stripe = @get('stripe')
      return true if stripe.sponsorID
      return true if stripe.subscriptionID
      return true if stripe.free is true
      return true if _.isString(stripe.free) and new Date() < new Date(stripe.free)
    if products = @get('products')
      now = new Date()
      homeProducts = @activeProducts('basic_subscription')
      maxFree = _.max(homeProducts, (p) => new Date(p.endDate)).endDate
      return true if new Date() < new Date(maxFree)
    false

  premiumEndDate: ->
    return null unless @isPremium()
    stripeEnd = undefined
    if stripe = @get('stripe')
      return $.t('subscribe.forever') if stripe.free is true
      return $.t('subscribe.forever') if stripe.sponsorID
      return $.t('subscribe.forever') if stripe.subscriptionID
      stripeEnd =  moment(stripe.free) if _.isString(stripe.free)

    if products = @get('products')
      homeProducts = @activeProducts('basic_subscription')
      endDate = _.max(homeProducts, (p) => new Date(p.endDate)).endDate
      productsEnd = moment(endDate)
      return stripeEnd.utc().format('ll') if stripeEnd and stripeEnd.isAfter(productsEnd)
      return productsEnd.utc().format('ll')

  isPremium: ->
    return true if @isInGodMode()
    return true if @isAdmin()
    return true if @hasSubscription()
    return false

  isForeverPremium: ->
    return @get('stripe')?.free is true

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

  trackActivity: (activityName, increment=1) ->
    $.ajax({
      method: 'POST'
      url: "/db/user/#{@id}/track/#{activityName}/#{increment}"
      success: (attributes) =>
        @set attributes
      error: ->
        console.error "Couldn't save activity #{activityName}"
    })

  startExperiment: (name, value, probability) ->
    experiments = @get('experiments') ? []
    return console.error "Already started experiment #{name}" if _.find experiments, name: name
    return console.error "Invalid experiment name: #{name}" unless /^[a-z][\-a-z0-9]*$/.test name
    return console.error "No experiment value provided" unless value?
    return console.error "Probability should be between 0-1 if set - #{name} - #{value} - #{probability}" if probability? and not (0 <= probability <= 1)
    $.ajax
      method: 'POST'
      url: "/db/user/#{@id}/start-experiment"
      data: {name, value, probability}
      success: (attributes) =>
        @set attributes
      error: (jqxhr) ->
        console.error "Couldn't start experiment #{name}:", jqxhr.responseJSON
    experiment = name: name, value: value, startDate: new Date()  # Server date/save will be authoritative
    experiment.probability = probability if probability?
    experiments.push experiment
    @set 'experiments', experiments
    experiment

  getExperimentValue: (experimentName, defaultValue=null, defaultValueIfAdmin=null) ->
    # Latest experiment to start with this experiment name wins, in the off chance we have multiple duplicate entries
    defaultValue = defaultValueIfAdmin if defaultValueIfAdmin? and @isAdmin()
    experiments = _.sortBy(@get('experiments') ? [], 'startDate').reverse()
    _.find(experiments, name: experimentName)?.value ? defaultValue

  isEnrolled: -> @prepaidStatus() is 'enrolled'

  prepaidStatus: -> # 'not-enrolled', 'enrolled', 'expired'
    courseProducts = _.filter(@get('products'), {product: 'course'})
    now = new Date()
    activeCourseProducts = _.filter(courseProducts, (p) -> new Date(p.endDate) > now || !p.endDate)
    courseIDs = utils.orderedCourseIDs
    return 'not-enrolled' unless courseProducts.length
    return 'enrolled' if _.some activeCourseProducts, (p) ->
      return true unless p.productOptions?.includedCourseIDs?.length
      return true if _.intersection(p.productOptions.includedCourseIDs, courseIDs).length
      return false
    return 'expired'

  activeProducts: (type) ->
    now = new Date()
    _.filter(@get('products'), (p) ->
      return p.product == type && (new Date(p.endDate) > now || !p.endDate)
    )

  hasAiLeagueActiveProduct: ->
    @activeProducts('ai-league').length > 0

  prepaidNumericalCourses: ->
    courseProducts = @activeProducts('course')
    return utils.courseNumericalStatus['NO_ACCESS'] unless courseProducts.length
    return utils.courseNumericalStatus['FULL_ACCESS'] if _.some courseProducts, (p) => !p.productOptions?.includedCourseIDs?
    union = (res, prepaid) => _.union(res, prepaid.productOptions?.includedCourseIDs ? [])
    courses = _.reduce(courseProducts, union, [])
    fun = (s, k) => s + utils.courseNumericalStatus[k]
    return _.reduce(courses, fun, 0)

  prepaidType: (includeCourseIDs) =>
    courseProducts = @activeProducts('course')
    return undefined unless courseProducts.length

    return 'course' if _.any(courseProducts, (p) => !p.productOptions?.includedCourseIDs?)
    # Note: currently includeCourseIDs is a argument only used when displaying
    # customized license's course names.
    # Be careful to match the returned string EXACTLY to avoid comparison issues

    if includeCourseIDs
      union = (res, prepaid) => _.union(res, prepaid.productOptions?.includedCourseIDs ? [])
      courses = _.reduce(courseProducts, union, [])
      # return all courses names join with + as customized licenses's name
      return (courses.map (id) -> utils.courseAcronyms[id]).join('+')
    # NOTE: Default type is 'course' if no type is marked on the user's copy
    return 'course'

  prepaidIncludesCourse: (course) ->
    courseProducts = @activeProducts('course')
    return false unless courseProducts.length
    # NOTE: Full licenses implicitly include all courses
    return true if _.any(courseProducts, (p) => !p.productOptions?.includedCourseIDs?)
    union = (res, prepaid) => _.union(res, prepaid.productOptions?.includedCourseIDs ? [])
    includedCourseIDs = _.reduce(courseProducts, union, [])
    courseID = course.id or course
    return courseID in includedCourseIDs

  findCourseProduct: (prepaidId) ->
    return _.find @activeProducts('course'),(p) => p.prepaid + '' == prepaidId + ''

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
    @clearUserSpecificLocalStorage()
    @fetch(options)

  stopSpying: (options={}) ->
    options.url = '/auth/stop-spying'
    options.type = 'POST'
    @clearUserSpecificLocalStorage()
    @fetch(options)

  logout: (options={}) ->
    options.type = 'POST'
    options.url = '/auth/logout'
    FB?.logout?()
    options.success ?= =>
      globalVar.application.tracker.identifyAfterNextPageLoad()
      globalVar.application.tracker.resetIdentity().finally =>
        location = _.result(globalVar.currentView, 'logoutRedirectURL')
        @clearUserSpecificLocalStorage?()
        if location
          window.location = location
        else
          window.location.reload()

    @fetch(options)

  clearUserSpecificLocalStorage: ->
    storage.remove key for key in ['hoc-campaign']

  signupWithPassword: (name, email, password, options={}) ->
    options.url = _.result(@, 'url') + '/signup-with-password'
    options.type = 'POST'
    options.data ?= {}
    _.extend(options.data, {name, email, password})
    options.contentType = 'application/json'
    options.xhrFields = { withCredentials: true }
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
    options.xhrFields = { withCredentials: true }
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
    options.xhrFields = { withCredentials: true }
    options.data = JSON.stringify(options.data)
    jqxhr = @fetch(options)
    jqxhr.then ->
      window.tracker?.trackEvent 'Google Login', category: "Signup", label: 'GPlus'
      window.tracker?.trackEvent 'Finished Signup', category: "Signup", label: 'GPlus'
    return jqxhr

  fetchGPlusUser: (gplusID, email, options={}) ->
    options.data ?= {}
    options.data.gplusID = gplusID
    options.data.gplusAccessToken = application.gplusHandler.token()
    options.data.email = email
    @fetch(options)

  loginGPlusUser: (gplusID, options={}) ->
    options.url = '/auth/login-gplus'
    options.type = 'POST'
    options.xhrFields = { withCredentials: true }
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
    options.xhrFields = { withCredentials: true }
    options.data ?= {}
    options.data.facebookID = facebookID
    options.data.facebookAccessToken = application.facebookHandler.token()
    @fetch(options)

  loginEdLinkUser: (code, options={}) ->
    options.url = '/auth/login-ed-link'
    options.type = 'POST'
    options.xhrFields = { withCredentials: true }
    options.data ?= {}
    options.data.code = code
    @fetch(options)

  loginPasswordUser: (usernameOrEmail, password, options={}) ->
    options.xhrFields = { withCredentials: true }
    options.url = '/auth/login'
    options.type = 'POST'
    options.data ?= {}
    _.extend(options.data, { username: usernameOrEmail, password })
    @fetch(options)

  confirmBindAIYouth: (provider, token, options={}) ->
    options.url = '/auth/bind-aiyouth'
    options.type = 'POST'
    options.data ?= {}
    options.data.token = token
    options.data.provider = provider
    @fetch(options)

  makeCoursePrepaid: (prepaidId) ->
    courseProduct = _.find @get('products'), (p) => p.product == 'course' && p.prepaid + '' == prepaidId + ''
    return null unless courseProduct
    Prepaid = require 'models/Prepaid'
    return new Prepaid({
      _id: prepaidId,
      type: 'course',
      includedCourseIDs: courseProduct?.productOptions?.includedCourseIDs
      startDate: courseProduct.startDate,
      endDate: courseProduct.endDate
    })

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
    return @isStudent() or (features.freeOnly and not @isPremium()) or (@isAnonymous() and @get('country') is 'taiwan')

  subscribe: (token, options={}) ->
    stripe = _.clone(@get('stripe') ? {})
    stripe.planID = options.planID || 'basic'
    stripe.token = token.id
    stripe.couponID = options.couponID if options.couponID
    @set({stripe})
    return @patch({headers: {'X-Change-Plan': 'true'}}).then =>
      unless utils.isValidEmail(@get('email'))
        @set({email: token.email})
        @patch()
      return Promise.resolve()

  unsubscribe: ->
    stripe = _.clone(@get('stripe') ? {})
    return unless stripe.planID
    delete stripe.planID
    @set({stripe})
    return @patch({headers: {'X-Change-Plan': 'true'}})

  unsubscribeRecipient: (id, options={}) ->
    options.url = _.result(@, 'url') + "/stripe/recipients/#{id}"
    options.method = 'DELETE'
    return $.ajax(options)

  age: -> utils.yearsSinceMonth @get('birthday')

  isRegisteredForAILeague: ->
    # TODO: This logic could use some thinking about, and maybe an explicit field for when we want to be sure they have registered on purpose instead of happening to have these properties.
    return false unless @get 'birthday'
    return false unless @get 'email'
    return false if @get 'unsubscribedFromMarketingEmails'
    return false unless @get('emails')?.generalNews?.enabled
    true

  getM7ExperimentValue: ->
    value = {true: 'beta', false: 'control', control: 'control', beta: 'beta'}[utils.getQueryVariable 'm7']
    value ?= me.getExperimentValue('m7', null, 'control')
    if value is 'beta' and (new Date() - _.find(me.get('experiments') ? [], name: 'm7')?.startDate) > 1 * 24 * 60 * 60 * 1000
      # Experiment only lasts one day so that users don't get stuck in it
      value = 'control'
    if userUtils.isInLibraryNetwork()
      value = 'control'
    if not value? and me.get('stats')?.gamesCompleted
      # Don't include players who have already started playing
      value = 'control'
    if not value? and new Date(me.get('dateCreated')) < new Date('2022-03-14')
      # Don't include users created before experiment start date
      value = 'control'
    if not value? and not /^en/.test me.get('preferredLanguage', true)
      # Don't include non-English-speaking users before beta levels are translated
      value = 'control'
    if not value? and me.get('hourOfCode')
      # Don't include users coming in through Hour of Code
      value = 'control'
    if not value? and not me.get('anonymous')
      # Don't include registered users
      value = 'control'
    if not value? and features?.china
      # Don't include China players
      value = 'control'
    if not value?
      probability = window.serverConfig?.experimentProbabilities?.m7?.beta ? 0
      if me.get('testGroupNumber') / 256 < probability
        value = 'beta'
        valueProbability = probability
      else
        value = 'control'
        valueProbability = 1 - probability
      me.startExperiment('m7', value, probability)
    value

  # Feature Flags
  # Abstract raw settings away from specific UX changes
  allowStudentHeroPurchase: -> features?.classroomItems ? false and @isStudent()
  canBuyGems: -> false  # Disabled direct buying of gems around 2021-03-16
  constrainHeroHealth: -> features?.classroomItems ? false and @isStudent()
  promptForClassroomSignup: -> not ((features?.chinaUx ? false) or (window.serverConfig?.codeNinjas ? false) or (features?.brainPop ? false) or userUtils.isInLibraryNetwork())
  showGearRestrictionsInClassroom: -> features?.classroomItems ? false and @isStudent()
  showGemsAndXp: -> features?.classroomItems ? false and @isStudent()
  showHeroAndInventoryModalsToStudents: -> features?.classroomItems and @isStudent()
  skipHeroSelectOnStudentSignUp: -> features?.classroomItems ? false
  useDexecure: -> not (features?.chinaInfra ? false)
  useSocialSignOn: -> not ((features?.chinaUx ? false) or (features?.china ? false))
  isTarena: -> features?.Tarena ? false
  useTarenaLogo: -> @isTarena()
  hideTopRightNav: -> @isTarena() or @isILK() or @isICode()
  hideFooter: -> @isTarena() or @isILK() or @isICode()
  hideOtherProductCTAs: -> @isTarena() or @isILK() or @isICode()
  useGoogleClassroom: -> not (features?.chinaUx ? false) and @get('gplusID')?   # if signed in using google SSO
  useGoogleAnalytics: -> not ((features?.china ? false) or (features?.chinaInfra ? false))
  isEdLinkAccount: -> not (features?.chinaUx ? false) and @get('edLink')?
  useDataDog: -> not ((features?.china ? false) or (features?.chinaInfra ? false))
  # features.china is set globally for our China server
  showChinaVideo: -> (features?.china ? false) or (features?.chinaInfra ? false)
  canAccessCampaignFreelyFromChina: (campaignID) -> (utils.isCodeCombat and campaignID == "55b29efd1cd6abe8ce07db0d") or (utils.isOzaria and campaignID == "5d1a8368abd38e8b5363bad9") # teacher can only access CS1 or CH1 freely in China
  isCreatedByTarena: -> @get('clientCreator') == '60fa65059e17ca0019950fdd' || @get('clientCreator') == "5c80a2a0d78b69002448f545"   #ClientID of Tarena2/Tarena3 on koudashijie.com
  isILK: -> @get('clientCreator') is '6082ec9996895d00a9b96e90' or _.find(@get('clientPermissions') ? [], client: '6082ec9996895d00a9b96e90')
  isICode: -> @get('clientCreator') is '61393874c324991d0f68fc70' or _.find(@get('clientPermissions') ? [], client: '61393874c324991d0f68fc70')
  isTecmilenio: -> @get('clientCreator') in ['62de625ef3365e002314d554', '62e7a13c85e9850026fa2c7f'] or _.find(@get('clientPermissions') ? [], (p) -> p.client in ['62de625ef3365e002314d554', '62e7a13c85e9850026fa2c7f'])
  showForumLink: -> not (features?.china ? false)
  showChinaResourceInfo: -> features?.china ? false
  showChinaHomeVersion: -> features?.chinaHome ? false
  useChinaHomeView: -> features?.china and ! features?.chinaHome ? false
  showChinaRegistration: -> features?.china ? false
  enableCpp: -> utils.isCodeCombat and (@hasSubscription() or @isStudent() or @isTeacher())
  useQiyukf: -> false
  useChinaServices: -> features?.china ? false
  useGeneralArticle: -> not (features?.china ? false)

  # Special flag to detect whether we're temporarily showing static html while loading full site
  showingStaticPagesWhileLoading: -> false
  showIndividualRegister: -> not (features?.china ? false)
  hideDiplomatModal: -> features?.china ? false
  showChinaRemindToast: -> features?.china ? false
  showOpenResourceLink: -> not (features?.china ? false)
  useStripe: -> (not ((features?.china ? false) or (features?.chinaInfra ? false))) and (@get('preferredLanguage') isnt 'nl-BE')
  canDeleteAccount: -> not (features?.china ? false)
  canAutoFillCode: -> @isAdmin() || @isTeacher() || @isInGodMode()

  # Ozaria flags
  hasCinematicEditorAccess: -> @isAdmin()
  hasCutsceneEditorAccess: -> @isAdmin()
  hasInteractiveEditorAccess: -> @isAdmin()

  # google classroom flags for new teacher dashboard, remove `useGoogleClassroom` when old dashboard disabled
  showGoogleClassroom: -> not (features?.chinaUx ? false)
  googleClassroomEnabled: -> me.get('gplusID')?

  # Block access to paid campaigns(any campaign other than CH1) for anonymous users + non-admin, non-internal individual users.
  # Scenarios where a user has access to a campaign:
  #   - Admin or internal user
  #   - Free campaigns
  #   - Student with full license
  #   - Teacher
  # Update in server/models/User also, if updated here.
  hasCampaignAccess: (campaignData) ->
    return true if utils.freeCampaignIds.includes(campaignData._id)
    return true if @isAdmin() or @isInternal()

    return true if User.isTeacher(@attributes) # TODO revisit this - we may want to restrict unpaid teachers
    return true if @isStudent() # TODO this should validate the student license, but we currently check this else where

    return false


tiersByLevel = [-1, 0, 0.05, 0.14, 0.18, 0.32, 0.41, 0.5, 0.64, 0.82, 0.91, 1.04, 1.22, 1.35, 1.48, 1.65, 1.78, 1.96, 2.1, 2.24, 2.38, 2.55, 2.69, 2.86, 3.03, 3.16, 3.29, 3.42, 3.58, 3.74, 3.89, 4.04, 4.19, 4.32, 4.47, 4.64, 4.79, 4.96,
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15
]

# Make UserLib accessible via eg. User.broadName(userObj)
_.assign(User, UserLib)
