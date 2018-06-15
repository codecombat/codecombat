mw = require '../middleware'

module.exports.setup = (app) ->

  app.put('/admin/feature-mode/:featureMode', mw.admin.putFeatureMode)
  app.delete('/admin/feature-mode', mw.admin.deleteFeatureMode)
  app.get('/admin/calculate-lines-of-code', mw.admin.calculateLinesOfCode) # For outcomes report

  app.get('/apcsp-files/*', mw.apcsp.getAPCSPFile)

  app.all('/api/*', mw.api.clientAuth)

  app.get('/api/auth/login-o-auth', mw.auth.loginByOAuthProvider)

  app.post('/api/classrooms', mw.api.postClassroom)
  app.put('/api/classrooms/:handle/members', mw.api.putClassroomMember)
  app.put('/api/classrooms/:classroomHandle/courses/:courseHandle/enrolled', mw.api.putClassroomCourseEnrolled)
  app.get('/api/classrooms/:classroomHandle/members/:memberHandle/sessions', mw.api.getClassroomMemberSessions)

  app.post('/api/users', mw.api.postUser)
  app.get('/api/users/:handle', mw.api.getUser)
  app.get('/api/users/:handle/classrooms', mw.api.getUserClassrooms)
  app.put('/api/users/:handle/hero-config', mw.api.putUserHeroConfig)
  app.post('/api/users/:handle/o-auth-identities', mw.api.postUserOAuthIdentity)
  app.post('/api/users/:handle/prepaids', mw.api.putUserSubscription) # Deprecated. TODO: Remove.
  app.put('/api/users/:handle/subscription', mw.api.putUserSubscription)
  app.put('/api/users/:handle/license', mw.api.putUserLicense)
  app.get('/api/user-lookup/israel-id/:israelId', mw.api.getUserLookupByIsraelId)
  app.get('/api/user-lookup/name/:name', mw.api.getUserLookupByName)
  app.get('/api/playtime-stats', mw.api.getPlayTimeStats)

  passport = require('passport')
  app.post('/auth/login', mw.auth.authDelay, passport.authenticate('local'), mw.auth.afterLogin)
  app.post('/auth/login-facebook', mw.auth.authDelay, mw.auth.loginByFacebook, mw.auth.afterLogin)
  app.post('/auth/login-gplus', mw.auth.authDelay, mw.auth.loginByGPlus, mw.auth.afterLogin)
  app.get('/auth/login-clever', mw.auth.authDelay, mw.auth.loginByClever, mw.auth.redirectAfterLogin)
  app.get('/auth/login-o-auth', mw.auth.authDelay, mw.auth.loginByOAuthProvider, mw.auth.redirectOnError, mw.auth.redirectAfterLogin)
  app.post('/auth/logout', mw.auth.logout)
  app.get('/auth/name/?(:name)?', mw.auth.name)
  app.get('/auth/email/?(:email)?', mw.auth.email)
  app.post('/auth/reset', mw.auth.reset)
  app.post('/auth/spy', mw.auth.spy)
  app.post('/auth/stop-spying', mw.auth.stopSpying)
  app.get('/auth/unsubscribe', mw.auth.unsubscribe)
  app.get('/auth/whoami', mw.auth.whoAmI)

  app.post('/contact/send-parent-signup-instructions', mw.contact.sendParentSignupInstructions)
  app.post('/contact/send-teacher-game-dev-project-share', mw.contact.sendTeacherGameDevProjectShare)
  app.post('/contact/send-teacher-signup-instructions', mw.contact.sendTeacherSignupInstructions)

  app.delete('/db/*', mw.auth.checkHasUser())
  app.patch('/db/*', mw.auth.checkHasUser())
  app.post('/db/*', mw.auth.checkHasUser())
  app.put('/db/*', mw.auth.checkHasUser())

  Achievement = require '../models/Achievement'
  app.get('/db/achievement', mw.achievements.fetchByRelated, mw.rest.get(Achievement))
  app.post('/db/achievement', mw.auth.checkHasPermission(['admin', 'artisan']), mw.rest.post(Achievement))
  app.get('/db/achievement/:handle', mw.rest.getByHandle(Achievement))
  app.put('/db/achievement/:handle', mw.auth.checkLoggedIn(), mw.achievements.put)
  app.delete('/db/achievement/:handle', mw.auth.checkHasPermission(['admin', 'artisan']), mw.rest.delete(Achievement))
  app.get('/db/achievement/names', mw.named.names(Achievement))
  app.post('/db/achievement/names', mw.named.names(Achievement))
  app.delete('/db/achievement/:handle/i18n-coverage', mw.auth.checkHasPermission(['admin', 'artisan']), mw.translations.deleteTranslationCoverage(Achievement))
  app.get('/db/achievement/:handle/patches', mw.patchable.patches(Achievement))
  app.post('/db/achievement/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Achievement, 'achievement'))
  app.post('/db/achievement/:handle/watchers', mw.patchable.joinWatchers(Achievement))
  app.delete('/db/achievement/:handle/watchers', mw.patchable.leaveWatchers(Achievement))

  AnalyticsLogEvent = require '../models/AnalyticsLogEvent'
  app.get('/db/analytics.log.event', mw.auth.checkHasPermission(['admin']), mw.rest.get(AnalyticsLogEvent))
  app.post('/db/analytics.log.event/-/log_event',  mw.auth.checkHasUser(), mw.analyticsLogEvents.post)

  app.post('/db/analytics_perday/-/active_classes', mw.auth.checkHasPermission(['admin']), mw.analyticsPerDay.getActiveClasses)
  app.post('/db/analytics_perday/-/active_users', mw.auth.checkHasPermission(['admin']), mw.analyticsPerDay.getActiveUsers)
  app.post('/db/analytics_perday/-/campaign_completions', mw.auth.checkHasPermission(['admin']), mw.analyticsPerDay.getCampaignCompletionsBySlug)
  app.post('/db/analytics_perday/-/level_completions', mw.auth.checkHasPermission(['admin']), mw.analyticsPerDay.getLevelCompletionsBySlug)
  app.post('/db/analytics_perday/-/level_drops', mw.auth.checkHasPermission(['admin']), mw.analyticsPerDay.getLevelDropsBySlugs)
  app.post('/db/analytics_perday/-/level_helps', mw.auth.checkHasPermission(['admin']), mw.analyticsPerDay.getLevelHelpsBySlugs)
  app.post('/db/analytics_perday/-/level_subscriptions', mw.auth.checkHasPermission(['admin']), mw.analyticsPerDay.getLevelSubscriptionsBySlugs)
  app.post('/db/analytics_perday/-/recurring_revenue', mw.auth.checkHasPermission(['admin']), mw.analyticsPerDay.getRecurringRevenue)

  app.get('/db/analytics.stripe.invoice/-/all', mw.auth.checkHasPermission(['admin']), mw.analyticsStripeInvoices.getAll)

  Article = require '../models/Article'
  app.get('/db/article', mw.rest.get(Article))
  app.post('/db/article', mw.auth.checkLoggedIn(), mw.auth.checkHasPermission(['admin', 'artisan']), mw.rest.post(Article))
  app.get('/db/article/names', mw.named.names(Article))
  app.post('/db/article/names', mw.named.names(Article))
  app.get('/db/article/:handle', mw.rest.getByHandle(Article))
  app.put('/db/article/:handle', mw.auth.checkHasPermission(['admin']), mw.rest.put(Article))
  app.patch('/db/article/:handle', mw.auth.checkHasPermission(['admin']), mw.rest.put(Article))
  app.post('/db/article/:handle/new-version', mw.auth.checkLoggedIn(), mw.versions.postNewVersion(Article, { hasPermissionsOrTranslations: 'artisan' }))
  app.get('/db/article/:handle/versions', mw.versions.versions(Article))
  app.get('/db/article/:handle/version/?(:version)?', mw.versions.getLatestVersion(Article))
  app.get('/db/article/:handle/files', mw.files.files(Article, {module: 'article'}))
  app.get('/db/article/:handle/patches', mw.patchable.patches(Article))
  app.post('/db/article/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Article, 'article'))
  app.post('/db/article/:handle/watchers', mw.patchable.joinWatchers(Article))
  app.delete('/db/article/:handle/watchers', mw.patchable.leaveWatchers(Article))

  Branch = require '../models/Branch'
  app.all('/db/branches*', mw.auth.checkLoggedIn(), mw.auth.checkHasPermission(['admin', 'artisan']))
  app.post('/db/branches', mw.branches.post)
  app.get('/db/branches', mw.rest.get(Branch))
  app.put('/db/branches/:handle', mw.branches.put)
  app.delete('/db/branches/:handle', mw.rest.delete(Branch))

  Campaign = require '../models/Campaign'
  app.post('/db/campaign', mw.auth.checkHasPermission(['admin']), mw.rest.post(Campaign))
  app.get('/db/campaign', mw.campaigns.fetchByType, mw.rest.get(Campaign))
  app.delete('/db/campaign/:handle/i18n-coverage', mw.auth.checkHasPermission(['admin', 'artisan']), mw.translations.deleteTranslationCoverage(Campaign))
  app.get('/db/campaign/names', mw.named.names(Campaign))
  app.post('/db/campaign/names', mw.named.names(Campaign))
  app.get('/db/campaign/:handle', mw.rest.getByHandle(Campaign))
  app.put('/db/campaign/:handle', mw.campaigns.put)
  app.get('/db/campaign/:handle/achievements', mw.campaigns.fetchRelatedAchievements)
  app.get('/db/campaign/:handle/levels', mw.campaigns.fetchRelatedLevels)
  app.get('/db/campaign/:handle/patches', mw.patchable.patches(Campaign))
  app.post('/db/campaign/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Campaign, 'campaign'))
  app.get('/db/campaign/-/overworld', mw.campaigns.fetchOverworld)
  app.post('/db/campaign/:handle/watchers', mw.patchable.joinWatchers(Campaign))
  app.delete('/db/campaign/:handle/watchers', mw.patchable.leaveWatchers(Campaign))

  Clan = require '../models/Clan'
  app.post('/db/clan', mw.auth.checkLoggedIn(), mw.clans.postClan)
  app.put('/db/clan/:handle', mw.auth.checkLoggedIn(), mw.clans.putClan)
  app.get('/db/clan/:handle', mw.rest.getByHandle(Clan))
  app.delete('/db/clan/:handle', mw.auth.checkLoggedIn(), mw.clans.deleteClan)
  app.put('/db/clan/:handle/join', mw.auth.checkLoggedIn(), mw.clans.joinClan)
  app.put('/db/clan/:handle/leave', mw.auth.checkLoggedIn(), mw.clans.leaveClan)
  app.get('/db/clan/:handle/member_achievements', mw.clans.getMemberAchievements)
  app.get('/db/clan/:handle/members', mw.clans.getMembers)
  app.get('/db/clan/:handle/member_sessions', mw.clans.getMemberSessions)
  app.get('/db/clan/:handle/public', mw.clans.getPublicClans)
  app.put('/db/clan/:handle/remove/:memberHandle', mw.auth.checkLoggedIn(), mw.clans.removeMember)

  app.post('/db/classroom', mw.classrooms.post)
  app.get('/db/classroom', mw.classrooms.getByCode, mw.classrooms.getByOwner, mw.classrooms.getByMember)
  app.get('/db/classroom/:handle/levels', mw.classrooms.fetchAllLevels)
  app.get('/db/classroom/:handle/courses/:courseID/levels', mw.classrooms.fetchLevelsForCourse)
  app.post('/db/classroom/:handle/invite-members', mw.classrooms.inviteMembers)
  app.get('/db/classroom/:handle/member-sessions', mw.classrooms.fetchMemberSessions)
  app.get('/db/classroom/:handle/members', mw.classrooms.fetchMembers) # TODO: Use mw.auth?
  app.get('/db/classroom/:classroomID/members/:memberID/is-auto-revokable', mw.classrooms.checkIsAutoRevokable)
  app.delete('/db/classroom/:classroomID/members/:memberID', mw.classrooms.deleteMember)
  app.post('/db/classroom/:classroomID/members/:memberID/reset-password', mw.classrooms.setStudentPassword)
  app.post('/db/classroom/:anything/members', mw.auth.checkLoggedIn(), mw.classrooms.join)
  app.post('/db/classroom/:handle/update-courses', mw.classrooms.updateCourses)
  app.get('/db/classroom/:handle', mw.auth.checkLoggedIn()) # TODO: Finish migrating route, adding now so 401 is returned
  app.get('/db/classroom/-/playtimes', mw.auth.checkHasPermission(['admin']), mw.classrooms.fetchPlaytimes)
  app.get('/db/classroom/-/users', mw.auth.checkHasPermission(['admin']), mw.classrooms.getUsers)

  APIClient = require ('../models/APIClient')
  app.get('/db/api-clients/name', mw.auth.checkHasPermission(['admin','licensor']), mw.apiClients.getByName)
  app.get('/db/api-clients', mw.auth.checkHasPermission(['admin','licensor']), mw.rest.get(APIClient))
  app.post('/db/api-clients', mw.auth.checkHasPermission(['admin','licensor']), mw.rest.post(APIClient))
  app.post('/db/api-clients/:handle/new-secret', mw.auth.checkHasPermission(['admin','licensor']), mw.apiClients.newSecret)

  OAuthProvider = require ('../models/OAuthProvider')
  app.post('/db/o-auth', mw.auth.checkHasPermission(['admin','licensor']), mw.oauth.postOAuthProvider)
  app.put('/db/o-auth', mw.auth.checkHasPermission(['admin','licensor']), mw.oauth.putOAuthProvider)
  app.get('/db/o-auth/name', mw.auth.checkHasPermission(['admin','licensor']), mw.oauth.getOAuthProviderByName)
  app.get('/db/o-auth', mw.auth.checkHasPermission(['admin','licensor']), mw.rest.get(OAuthProvider))

  CodeLog = require ('../models/CodeLog')
  app.post('/db/codelogs', mw.codelogs.post)
  app.get('/db/codelogs', mw.auth.checkHasPermission(['admin']), mw.rest.get(CodeLog))

  Course = require '../models/Course'
  app.get('/db/course', mw.courses.get(Course))
  app.delete('/db/course/:handle/i18n-coverage', mw.auth.checkHasPermission(['admin', 'artisan']), mw.translations.deleteTranslationCoverage(Course))
  app.get('/db/course/names', mw.named.names(Course))
  app.post('/db/course/names', mw.named.names(Course))
  app.put('/db/course/:handle', mw.auth.checkHasPermission(['admin', 'artisan']), mw.rest.put(Course))
  app.get('/db/course/:handle', mw.rest.getByHandle(Course))
  app.get('/db/course/:handle/level-solutions', mw.courses.fetchLevelSolutions)
  app.get('/db/course/:handle/levels/:levelOriginal/next', mw.courses.fetchNextLevel)
  app.post('/db/course/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Course, 'course'))
  app.get('/db/course/:handle/patches', mw.patchable.patches(Course))

  app.get('/db/course_instance/-/non-hoc', mw.auth.checkHasPermission(['admin']), mw.courseInstances.fetchNonHoc)
  app.post('/db/course_instance/-/recent', mw.auth.checkHasPermission(['admin']), mw.courseInstances.fetchRecent)
  app.get('/db/course_instance/:handle/levels/:levelOriginal/sessions/:sessionID/next', mw.courseInstances.fetchNextLevels)
  app.post('/db/course_instance/:handle/members', mw.auth.checkLoggedIn(), mw.courseInstances.addMembers)
  app.delete('/db/course_instance/:handle/members', mw.auth.checkLoggedIn(), mw.courseInstances.removeMembers)
  app.get('/db/course_instance/:handle/classroom', mw.auth.checkLoggedIn(), mw.courseInstances.fetchClassroom)
  app.get('/db/course_instance/:handle/course', mw.auth.checkLoggedIn(), mw.courseInstances.fetchCourse)
  app.get('/db/course_instance/:handle/course-level-sessions/:userID', mw.auth.checkLoggedIn(), mw.courseInstances.fetchCourseLevelSessions)
  app.get('/db/course_instance/:handle/peer-projects', mw.auth.checkLoggedIn(), mw.courseInstances.fetchPeerProjects)

  EarnedAchievement = require '../models/EarnedAchievement'
  app.post('/db/earned_achievement', mw.auth.checkHasUser(), mw.earnedAchievements.post)

  Level = require '../models/Level'
  app.post('/db/level/names', mw.named.names(Level))
  app.post('/db/level/:handle', mw.auth.checkLoggedIn(), mw.versions.postNewVersion(Level, { hasPermissionsOrTranslations: 'artisan' })) # TODO: add /new-version to route like Article has
  app.delete('/db/level/:handle/i18n-coverage', mw.auth.checkHasPermission(['admin', 'artisan']), mw.translations.deleteTranslationCoverage(Level))
  app.get('/db/level/:handle/session', mw.auth.checkHasUser(), mw.levels.upsertSession)
  app.post('/db/level/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Level, 'level'))
  app.get('/db/level/:handle/patches', mw.patchable.patches(Level))
  app.get('/db/level/:handle/versions', mw.versions.versions(Level))
  app.get('/db/level/:handle/version/?(:version)?', mw.versions.getLatestVersion(Level))

  LevelComponent = require '../models/LevelComponent'
  app.delete('/db/level.component/:handle/i18n-coverage', mw.auth.checkHasPermission(['admin', 'artisan']), mw.translations.deleteTranslationCoverage(LevelComponent))
  app.post('/db/level.component/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(LevelComponent, 'level_component'))
  app.get('/db/level.component/:handle/patches', mw.patchable.patches(LevelComponent))

  LevelSession = require '../models/LevelSession'
  app.post('/queue/scoring', mw.levelSessions.submitToLadder) # TODO: Rename to /db/level_session/:handle/submit-to-ladder
  app.post('/db/level.session/unset-scores', mw.auth.checkHasPermission(['admin']), mw.levelSessions.unsetScores)
  app.put('/db/level.session/:handle/key-value-db/:key', mw.levelSessions.putKeyValueDb)
  app.post('/db/level.session/:handle/key-value-db/:key/increment', mw.levelSessions.incrementKeyValueDb)
  app.post('/db/level.session/-/levels-and-students', mw.auth.checkHasPermission(['admin']), mw.levelSessions.byLevelsAndStudents)
  app.post('/db/level.session/short-link', mw.auth.checkHasUser(), mw.levelSessions.shortLink)

  LevelSystem = require '../models/LevelSystem'
  app.post('/db/level.system/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(LevelSystem, 'level_system'))
  app.get('/db/level.system/:handle/patches', mw.patchable.patches(LevelSystem))

  app.post('/db/subscription/-/subscribe_prepaid', mw.auth.checkLoggedIn(), mw.subscriptions.subscribeWithPrepaidCode, mw.logging.logErrors('Subscribe with prepaid code'))

  app.delete('/db/user/:handle', mw.auth.checkLoggedIn(), mw.users.delete)
  app.get('/db/user', mw.users.fetchByGPlusID, mw.users.fetchByFacebookID, mw.users.fetchByEmail, mw.users.adminSearch)
  app.put('/db/user/-/become-student', mw.users.becomeStudent)
  app.get('/db/users/-/by-age', mw.auth.checkHasPermission(['admin']), mw.users.fetchByAge)
  app.put('/db/user/-/remain-teacher', mw.users.remainTeacher)
  app.get('/db/user/-/lead-priority', mw.auth.checkLoggedIn(), mw.users.getLeadPriority)
  app.put('/db/user/:handle/verifiedTeacher', mw.auth.checkHasPermission(['admin']), mw.users.setVerifiedTeacher)
  app.post('/db/user/:userID/request-verify-email', mw.users.sendVerificationEmail)
  app.post('/db/user/:userID/verify/:verificationCode', mw.users.verifyEmailAddress) # TODO: Finalize URL scheme
  app.post('/db/user/:userID/keep-me-updated/:verificationCode', mw.users.keepMeUpdated)
  app.post('/db/user/:userID/no-delete-eu/:verificationCode', mw.users.noDeleteEU)
  app.get('/db/user/-/students', mw.auth.checkHasPermission(['admin']), mw.users.getStudents)
  app.get('/db/user/-/teachers', mw.auth.checkHasPermission(['admin']), mw.users.getTeachers)
  app.post('/db/user/:handle/check-for-new-achievement', mw.auth.checkLoggedIn(), mw.users.checkForNewAchievement)
  app.post('/db/user/:handle/destudent', mw.auth.checkHasPermission(['admin']), mw.users.destudent)
  app.post('/db/user/:handle/deteacher', mw.auth.checkHasPermission(['admin']), mw.users.deteacher)
  app.post('/db/user/:handle/paypal/create-billing-agreement', mw.auth.checkLoggedIn(), mw.subscriptions.createPayPalBillingAgreement)
  app.post('/db/user/:handle/paypal/execute-billing-agreement', mw.auth.checkLoggedIn(), mw.subscriptions.executePayPalBillingAgreement)
  app.post('/db/user/:handle/paypal/cancel-billing-agreement', mw.auth.checkLoggedIn(), mw.subscriptions.cancelPayPalBillingAgreement)
  app.post('/db/user/:handle/reset_progress', mw.users.resetProgress)
  app.post('/db/user/:handle/signup-with-facebook', mw.users.signupWithFacebook)
  app.post('/db/user/:handle/signup-with-gplus', mw.users.signupWithGPlus)
  app.post('/db/user/:handle/signup-with-password', mw.users.signupWithPassword)
  app.delete('/db/user/:handle/stripe/recipients/:recipientHandle', mw.auth.checkLoggedIn(), mw.subscriptions.unsubscribeRecipientEndpoint)
  app.get('/db/user/:handle/avatar', mw.users.getAvatar)
  app.get('/db/user/:handle/course-instances', mw.users.getCourseInstances)
  app.get('/db/user/:handle/name-for-classmate', mw.users.getNameForClassmate)

  app.post('/db/patch', mw.patches.post)
  app.put('/db/patch/:handle/status', mw.auth.checkLoggedIn(), mw.patches.setStatus)

  app.get('/db/payments/-/all', mw.auth.checkHasPermission(['admin']), mw.payments.all)

  Poll = require '../models/Poll'
  app.delete('/db/poll/:handle/i18n-coverage', mw.auth.checkHasPermission(['admin', 'artisan']), mw.translations.deleteTranslationCoverage(Poll))
  app.post('/db/poll/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Poll, 'poll'))
  app.get('/db/poll/:handle/patches', mw.patchable.patches(Poll))

  app.get('/db/prepaid/client', mw.auth.checkHasPermission(['admin','licensor']), mw.prepaids.fetchByClient)
  app.get('/db/prepaid', mw.auth.checkLoggedIn(), mw.prepaids.fetchByCreator)
  app.get('/db/prepaid/:handle/creator', mw.prepaids.fetchCreator)
  app.get('/db/prepaid/:handle/joiners', mw.prepaids.fetchJoiners)
  app.get('/db/prepaid/-/active-school-licenses', mw.auth.checkHasPermission(['admin']), mw.prepaids.fetchActiveSchoolLicenses)
  app.get('/db/prepaid/-/active-schools', mw.auth.checkHasPermission(['admin']), mw.prepaids.fetchActiveSchools)
  app.post('/db/prepaid', mw.auth.checkHasPermission(['admin','licensor']), mw.prepaids.post)
  app.post('/db/starter-license-prepaid', mw.auth.checkLoggedIn(), mw.prepaids.purchaseStarterLicenses)
  app.post('/db/prepaid/:handle/redeemers', mw.prepaids.redeem)
  app.post('/db/prepaid/:handle/joiners', mw.prepaids.addJoiner)
  app.delete('/db/prepaid/:handle/redeemers', mw.prepaids.revoke)

  Product = require '../models/Product'
  app.post('/db/products/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Product, 'product'))
  app.get('/db/products/:handle/patches', mw.patchable.patches(Product))
  app.get('/db/products/:handle', mw.rest.getByHandle(Product))
  app.put('/db/products/:handle', mw.auth.checkHasUser(), mw.rest.put(Product))
  app.get('/db/products', mw.auth.checkHasUser(), mw.products.get)
  app.post('/db/products/:handle/purchase', mw.auth.checkLoggedIn(), mw.subscriptions.purchaseProduct)

  app.get('/db/skipped-contact', mw.auth.checkHasPermission(['admin']), mw.skippedContacts.fetchAll)
  app.put('/db/skipped-contact/:id', mw.auth.checkHasPermission(['admin']), mw.skippedContacts.put)

  ThangType = require '../models/ThangType'
  app.delete('/db/thang.type/:handle/i18n-coverage', mw.auth.checkHasPermission(['admin', 'artisan']), mw.translations.deleteTranslationCoverage(ThangType))
  app.post('/db/thang.type/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(ThangType, 'thang_type'))
  app.get('/db/thang.type/:handle/patches', mw.patchable.patches(ThangType))

  TrialRequest = require '../models/TrialRequest'
  app.get('/db/trial.request', mw.trialRequests.fetchByApplicant, mw.auth.checkHasPermission(['admin']), mw.rest.get(TrialRequest))
  app.post('/db/trial.request', mw.trialRequests.post)
  app.get('/db/trial.request/:handle', mw.auth.checkHasPermission(['admin']), mw.rest.getByHandle(TrialRequest))
  app.put('/db/trial.request/:handle', mw.auth.checkHasPermission(['admin']), mw.trialRequests.put)
  app.get('/db/trial.request/-/users', mw.auth.checkHasPermission(['admin']), mw.trialRequests.getUsers)

  app.all('/headers', mw.headers)

  app.get('/healthcheck', mw.healthcheck.healthcheckRoute)

  app.post('/webhooks/intercom', mw.intercom.webhook)
