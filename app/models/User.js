// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let User
const CocoModel = require('./CocoModel')
const ThangTypeConstants = require('lib/ThangTypeConstants')
const LevelConstants = require('lib/LevelConstants')
const utils = require('core/utils')
const api = require('core/api')
const co = require('co')
const storage = require('core/storage')
const globalVar = require('core/globalVar')
const fetchJson = require('core/api/fetch-json')
const userUtils = require('lib/user-utils')
const _ = require('lodash')
const moment = require('moment')

// Pure functions for use in Vue
// First argument is always a raw User.attributes
// Accessible via eg. `User.broadName(userObj)`
const UserLib = {
  broadName (user) {
    if (user.deleted) { return '(deleted)' }
    let name = _.filter([user.firstName, user.lastName]).join(' ')
    if (features?.china) {
      name = user.firstName
    }
    if (!/[a-z]/.test(name)) {
      name = _.string.titleize(name) // Rewrite all-uppercase names to title-case for display
    }
    if (name) { return name }
    ({
      name
    } = user)
    if (name) { return name }
    const [emailName, emailDomain] = Array.from(user.email?.split('@') || []) // eslint-disable-line no-unused-vars
    if (emailName) { return emailName }
    return 'Anonymous'
  },
  isSmokeTestUser (user) { return utils.isSmokeTestEmail(user.email) },
  isTeacher (user, includePossibleTeachers = false) {
    if (includePossibleTeachers && (user.role === 'possible teacher')) { return true } // They maybe haven't created an account but we think they might be a teacher based on behavior
    return ['teacher', 'technology coordinator', 'advisor', 'principal', 'superintendent', 'parent'].includes(user.role)
  }
}

module.exports = (User = (function () {
  let a
  let b
  let c
  User = class User extends CocoModel {
    constructor (...args) {
      super(...args)
      this.prepaidType = this.prepaidType.bind(this)
    }

    static initClass () {
      this.className = 'User'
      this.schema = require('schemas/models/user')
      this.prototype.urlRoot = '/db/user'
      this.prototype.notyErrors = false
      this.PERMISSIONS = {
        COCO_ADMIN: 'admin',
        SCHOOL_ADMINISTRATOR: 'schoolAdministrator',
        ARTISAN: 'artisan',
        GOD_MODE: 'godmode',
        LICENSOR: 'licensor',
        API_CLIENT: 'apiclient',
        ONLINE_TEACHER: 'onlineTeacher',
        BETA_TESTER: 'betaTester',
        PARENT_ADMIN: 'parentAdmin'
      }

      a = 5
      b = 100
      c = b

      this.prototype.getHeroPoseImage = co.wrap(function * () {
        let left
        const heroOriginal = (left = this.get('heroConfig')?.thangType) != null ? left : ThangTypeConstants.heroes.captain
        const heroThangType = yield fetchJson(`/db/thang.type/${heroOriginal}/version?project=poseImage`)
        return '/file/' + heroThangType.poseImage
      })

      this.prototype.fetchOnlineTeachers = co.wrap(function * (users) {
        let url = '/db/user/teachers/online'
        if (users != null) {
          url += `?teachers=${encodeURIComponent(JSON.stringify(users))}`
        }
        return yield fetchJson(url)
      })
    }

    get (attr, withDefault = false) {
      const prop = super.get(attr, withDefault)
      if (attr === 'products') {
        return prop != null ? prop : []
      }
      return prop
    }

    isAdmin () {
      const needle = this.constructor.PERMISSIONS.COCO_ADMIN
      return this.get('permissions', true).includes(needle)
    }

    isLicensor () {
      const needle = this.constructor.PERMISSIONS.LICENSOR
      return this.get('permissions', true).includes(needle)
    }

    isArtisan () {
      const needle = this.constructor.PERMISSIONS.ARTISAN
      return this.get('permissions', true).includes(needle)
    }

    isOnlineTeacher () {
      const needle = this.constructor.PERMISSIONS.ONLINE_TEACHER
      return this.get('permissions', true).includes(needle)
    }

    isInGodMode () {
      const needle = this.constructor.PERMISSIONS.GOD_MODE
      const needle1 = this.constructor.PERMISSIONS.ONLINE_TEACHER
      return this.get('permissions', true).includes(needle) || this.get('permissions', true).includes(needle1)
    }

    isSchoolAdmin () {
      const needle = this.constructor.PERMISSIONS.SCHOOL_ADMINISTRATOR
      return this.get('permissions', true).includes(needle)
    }

    isAPIClient () {
      const needle = this.constructor.PERMISSIONS.API_CLIENT
      return this.get('permissions', true).includes(needle)
    }

    isBetaTester () {
      const needle = this.constructor.PERMISSIONS.BETA_TESTER
      return this.get('permissions', true).includes(needle)
    }

    isParentAdmin () {
      const needle = this.constructor.PERMISSIONS.PARENT_ADMIN
      return this.get('permissions', true).includes(needle)
    }

    isAnonymous () { return this.get('anonymous', true) }
    isSmokeTestUser () { return User.isSmokeTestUser(this.attributes) }
    isIndividualUser () { return !this.isStudent() && !User.isTeacher(this.attributes) }

    isInternal () {
      const email = this.get('email')
      if (!email) { return false }
      return email.endsWith('@codecombat.com') || email.endsWith('@ozaria.com')
    }

    displayName () { return this.get('name', true) }
    broadName () { return User.broadName(this.attributes) }

    inEU (defaultIfUnknown = true) { if (!this.get('country')) { return defaultIfUnknown } else { return utils.inEU(this.get('country')) } }
    addressesIncludeAdministrativeRegion (defaultIfUnknown = true) { if (!this.get('country')) { return defaultIfUnknown } else { return utils.addressesIncludeAdministrativeRegion(this.get('country')) } }

    getPhotoURL (size = 80) {
      if (application.testing) { return '' }
      return `/db/user/${this.id}/avatar?s=${size}`
    }

    getRequestVerificationEmailURL () {
      return this.url() + '/request-verify-email'
    }

    getSlugOrID () { return this.get('slug') || this.get('_id') }

    hasNoPasswordLoginMethod () {
      // Return true if user has any login method that doesn't require a password
      return Boolean(this.get('facebookID') || this.get('gplusID') || this.get('githubID') || this.get('cleverID'))
    }

    currentPasswordRequired () {
      // Return true if current password should be given for password change
      const spying = window.serverSession?.amActually
      return !spying && !this.get('newPasswordRequired') && !this.hasNoPasswordLoginMethod()
    }

    static getUnconflictedName (name, done) {
      // deprecate in favor of @checkNameConflicts, which uses Promises and returns the whole response
      return $.ajax(`/auth/name/${encodeURIComponent(name)}`, {
        cache: false,
        success (data) { return done(data.suggestedName) }
      }
      )
    }

    static checkNameConflicts (name) {
      return new Promise((resolve, reject) => $.ajax(`/auth/name/${encodeURIComponent(name)}`, {
        cache: false,
        success: resolve,
        error (jqxhr) { return reject(jqxhr.responseJSON) }
      }
      ))
    }

    static checkEmailExists (email) {
      return new Promise((resolve, reject) => $.ajax(`/auth/email/${encodeURIComponent(email)}`, {
        cache: false,
        success: resolve,
        error (jqxhr) { return reject(jqxhr.responseJSON) }
      }
      ))
    }

    getEnabledEmails () {
      return (() => {
        const result = []
        const object = this.get('emails', true)
        for (const emailName in object) {
          const emailDoc = object[emailName]
          if (emailDoc.enabled) {
            result.push(emailName)
          }
        }
        return result
      })()
    }

    setEmailSubscription (name, enabled) {
      const newSubs = _.clone(this.get('emails')) || {};
      (newSubs[name] != null ? newSubs[name] : (newSubs[name] = {})).enabled = enabled
      return this.set('emails', newSubs)
    }

    isEmailSubscriptionEnabled (name) { return (this.get('emails') || {})[name]?.enabled }

    isHomeUser () { return (!this.get('role')) || this.isParentHome() }

    isParentHome () { return this.get('role') === 'parent-home' }

    hasNoVerifiedChild () { return !(_.find((this.get('related') || []), c => (c.relation === 'children') && c.verified)) }

    isRegisteredHomeUser () { return this.isHomeUser() && !this.get('anonymous') }

    isStudent () { return this.get('role') === 'student' }

    isTestStudent () { return this.isStudent() && (this.get('related') || []).some(({ relation }) => relation === 'TestStudent') }

    isCreatedByClient () { return (this.get('clientCreator') != null) }

    isTeacher (includePossibleTeachers = false) { return User.isTeacher(this.attributes, includePossibleTeachers) }

    isPaidTeacher () {
      // TODO: this doesn't actually check to see if they are paid (having prepaids), confusing
      if (!this.isTeacher()) { return false }
      return this.isCreatedByClient() || (/@codeninjas.com$/i.test(this.get('email')))
    }

    getHocCourseInstanceId () {
      const courseInstanceIds = me.get('courseInstances') || []
      if (courseInstanceIds.length === 0) { return }
      const courseInstancePromises = []
      courseInstanceIds.forEach(id => {
        return courseInstancePromises.push(api.courseInstances.get({ courseInstanceID: id }))
      })

      return Promise.all(courseInstancePromises)
        .then(courseInstances => {
          let courseInstancesHoc = courseInstances.filter(c => c.courseID === utils.hourOfCodeOptions.courseId)
          if (courseInstancesHoc.length === 0) { return }
          if (courseInstancesHoc.length === 1) { return courseInstancesHoc[0]._id }
          // return the latest course instance id if there are multiple
          courseInstancesHoc = _.sortBy(courseInstancesHoc, c => c._id)
          return _.last(courseInstancesHoc)._id
        }).catch(err => console.error('Error in fetching hoc course instance', err))
    }

    isSessionless () {
      return Boolean((utils.getQueryVariable('dev', false) || this.isTeacher()) && utils.getQueryVariable('course', false) && !utils.getQueryVariable('course-instance'))
    }

    isInHourOfCode () {
      if (!this.get('hourOfCode')) { return false }
      const daysElapsed = (new Date() - new Date(this.get('dateCreated'))) / (86400 * 1000)
      if (daysElapsed > 7) { return false } // Disable special HoC handling after a week, treat as normal users after that point
      if ((daysElapsed > 1) && this.get('hourOfCodeComplete')) { return false } // ... or one day, if they're already done with it
      return true
    }

    async getClientCreatorPermissions () {
      let clientID = this.get('clientCreator')
      if (!clientID) {
        clientID = utils.getApiClientIdFromEmail(this.get('email'))
      }
      if (clientID) {
        try {
          const apiClient = await api.apiClients.getByHandle(clientID)
          this.clientPermissions = apiClient.permissions
          return this.clientPermissions
        } catch (e) {
          console.error(e)
        }
      }
    }

    canManageLicensesViaUI () { return this.clientPermissions?.manageLicensesViaUI != null ? this.clientPermissions?.manageLicensesViaUI : true }

    canRevokeLicensesViaUI () {
      if (!this.clientPermissions || (this.clientPermissions.manageLicensesViaUI && this.clientPermissions.revokeLicensesViaUI)) {
        return true
      }
      return false
    }

    setRole (role, force = false) {
      const oldRole = this.get('role')
      if ((oldRole === role) || (oldRole && !force)) { return }
      this.set('role', role)
      this.patch()
      application.tracker.identify()
      return this.get('role')
    }

    // y = a * ln(1/b * (x + c)) + 1
    static levelFromExp (xp) {
      if (xp > 0) { return Math.floor(a * Math.log((1 / b) * (xp + c))) + 1 } else { return 1 }
    }

    // x = b * e^((y-1)/a) - c
    static expForLevel (level) {
      if (level > 1) { return Math.ceil((Math.exp((level - 1) / a) * b) - c) } else { return 0 }
    }

    static tierFromLevel (level) {
      // TODO: math
      // For now, just eyeball it.
      return tiersByLevel[Math.min(level, tiersByLevel.length - 1)]
    }

    static levelForTier (tier) {
      // TODO: math
      for (let level = 0; level < tiersByLevel.length; level++) {
        const tierThreshold = tiersByLevel[level]
        if (tierThreshold >= tier) { return level }
      }
    }

    level () {
      let totalPoint = this.get('points')
      if (this.isInGodMode()) { totalPoint = totalPoint + 1000000 }
      return User.levelFromExp(totalPoint)
    }

    tier () {
      return User.tierFromLevel(this.level())
    }

    gems () {
      let left, left1, left2
      let gemsEarned = (left = this.get('earned')?.gems) != null ? left : 0
      if (this.isInGodMode()) { gemsEarned = gemsEarned + 100000 }
      if (this.get('hourOfCode')) { gemsEarned += 1000 }
      const gemsPurchased = (left1 = this.get('purchased')?.gems) != null ? left1 : 0
      const gemsSpent = (left2 = this.get('spent')) != null ? left2 : 0
      return Math.floor((gemsEarned + gemsPurchased) - gemsSpent)
    }

    heroes () {
      let left
      const heroes = ((left = this.get('purchased')?.heroes) != null ? left : []).concat([ThangTypeConstants.heroes.captain, ThangTypeConstants.heroes.knight, ThangTypeConstants.heroes.champion, ThangTypeConstants.heroes.duelist])
      if (window.serverConfig.codeNinjas) { heroes.push(ThangTypeConstants.heroes['code-ninja']) }
      for (const clanHero of utils.clanHeroes) {
        if ((this.get('clans') || []).includes(clanHero.clanId)) {
          heroes.push(clanHero.thangTypeOriginal)
        }
      }
      return heroes
    }

    items () {
      let left, left1
      return ((left = this.get('earned')?.items) != null ? left : []).concat((left1 = this.get('purchased')?.items) != null ? left1 : []).concat([ThangTypeConstants.items['simple-boots']])
    }

    levels () {
      let left, left1
      return ((left = this.get('earned')?.levels) != null ? left : []).concat((left1 = this.get('purchased')?.levels) != null ? left1 : []).concat(LevelConstants.levels['dungeons-of-kithgard'])
    }

    ownsHero (heroOriginal) {
      const needle = heroOriginal
      return this.isInGodMode() || this.heroes().includes(needle)
    }

    ownsItem (itemOriginal) {
      const needle = itemOriginal
      return this.items().includes(needle)
    }

    ownsLevel (levelOriginal) {
      const needle = levelOriginal
      return this.levels().includes(needle)
    }

    getHeroClasses () {
      const idsToSlugs = _.invert(ThangTypeConstants.heroes)
      const myHeroSlugs = (this.heroes().map((id) => idsToSlugs[id]))
      const myHeroClasses = []
      for (const heroClass in ThangTypeConstants.heroClasses) { const heroSlugs = ThangTypeConstants.heroClasses[heroClass]; if (_.intersection(myHeroSlugs, heroSlugs).length) { myHeroClasses.push(heroClass) } }
      return myHeroClasses
    }

    validate () {
      const errors = super.validate()
      if (errors && this._revertAttributes) {
        // Do not return errors if they were all present when last marked to revert.
        // This is so that if a user has an invalid property, that does not prevent
        // them from editing their settings.
        const definedAttributes = _.pick(this._revertAttributes, v => v !== undefined)
        const oldResult = tv4.validateMultiple(definedAttributes, this.constructor.schema || {})
        const mapper = error => [error.code.toString(), error.dataPath, error.schemaPath].join(':')
        const originalErrors = _.map(oldResult.errors, mapper)
        const currentErrors = _.map(errors, mapper)
        const newErrors = _.difference(currentErrors, originalErrors)
        if (_.size(newErrors) === 0) {
          return
        }
      }
      return errors
    }

    hasSubscription () {
      if (this.isStudent() || this.isTeacher()) { return false }
      const payPal = this.get('payPal')
      const stripe = this.get('stripe')
      const products = this.get('products')
      if (payPal) {
        if (payPal.billingAgreementID) { return true }
      }
      if (stripe) {
        if (stripe.free === true) { return true }
        if (_.isString(stripe.free) && (new Date() < new Date(stripe.free))) { return true }
      }
      if (products) {
        const homeProducts = this.activeProducts('basic_subscription')
        const maxFree = _.max(homeProducts, p => new Date(p.endDate)).endDate
        if (new Date() < new Date(maxFree)) { return true }
      }
      return false
    }

    isPaidOnlineClassUser () {
      const products = this.get('products')
      if (products) {
        const onlineClassProducts = this.activeProducts('online-classes')
        if (onlineClassProducts.length > 0) { return true }
      }
      return false
    }

    premiumEndDate () {
      if (!this.isPremium()) { return null }
      let stripeEnd
      const stripe = this.get('stripe')
      if (stripe) {
        if (stripe.free === true) { return $.t('subscribe.forever') }
        if (stripe.sponsorID) { return $.t('subscribe.forever') }
        if (stripe.subscriptionID) { return $.t('subscribe.forever') }
        if (_.isString(stripe.free)) { stripeEnd = moment(stripe.free) }
      }

      const products = this.get('products')
      if (products) {
        const homeProducts = this.activeProducts('basic_subscription')
        const {
          endDate
        } = _.max(homeProducts, p => new Date(p.endDate))
        const productsEnd = moment(endDate)
        if (stripeEnd && stripeEnd.isAfter(productsEnd)) { return stripeEnd.utc().format('ll') }
        return productsEnd.utc().format('ll')
      }
    }

    isPremium () {
      if (this.isInGodMode()) { return true }
      if (this.isAdmin()) { return true }
      if (this.hasSubscription()) { return true }
      return false
    }

    isForeverPremium () {
      return this.get('stripe')?.free === true
    }

    sendVerificationCode (code) {
      return $.ajax({
        method: 'POST',
        url: `/db/user/${this.id}/verify/${code}`,
        success: attributes => {
          this.set(attributes)
          return this.trigger('email-verify-success')
        },
        error: () => {
          return this.trigger('email-verify-error')
        }
      })
    }

    sendKeepMeUpdatedVerificationCode (code) {
      return $.ajax({
        method: 'POST',
        url: `/db/user/${this.id}/keep-me-updated/${code}`,
        success: attributes => {
          this.set(attributes)
          return this.trigger('user-keep-me-updated-success')
        },
        error: () => {
          return this.trigger('user-keep-me-updated-error')
        }
      })
    }

    updatePassword (currentPassword, newPassword, success, error) {
      return $.ajax({
        method: 'PUT',
        url: `/db/user/${this.id}/update-user-password`,
        data: { currentPassword, newPassword },
        success: attributes => {
          this.set(attributes)
          return success()
        },
        error
      })
    }

    sendNoDeleteEUVerificationCode (code) {
      return $.ajax({
        method: 'POST',
        url: `/db/user/${this.id}/no-delete-eu/${code}`,
        success: attributes => {
          this.set(attributes)
          return this.trigger('user-no-delete-eu-success')
        },
        error: () => {
          return this.trigger('user-no-delete-eu-error')
        }
      })
    }

    trackActivity (activityName, increment = 1) {
      return $.ajax({
        method: 'POST',
        url: `/db/user/${this.id}/track/${activityName}/${increment}`,
        success: attributes => {
          return this.set(attributes)
        },
        error () {
          return console.error(`Couldn't save activity ${activityName}`)
        }
      })
    }

    startExperiment (name, value, probability) {
      let left
      const experiments = (left = this.get('experiments')) != null ? left : []
      if (_.find(experiments, { name })) { return console.error(`Already started experiment ${name}`) }
      if (!/^[a-z][\-a-z0-9]*$/.test(name)) { return console.error(`Invalid experiment name: ${name}`) } // eslint-disable-line no-useless-escape
      if (value == null) { return console.error('No experiment value provided') }
      if ((probability != null) && !(probability >= 0 && probability <= 1)) { return console.error(`Probability should be between 0-1 if set - ${name} - ${value} - ${probability}`) }
      $.ajax({
        method: 'POST',
        url: `/db/user/${this.id}/start-experiment`,
        data: { name, value, probability },
        success: attributes => {
          return this.set(attributes)
        },
        error (jqxhr) {
          return console.error(`Couldn't start experiment ${name}:`, jqxhr.responseJSON)
        }
      })
      const experiment = { name, value, startDate: new Date() } // Server date/save will be authoritative
      if (probability != null) { experiment.probability = probability }
      experiments.push(experiment)
      this.set('experiments', experiments)
      return experiment
    }

    updateExperimentValue (experimentName, newValue = null) {
      let left
      const experiments = _.sortBy((left = this.get('experiments')) != null ? left : [], 'startDate').reverse()
      const experiment = _.find(experiments, { name: experimentName })
      if (!experiment) { return console.error('No experiment found') }
      experiment.value = newValue
      experiment.probability = 1
      this.set({ experiments })
      return this.save()
    }

    getExperimentValue (experimentName, defaultValue = null, defaultValueIfAdmin = null) {
      // Latest experiment to start with this experiment name wins, in the off chance we have multiple duplicate entries
      let left, left1
      if ((defaultValueIfAdmin != null) && this.isAdmin()) { defaultValue = defaultValueIfAdmin }
      const experiments = _.sortBy((left = this.get('experiments')) != null ? left : [], 'startDate').reverse()
      return (left1 = _.find(experiments, { name: experimentName })?.value) != null ? left1 : defaultValue
    }

    isEnrolled () { return this.prepaidStatus() === 'enrolled' }

    prepaidStatus () { // 'not-enrolled', 'enrolled', 'expired'
      const courseProducts = _.filter(this.get('products'), { product: 'course' })
      const now = new Date()
      const activeCourseProducts = _.filter(courseProducts, p => (new Date(p.endDate) > now) || !p.endDate)
      const courseIDs = utils.orderedCourseIDs
      if (!courseProducts.length) { return 'not-enrolled' }
      if (_.some(activeCourseProducts, function (p) {
        if (!p.productOptions?.includedCourseIDs?.length) { return true }
        if (_.intersection(p.productOptions.includedCourseIDs, courseIDs).length) { return true }
        return false
      })) { return 'enrolled' }
      return 'expired'
    }

    activeProducts (type) {
      const now = new Date()
      return _.filter(this.get('products'), p => (p.product === type) && ((new Date(p.endDate) > now) || !p.endDate))
    }

    expiredProducts (type) {
      const now = new Date()
      return _.filter(this.get('products'), p => (p.product === type) && (new Date(p.endDate) < now))
    }

    getProductsByType (type) {
      const products = this.get('products')
      if (!type) { return products }
      return _.filter(products, p => p.product === type)
    }

    hasAiLeagueActiveProduct () {
      return this.activeProducts('esports').length > 0
    }

    prepaidNumericalCourses () {
      const courseProducts = this.activeProducts('course')
      if (!courseProducts.length) { return utils.courseNumericalStatus.NO_ACCESS }
      if (_.some(courseProducts, p => (p.productOptions?.includedCourseIDs == null))) { return utils.courseNumericalStatus.FULL_ACCESS }
      const union = (res, prepaid) => _.union(res, prepaid.productOptions?.includedCourseIDs != null ? prepaid.productOptions?.includedCourseIDs : [])
      const courses = _.reduce(courseProducts, union, [])
      const fun = (s, k) => s + utils.courseNumericalStatus[k]
      return _.reduce(courses, fun, 0)
    }

    prepaidType (includeCourseIDs) {
      const courseProducts = this.activeProducts('course')
      if (!courseProducts.length) { return undefined }

      if (_.any(courseProducts, p => (p.productOptions?.includedCourseIDs == null))) { return 'course' }
      // Note: currently includeCourseIDs is a argument only used when displaying
      // customized license's course names.
      // Be careful to match the returned string EXACTLY to avoid comparison issues

      if (includeCourseIDs) {
        const union = (res, prepaid) => _.union(res, prepaid.productOptions?.includedCourseIDs != null ? prepaid.productOptions?.includedCourseIDs : [])
        const courses = _.reduce(courseProducts, union, [])
        // return all courses names join with + as customized licenses's name
        return (courses.map(id => utils.courseAcronyms[id])).join('+')
      }
      // NOTE: Default type is 'course' if no type is marked on the user's copy
      return 'course'
    }

    prepaidIncludesCourse (course) {
      const courseProducts = this.activeProducts('course')
      if (!courseProducts.length) { return false }
      // NOTE: Full licenses implicitly include all courses
      if (_.any(courseProducts, p => (p.productOptions?.includedCourseIDs == null))) { return true }
      const union = (res, prepaid) => _.union(res, prepaid.productOptions?.includedCourseIDs != null ? prepaid.productOptions?.includedCourseIDs : [])
      const includedCourseIDs = _.reduce(courseProducts, union, [])
      const courseID = course.id || course
      return includedCourseIDs.includes(courseID)
    }

    findCourseProduct (prepaidId) {
      return _.find(this.activeProducts('course'), p => (p.prepaid + '') === (prepaidId + ''))
    }

    fetchCreatorOfPrepaid (prepaid) {
      return this.fetch({ url: `/db/prepaid/${prepaid.id}/creator` })
    }

    fetchNameForClassmate (options = {}) {
      options.method = 'GET'
      options.contentType = 'application/json'
      options.url = `/db/user/${this.id}/name-for-classmate`
      return $.ajax(options)
    }

    // Function meant for "me"

    spy (user, options = {}) {
      user = user.id || user // User instance, user ID, email or username
      options.url = '/auth/spy'
      options.type = 'POST'
      if (options.data == null) { options.data = {} }
      options.data.user = user
      this.clearUserSpecificLocalStorage()
      return this.fetch(options)
    }

    stopSpying (options = {}) {
      options.url = '/auth/stop-spying'
      options.type = 'POST'
      this.clearUserSpecificLocalStorage()
      return this.fetch(options)
    }

    logout (options = {}) {
      options.type = 'POST'
      options.url = '/auth/logout'
      window?.FB?.logout?.()
      if (!options.success) {
        options.success = () => {
          globalVar.application.tracker.identifyAfterNextPageLoad()
          return globalVar.application.tracker.resetIdentity().finally(() => {
            const location = _.result(globalVar.currentView, 'logoutRedirectURL')
            this.clearUserSpecificLocalStorage?.()
            if (location) {
              window.location = location
            } else {
              window.location.reload()
            }
          })
        }
      }

      return this.fetch(options)
    }

    clearUserSpecificLocalStorage () {
      for (const key of ['hoc-campaign']) { storage.remove(key) }
      return userUtils.removeLibraryKeys()
    }

    signupWithPassword (name, email, password, options = {}) {
      options.url = _.result(this, 'url') + '/signup-with-password'
      options.type = 'POST'
      if (options.data == null) { options.data = {} }
      _.extend(options.data, { name, email, password })
      options.contentType = 'application/json'
      options.xhrFields = { withCredentials: true }
      options.data = JSON.stringify(options.data)
      const jqxhr = this.fetch(options)
      jqxhr.then(() => window.tracker?.trackEvent('Finished Signup', { category: 'Signup', label: 'CodeCombat' }))
      return jqxhr
    }

    signupWithFacebook (name, email, facebookID, options = {}) {
      options.url = _.result(this, 'url') + '/signup-with-facebook'
      options.type = 'POST'
      if (options.data == null) { options.data = {} }
      _.extend(options.data, { name, email, facebookID, facebookAccessToken: application.facebookHandler.token() })
      options.contentType = 'application/json'
      options.xhrFields = { withCredentials: true }
      options.data = JSON.stringify(options.data)
      const jqxhr = this.fetch(options)
      jqxhr.then(function () {
        window.tracker?.trackEvent('Facebook Login', { category: 'Signup', label: 'Facebook' })
        return window.tracker?.trackEvent('Finished Signup', { category: 'Signup', label: 'Facebook' })
      })
      return jqxhr
    }

    signupWithGPlus (name, email, gplusID, options = {}) {
      options.url = _.result(this, 'url') + '/signup-with-gplus'
      options.type = 'POST'
      if (options.data == null) { options.data = {} }
      _.extend(options.data, { name, email, gplusID, gplusAccessToken: application.gplusHandler.token() })
      options.contentType = 'application/json'
      options.xhrFields = { withCredentials: true }
      options.data = JSON.stringify(options.data)
      const jqxhr = this.fetch(options)
      jqxhr.then(function () {
        window.tracker?.trackEvent('Google Login', { category: 'Signup', label: 'GPlus' })
        return window.tracker?.trackEvent('Finished Signup', { category: 'Signup', label: 'GPlus' })
      })
      return jqxhr
    }

    fetchGPlusUser (gplusID, email, options = {}) {
      if (options.data == null) { options.data = {} }
      options.data.gplusID = gplusID
      options.data.gplusAccessToken = application.gplusHandler.token()
      options.data.email = email
      return this.fetch(options)
    }

    linkGPlusUser (gplusID, email, options = {}) {
      options.url = `/db/user/${this.id}/link-with-gplus`
      options.type = 'POST'
      options.xhrFields = { withCredentials: true }
      if (options.data == null) { options.data = {} }
      options.data.gplusID = gplusID
      options.data.gplusAccessToken = application.gplusHandler.token()
      options.data.email = email
      return this.fetch(options)
    }

    loginGPlusUser (gplusID, options = {}) {
      options.url = '/auth/login-gplus'
      options.type = 'POST'
      options.xhrFields = { withCredentials: true }
      if (options.data == null) { options.data = {} }
      options.data.gplusID = gplusID
      options.data.gplusAccessToken = application.gplusHandler.token()
      return this.fetch(options)
    }

    fetchFacebookUser (facebookID, options = {}) {
      if (options.data == null) { options.data = {} }
      options.data.facebookID = facebookID
      options.data.facebookAccessToken = application.facebookHandler.token()
      return this.fetch(options)
    }

    loginFacebookUser (facebookID, options = {}) {
      options.url = '/auth/login-facebook'
      options.type = 'POST'
      options.xhrFields = { withCredentials: true }
      if (options.data == null) { options.data = {} }
      options.data.facebookID = facebookID
      options.data.facebookAccessToken = application.facebookHandler.token()
      return this.fetch(options)
    }

    loginEdLinkUser (code, options = {}) {
      options.url = '/auth/login-ed-link'
      options.type = 'POST'
      options.xhrFields = { withCredentials: true }
      if (options.data == null) { options.data = {} }
      options.data.code = code
      return this.fetch(options)
    }

    loginPasswordUser (usernameOrEmail, password, options = {}) {
      options.xhrFields = { withCredentials: true }
      options.url = '/auth/login'
      options.type = 'POST'
      if (options.data == null) { options.data = {} }
      _.extend(options.data, { username: usernameOrEmail, password })
      return this.fetch(options)
    }

    confirmBindAIYouth (provider, token, options = {}) {
      options.url = '/auth/bind-aiyouth'
      options.type = 'POST'
      if (options.data == null) { options.data = {} }
      options.data.token = token
      options.data.provider = provider
      return this.fetch(options)
    }

    changePassword (userId, password, options = {}) {
      options.url = '/auth/change-password'
      options.type = 'POST'
      if (options.data == null) { options.data = {} }
      _.extend(options.data, { userId, password })
      return this.fetch(options)
    }

    makeCoursePrepaid (prepaidId) {
      const courseProduct = _.find(this.get('products'), p => (p.product === 'course') && ((p.prepaid + '') === (prepaidId + '')))
      if (!courseProduct) { return null }
      const Prepaid = require('models/Prepaid')
      return new Prepaid({
        _id: prepaidId,
        type: 'course',
        includedCourseIDs: courseProduct?.productOptions?.includedCourseIDs,
        startDate: courseProduct.startDate,
        endDate: courseProduct.endDate
      })
    }

    // TODO: Probably better to denormalize this into the user
    getLeadPriority () {
      const request = $.get('/db/user/-/lead-priority')
      request.then(({ priority }) => application.tracker.identify({ priority }))
      return request
    }

    becomeStudent (options = {}) {
      options.url = '/db/user/-/become-student'
      options.type = 'PUT'
      return this.fetch(options)
    }

    remainTeacher (options = {}) {
      options.url = '/db/user/-/remain-teacher'
      options.type = 'PUT'
      return this.fetch(options)
    }

    destudent (options = {}) {
      options.url = _.result(this, 'url') + '/destudent'
      options.type = 'POST'
      return this.fetch(options)
    }

    deteacher (options = {}) {
      options.url = _.result(this, 'url') + '/deteacher'
      options.type = 'POST'
      return this.fetch(options)
    }

    checkForNewAchievement (options = {}) {
      options.url = _.result(this, 'url') + '/check-for-new-achievement'
      options.type = 'POST'
      const jqxhr = this.fetch(options)

      // Setting @loading to false because otherwise, if the user tries to edit their settings while checking
      // for new achievements, the changes won't be saved. This is because AccountSettingsView relies on
      // hasLocalChanges, and that is only true if, when set is called, the model isn't "loading".
      this.loading = false

      return jqxhr
    }

    finishedAnyLevels () { return Boolean((this.get('stats') || {}).gamesCompleted) }

    isFromUk () { return (this.get('country') === 'united-kingdom') || (this.get('preferredLanguage') === 'en-GB') }
    isFromIndia () { return this.get('country') === 'india' }
    setToGerman () { return _.string.startsWith((this.get('preferredLanguage') || ''), 'de') }
    setToSpanish () { return _.string.startsWith((this.get('preferredLanguage') || ''), 'es') }

    freeOnly () {
      return this.isStudent() || (features.freeOnly && !this.isPremium()) || (this.isAnonymous() && (this.get('country') === 'taiwan'))
    }

    subscribe (token, options = {}) {
      let left
      const stripe = _.clone((left = this.get('stripe')) != null ? left : {})
      stripe.planID = options.planID || 'basic'
      stripe.token = token.id
      if (options.couponID) { stripe.couponID = options.couponID }
      this.set({ stripe })
      return this.patch({ headers: { 'X-Change-Plan': 'true' } }).then(() => {
        if (!utils.isValidEmail(this.get('email'))) {
          this.set({ email: token.email })
          this.patch()
        }
        return Promise.resolve()
      })
    }

    unsubscribe () {
      let left
      const stripe = _.clone((left = this.get('stripe')) != null ? left : {})
      if (!stripe.planID) { return }
      delete stripe.planID
      this.set({ stripe })
      return this.patch({ headers: { 'X-Change-Plan': 'true' } })
    }

    unsubscribeRecipient (id, options = {}) {
      options.url = _.result(this, 'url') + `/stripe/recipients/${id}`
      options.method = 'DELETE'
      return $.ajax(options)
    }

    age () { return utils.yearsSinceMonth(this.get('birthday')) }

    isRegisteredForAILeague () {
      // TODO: This logic could use some thinking about, and maybe an explicit field for when we want to be sure they have registered on purpose instead of happening to have these properties.
      if (!this.get('birthday')) { return false }
      if (!this.get('email')) { return false }
      if (this.get('unsubscribedFromMarketingEmails')) { return false }
      if (!this.get('emails')?.generalNews?.enabled) { return false }
      return true
    }

    getM7ExperimentValue () {
      let left
      let value = { true: 'beta', false: 'control', control: 'control', beta: 'beta' }[utils.getQueryVariable('m7')]
      if (value == null) { value = me.getExperimentValue('m7', null, 'control') }
      if ((value === 'beta') && ((new Date() - _.find((left = me.get('experiments')) != null ? left : [], { name: 'm7' })?.startDate) > (1 * 24 * 60 * 60 * 1000))) {
        // Experiment only lasts one day so that users don't get stuck in it
        value = 'control'
      }
      if (userUtils.isInLibraryNetwork()) {
        value = 'control'
      }
      if ((value == null) && me.get('stats')?.gamesCompleted) {
        // Don't include players who have already started playing
        value = 'control'
      }
      if ((value == null) && (new Date(me.get('dateCreated')) < new Date('2022-03-14'))) {
        // Don't include users created before experiment start date
        value = 'control'
      }
      if ((value == null) && !/^en/.test(me.get('preferredLanguage', true))) {
        // Don't include non-English-speaking users before beta levels are translated
        value = 'control'
      }
      if ((value == null) && me.get('hourOfCode')) {
        // Don't include users coming in through Hour of Code
        value = 'control'
      }
      if ((value == null) && !me.get('anonymous')) {
        // Don't include registered users
        value = 'control'
      }
      if ((value == null) && features?.china) {
        // Don't include China players
        value = 'control'
      }
      if ((value == null)) {
        let valueProbability
        const probability = window.serverConfig?.experimentProbabilities?.m7?.beta != null ? window.serverConfig?.experimentProbabilities?.m7?.beta : 0
        if ((me.get('testGroupNumber') / 256) < probability) {
          value = 'beta'
          valueProbability = probability
        } else {
          value = 'control'
          valueProbability = 1 - probability
        }
        me.startExperiment('m7', value, valueProbability)
      }
      return value
    }

    getLevelChatExperimentValue () {
      let value = { true: 'beta', false: 'control', control: 'control', beta: 'beta' }[utils.getQueryVariable('ai')]
      if ((value == null) && utils.isOzaria) {
        // Don't include Ozaria for now
        value = 'control'
      }
      if ((value == null) && features?.china) {
        // Don't include China players for now
        value = 'control'
      }
      if ((value == null) && (me.get('role') === 'student')) {
        // Don't include student users (do include teachers, parents, home users, and anonymous)
        value = 'control'
      }
      if ((value == null)) {
        // No experiment any more, just on for everyone else
        value = 'beta'
      }
      return value
    }

    getHackStackExperimentValue () {
      let value = { true: 'beta', false: 'control', control: 'control', beta: 'beta' }[utils.getQueryVariable('hackstack')]
      if (value == null) { value = me.getExperimentValue('hackstack', null, 'beta') }
      if ((value == null) && utils.isOzaria) {
        // Don't include Ozaria for now
        value = 'control'
      }
      if ((value == null) && features?.china) {
        // Don't include China players for now
        value = 'control'
      }
      if (userUtils.isInLibraryNetwork()) {
        value = 'control'
      }
      if ((value == null) && !/^en/.test(me.get('preferredLanguage', true))) {
        // Don't include non-English-speaking users before we fine-tune for other languages
        value = 'control'
      }
      if ((value == null) && me.get('hourOfCode')) {
        // Don't include users coming in through Hour of Code
        value = 'control'
      }
      if ((value == null) && me.get('role')) {
        // Don't include users other than home users
        value = 'control'
      }
      if ((value == null)) {
        let valueProbability
        const probability = window.serverConfig?.experimentProbabilities?.hackstack?.beta != null ? window.serverConfig?.experimentProbabilities?.hackstack?.beta : 0.05
        if (Math.random() < probability) {
          value = 'beta'
          valueProbability = probability
        } else {
          value = 'control'
          valueProbability = 1 - probability
        }
        console.log('starting hackstack experiment with value', value, 'prob', valueProbability)
        me.startExperiment('hackstack', value, valueProbability)
      }
      if (me.isAdmin()) {
        value = 'beta'
      }
      return value
    }

    removeRelatedAccount (relatedUserId, options = {}) {
      options.url = '/db/user/related-accounts'
      options.type = 'DELETE'
      if (options.data == null) { options.data = {} }
      options.data.userId = relatedUserId
      return this.fetch(options)
    }

    linkRelatedAccount (body, options = {}) {
      options.url = '/db/user/related-accounts'
      options.type = 'PUT'
      if (options.data == null) { options.data = body }
      return this.fetch(options)
    }

    getRelatedAccounts (body, options = {}) {
      options.url = '/db/user/related-accounts/details'
      return this.fetch(options)
    }

    getTestStudentId () {
      const testStudentRelation = (this.get('related') || []).filter(related => related.relation === 'TestStudent')[0]
      if (testStudentRelation) {
        return Promise.resolve(testStudentRelation.userId)
      } else {
        return this.createTestStudentAccount().then(response => {
          return response.relatedUserId
        })
      }
    }

    switchToStudentMode () {
      return this.getTestStudentId().then(testStudentId => this.spy({ id: testStudentId }))
    }

    switchToTeacherMode () {
      return this.switchToStudentMode()
    }

    createTestStudentAccount (body, options = {}) {
      options.url = '/db/user/create-test-student-account'
      options.type = 'PUT'
      if (options.data == null) { options.data = body }
      return this.fetch(options)
    }

    createAndAssociateAccount (body, options = {}) {
      options.url = '/db/user/related-accounts/associate-account'
      options.type = 'PUT'
      if (options.data == null) { options.data = body }
      return this.fetch(options)
    }

    lastClassroomItems () {
      // We don't always have a classroom at hand, so whenever we do interact with a classroom, we can temporarily store the classroom items setting
      if (this.lastClassroomItemsCache != null) { return this.lastClassroomItemsCache }
      this.lastClassroomItemsCache = storage.load('last-classroom-items')
      return this.lastClassroomItemsCache != null ? this.lastClassroomItemsCache : false
    }

    setLastClassroomItems (enabled) {
      this.lastClassroomItemsCache = enabled
      return storage.save('last-classroom-items', enabled)
    }

    // Feature Flags
    // Abstract raw settings away from specific UX changes
    canBuyGems () { return false } // Disabled direct buying of gems around 2021-03-16
    constrainHeroHealth () { return features?.classroomItems != null ? features?.classroomItems : this.lastClassroomItems() && this.isStudent() }
    promptForClassroomSignup () { return !((features?.chinaUx != null ? features?.chinaUx : false) || (window.serverConfig?.codeNinjas != null ? window.serverConfig?.codeNinjas : false) || (features?.brainPop != null ? features?.brainPop : false) || userUtils.isInLibraryNetwork()) }
    showGearRestrictionsInClassroom () { return features?.classroomItems != null ? features?.classroomItems : this.lastClassroomItems() && this.isStudent() }
    showGemsAndXpInClassroom () { return features?.classroomItems != null ? features?.classroomItems : this.lastClassroomItems() && this.isStudent() }
    showHeroAndInventoryModalsToStudents () { return features?.classroomItems != null ? features?.classroomItems : this.lastClassroomItems() && this.isStudent() }
    skipHeroSelectOnStudentSignUp () { return features?.classroomItems != null ? features?.classroomItems : false }
    useDexecure () { return !(features?.chinaInfra != null ? features?.chinaInfra : false) }
    useSocialSignOn () { return !((features?.chinaUx != null ? features?.chinaUx : false) || (features?.china != null ? features?.china : false)) }
    isTarena () { return features?.Tarena != null ? features?.Tarena : false }
    useTarenaLogo () { return this.isTarena() }
    hideTopRightNav () { return this.isTarena() || this.isILK() || this.isICode() }
    hideFooter () { return this.isTarena() || this.isILK() || this.isICode() }
    hideOtherProductCTAs () { return this.isTarena() || this.isILK() || this.isICode() }
    useGoogleClassroom () { return !(features?.chinaUx != null ? features?.chinaUx : false) && (this.get('gplusID') != null) } // if signed in using google SSO
    useGoogleCalendar () { return !(features?.chinaUx != null ? features?.chinaUx : false) && (this.get('gplusID') != null) && (this.isAdmin() || this.isOnlineTeacher()) } // if signed in using google SSO
    useGoogleAnalytics () { return !((features?.china != null ? features?.china : false) || (features?.chinaInfra != null ? features?.chinaInfra : false)) }
    isEdLinkAccount () { return !(features?.chinaUx != null ? features?.chinaUx : false) && (this.get('edLink') != null) }
    useDataDog () { return !((features?.china != null ? features?.china : false) || (features?.chinaInfra != null ? features?.chinaInfra : false)) }
    // features.china is set globally for our China server
    showChinaVideo () { return (features?.china != null ? features?.china : false) || (features?.chinaInfra != null ? features?.chinaInfra : false) }
    canAccessCampaignFreelyFromChina (campaignID) { return (utils.isCodeCombat && (campaignID === '55b29efd1cd6abe8ce07db0d')) || (utils.isOzaria && (campaignID === '5d1a8368abd38e8b5363bad9')) } // teacher can only access CS1 or CH1 freely in China
    isCreatedByTarena () { return (this.get('clientCreator') === '60fa65059e17ca0019950fdd') || (this.get('clientCreator') === '5c80a2a0d78b69002448f545') } // ClientID of Tarena2/Tarena3 on koudashijie.com
    isILK () {
      let left
      return (this.get('clientCreator') === '6082ec9996895d00a9b96e90') || _.find((left = this.get('clientPermissions')) != null ? left : [], { client: '6082ec9996895d00a9b96e90' })
    }

    isICode () {
      let left
      return (this.get('clientCreator') === '61393874c324991d0f68fc70') || _.find((left = this.get('clientPermissions')) != null ? left : [], { client: '61393874c324991d0f68fc70' })
    }

    isTecmilenio () {
      let left
      return ['62de625ef3365e002314d554', '62e7a13c85e9850026fa2c7f'].includes(this.get('clientCreator')) || _.find((left = this.get('clientPermissions')) != null ? left : [], p => ['62de625ef3365e002314d554', '62e7a13c85e9850026fa2c7f'].includes(p.client))
    }

    showForumLink () { return !(features?.china != null ? features?.china : false) }
    showChinaResourceInfo () { return features?.china != null ? features?.china : false }
    showChinaHomeVersion () { return features?.chinaHome != null ? features?.chinaHome : false }
    useChinaHomeView () {
      let left
      return (left = features?.china && !features?.chinaHome) != null ? left : false
    }

    showChinaRegistration () { return features?.china != null ? features?.china : false }
    enableCpp () { return utils.isCodeCombat && (this.hasSubscription() || this.isStudent() || this.isTeacher()) }
    enableJava () { return utils.isCodeCombat && (this.hasSubscription() || this.isStudent() || (this.isTeacher() && this.isBetaTester())) }
    useQiyukf () { return false }
    useChinaServices () { return features?.china != null ? features?.china : false }
    useGeneralArticle () { return !(features?.china != null ? features?.china : false) }

    // Special flag to detect whether we're temporarily showing static html while loading full site
    showingStaticPagesWhileLoading () { return false }
    showIndividualRegister () { return !(features?.china != null ? features?.china : false) }
    hideDiplomatModal () { return features?.china != null ? features?.china : false }
    showChinaRemindToast () { return features?.china != null ? features?.china : false }
    showOpenResourceLink () { return !(features?.china != null ? features?.china : false) }
    useStripe () { return (!((features?.china != null ? features?.china : false) || (features?.chinaInfra != null ? features?.chinaInfra : false))) && (this.get('preferredLanguage') !== 'nl-BE') }
    canDeleteAccount () { return !(features?.china != null ? features?.china : false) }
    canAutoFillCode () { return this.isAdmin() || this.isTeacher() || this.isInGodMode() }

    // Ozaria flags
    hasCinematicEditorAccess () { return this.isAdmin() }
    hasCutsceneEditorAccess () { return this.isAdmin() }
    hasInteractiveEditorAccess () { return this.isAdmin() }

    // google classroom flags for new teacher dashboard, remove `useGoogleClassroom` when old dashboard disabled
    showGoogleClassroom () { return !(features?.chinaUx != null ? features?.chinaUx : false) }
    googleClassroomEnabled () { return (me.get('gplusID') != null) }

    // Block access to paid campaigns(any campaign other than CH1) for anonymous users + non-admin, non-internal individual users.
    // Scenarios where a user has access to a campaign:
    //   - Admin or internal user
    //   - Free campaigns
    //   - Student with full license
    //   - Teacher
    // Update in server/models/User also, if updated here.
    hasCampaignAccess (campaignData) {
      if (utils.freeCampaignIds.includes(campaignData._id)) { return true }
      if (this.isAdmin() || this.isInternal()) { return true }

      if (User.isTeacher(this.attributes)) { return true } // TODO revisit this - we may want to restrict unpaid teachers
      if (this.isStudent()) { return true } // TODO this should validate the student license, but we currently check this else where

      return false
    }
  }
  User.initClass()
  return User
})())

const tiersByLevel = [-1, 0, 0.05, 0.14, 0.18, 0.32, 0.41, 0.5, 0.64, 0.82, 0.91, 1.04, 1.22, 1.35, 1.48, 1.65, 1.78, 1.96, 2.1, 2.24, 2.38, 2.55, 2.69, 2.86, 3.03, 3.16, 3.29, 3.42, 3.58, 3.74, 3.89, 4.04, 4.19, 4.32, 4.47, 4.64, 4.79, 4.96,
  5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15
]

// Make UserLib accessible via eg. User.broadName(userObj)
_.assign(User, UserLib)
