mw = require '../middleware'

module.exports.setup = (app) ->
  
  app.put('/admin/feature-mode/:featureMode', mw.admin.putFeatureMode)
  app.delete('/admin/feature-mode', mw.admin.deleteFeatureMode)
  
  app.all('/api/*', mw.api.clientAuth)
  
  app.get('/api/auth/login-o-auth', mw.auth.loginByOAuthProvider)
  
  app.put('/api/classrooms/:handle/members', mw.api.putClassroomMember)
  app.put('/api/classrooms/:classroomHandle/courses/:courseHandle/enrolled', mw.api.putClassroomCourseEnrolled)
  
  app.post('/api/users', mw.api.postUser)
  app.get('/api/users/:handle', mw.api.getUser)
  app.get('/api/users/:handle/classrooms', mw.api.getUserClassrooms)
  app.put('/api/users/:handle/hero-config', mw.api.putUserHeroConfig)
  app.post('/api/users/:handle/o-auth-identities', mw.api.postUserOAuthIdentity)
  app.post('/api/users/:handle/prepaids', mw.api.putUserSubscription) # Deprecated. TODO: Remove.
  app.put('/api/users/:handle/subscription', mw.api.putUserSubscription)
  app.put('/api/users/:handle/license', mw.api.putUserLicense)
  app.get('/api/user-lookup/israel-id/:israelId', mw.api.getUserLookupByIsraelId)
  
  passport = require('passport')
  app.post('/auth/login', passport.authenticate('local'), mw.auth.afterLogin)
  app.post('/auth/login-facebook', mw.auth.loginByFacebook, mw.auth.afterLogin)
  app.post('/auth/login-gplus', mw.auth.loginByGPlus, mw.auth.afterLogin)
  app.get('/auth/login-clever', mw.auth.loginByClever, mw.auth.redirectAfterLogin)
  app.get('/auth/login-o-auth', mw.auth.loginByOAuthProvider, mw.auth.redirectAfterLogin)
  app.post('/auth/logout', mw.auth.logout)
  app.get('/auth/name/?(:name)?', mw.auth.name)
  app.get('/auth/email/?(:email)?', mw.auth.email)
  app.post('/auth/reset', mw.auth.reset)
  app.post('/auth/spy', mw.auth.spy)
  app.post('/auth/stop-spying', mw.auth.stopSpying)
  app.get('/auth/unsubscribe', mw.auth.unsubscribe)
  app.get('/auth/whoami', mw.auth.whoAmI)

  app.post('/contact/send-parent-signup-instructions', mw.contact.sendParentSignupInstructions)

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
  app.get('/db/achievement/:handle/patches', mw.patchable.patches(Achievement))
  app.post('/db/achievement/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Achievement, 'achievement'))
  app.post('/db/achievement/:handle/watchers', mw.patchable.joinWatchers(Achievement))
  app.delete('/db/achievement/:handle/watchers', mw.patchable.leaveWatchers(Achievement))

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
  app.get('/db/campaign/names', mw.named.names(Campaign))
  app.post('/db/campaign/names', mw.named.names(Campaign))
  app.get('/db/campaign/:handle', mw.rest.getByHandle(Campaign))
  app.put('/db/campaign/:handle', mw.campaigns.put)
  app.get('/db/campaign/:handle/achievements', mw.campaigns.fetchRelatedAchievements)
  app.get('/db/campaign/:handle/levels', mw.campaigns.fetchRelatedLevels)
  app.get('/db/campaign/:handle/patches', mw.patchable.patches(Campaign))
  app.post('/db/campaign/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Campaign, 'campaign'))
  app.get('/db/campaign/-/overworld', mw.campaigns.fetchOverworld)

  app.post('/db/classroom', mw.classrooms.post)
  app.get('/db/classroom', mw.classrooms.fetchByCode, mw.classrooms.getByOwner)
  app.get('/db/classroom/:handle/levels', mw.classrooms.fetchAllLevels)
  app.get('/db/classroom/:handle/courses/:courseID/levels', mw.classrooms.fetchLevelsForCourse)
  app.post('/db/classroom/:handle/invite-members', mw.classrooms.inviteMembers)
  app.get('/db/classroom/:handle/member-sessions', mw.classrooms.fetchMemberSessions)
  app.get('/db/classroom/:handle/members', mw.classrooms.fetchMembers) # TODO: Use mw.auth?
  app.post('/db/classroom/:classroomID/members/:memberID/reset-password', mw.classrooms.setStudentPassword)
  app.post('/db/classroom/:anything/members', mw.auth.checkLoggedIn(), mw.classrooms.join)
  app.post('/db/classroom/:handle/update-courses', mw.classrooms.updateCourses)
  app.get('/db/classroom/:handle', mw.auth.checkLoggedIn()) # TODO: Finish migrating route, adding now so 401 is returned
  app.get('/db/classroom/-/playtimes', mw.auth.checkHasPermission(['admin']), mw.classrooms.fetchPlaytimes)
  app.get('/db/classroom/-/users', mw.auth.checkHasPermission(['admin']), mw.classrooms.getUsers)
  
  APIClient = require ('../models/APIClient')
  app.post('/db/api-clients', mw.auth.checkHasPermission(['admin']), mw.rest.post(APIClient))
  app.post('/db/api-clients/:handle/new-secret', mw.auth.checkHasPermission(['admin']), mw.apiClients.newSecret)

  CodeLog = require ('../models/CodeLog')
  app.post('/db/codelogs', mw.codelogs.post)
  app.get('/db/codelogs', mw.auth.checkHasPermission(['admin']), mw.rest.get(CodeLog))

  Course = require '../models/Course'
  app.get('/db/course', mw.courses.get(Course))
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
  app.get('/db/course_instance/:handle/levels/:levelOriginal/sessions/:sessionID/next', mw.courseInstances.fetchNextLevel)
  app.post('/db/course_instance/:handle/members', mw.auth.checkLoggedIn(), mw.courseInstances.addMembers)
  app.get('/db/course_instance/:handle/classroom', mw.auth.checkLoggedIn(), mw.courseInstances.fetchClassroom)
  app.get('/db/course_instance/:handle/course', mw.auth.checkLoggedIn(), mw.courseInstances.fetchCourse)
  app.get('/db/course_instance/:handle/my-course-level-sessions', mw.auth.checkLoggedIn(), mw.courseInstances.fetchMyCourseLevelSessions)
  
  EarnedAchievement = require '../models/EarnedAchievement'
  app.post('/db/earned_achievement', mw.auth.checkHasUser(), mw.earnedAchievements.post)
  
  Level = require '../models/Level'
  app.post('/db/level/names', mw.named.names(Level))
  app.post('/db/level/:handle', mw.auth.checkLoggedIn(), mw.versions.postNewVersion(Level, { hasPermissionsOrTranslations: 'artisan' })) # TODO: add /new-version to route like Article has
  app.get('/db/level/:handle/session', mw.auth.checkHasUser(), mw.levels.upsertSession)
  app.post('/db/level/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Level, 'level'))
  app.get('/db/level/:handle/patches', mw.patchable.patches(Level))
  app.get('/db/level/:handle/versions', mw.versions.versions(Level))
  app.get('/db/level/:handle/version/?(:version)?', mw.versions.getLatestVersion(Level))
  
  LevelComponent = require '../models/LevelComponent'
  app.post('/db/level.component/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(LevelComponent, 'level_component'))
  app.get('/db/level.component/:handle/patches', mw.patchable.patches(LevelComponent))

  LevelSystem = require '../models/LevelSystem'
  app.post('/db/level.system/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(LevelSystem, 'level_system'))
  app.get('/db/level.system/:handle/patches', mw.patchable.patches(LevelSystem))
  
  app.post('/db/subscription/-/subscribe_prepaid', mw.auth.checkLoggedIn(), mw.subscriptions.subscribeWithPrepaidCode, mw.logging.logErrors('Subscribe with prepaid code'))

  app.delete('/db/user/:handle', mw.users.removeFromClassrooms)
  app.get('/db/user', mw.users.fetchByGPlusID, mw.users.fetchByFacebookID)
  app.put('/db/user/-/become-student', mw.users.becomeStudent)
  app.put('/db/user/-/remain-teacher', mw.users.remainTeacher)
  app.get('/db/user/-/lead-priority', mw.auth.checkLoggedIn(), mw.users.getLeadPriority)
  app.post('/db/user/:userID/request-verify-email', mw.users.sendVerificationEmail)
  app.post('/db/user/:userID/verify/:verificationCode', mw.users.verifyEmailAddress) # TODO: Finalize URL scheme
  app.get('/db/user/-/students', mw.auth.checkHasPermission(['admin']), mw.users.getStudents)
  app.get('/db/user/-/teachers', mw.auth.checkHasPermission(['admin']), mw.users.getTeachers)
  app.post('/db/user/:handle/signup-with-facebook', mw.users.signupWithFacebook)
  app.post('/db/user/:handle/signup-with-gplus', mw.users.signupWithGPlus)
  app.post('/db/user/:handle/signup-with-password', mw.users.signupWithPassword)
  app.post('/db/user/:handle/destudent', mw.auth.checkHasPermission(['admin']), mw.users.destudent)
  app.post('/db/user/:handle/deteacher', mw.auth.checkHasPermission(['admin']), mw.users.deteacher)
  app.post('/db/user/:handle/check-for-new-achievement', mw.auth.checkLoggedIn(), mw.users.checkForNewAchievement)

  app.post('/db/patch', mw.patches.post)
  app.put('/db/patch/:handle/status', mw.auth.checkLoggedIn(), mw.patches.setStatus)
  
  Poll = require '../models/Poll'
  app.post('/db/poll/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(Poll, 'poll'))
  app.get('/db/poll/:handle/patches', mw.patchable.patches(Poll))
  
  app.get('/db/prepaid', mw.auth.checkLoggedIn(), mw.prepaids.fetchByCreator)
  app.get('/db/prepaid/-/active-school-licenses', mw.auth.checkHasPermission(['admin']), mw.prepaids.fetchActiveSchoolLicenses)
  app.get('/db/prepaid/-/active-schools', mw.auth.checkHasPermission(['admin']), mw.prepaids.fetchActiveSchools)
  app.post('/db/prepaid', mw.auth.checkHasPermission(['admin']), mw.prepaids.post)
  app.post('/db/starter-license-prepaid', mw.auth.checkLoggedIn(), mw.prepaids.purchaseStarterLicenses)
  app.post('/db/prepaid/:handle/redeemers', mw.prepaids.redeem)

  app.get '/db/products', require('./db/product').get

  ThangType = require '../models/ThangType'
  app.post('/db/thang.type/:handle/patch', mw.auth.checkLoggedIn(), mw.patchable.postPatch(ThangType, 'thang_type'))
  app.get('/db/thang.type/:handle/patches', mw.patchable.patches(ThangType))

  TrialRequest = require '../models/TrialRequest'
  app.get('/db/trial.request', mw.trialRequests.fetchByApplicant, mw.auth.checkHasPermission(['admin']), mw.rest.get(TrialRequest))
  app.post('/db/trial.request', mw.trialRequests.post)
  app.get('/db/trial.request/:handle', mw.auth.checkHasPermission(['admin']), mw.rest.getByHandle(TrialRequest))
  app.put('/db/trial.request/:handle', mw.auth.checkHasPermission(['admin']), mw.trialRequests.put)
  app.get('/db/trial.request/-/users', mw.auth.checkHasPermission(['admin']), mw.trialRequests.getUsers)

  app.all('/headers', mw.headers)
  
  app.get('/healthcheck', mw.healthcheck)
