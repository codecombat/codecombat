mw = require '../middleware'

module.exports.setup = (app) ->
  
  passport = require('passport')
  app.post('/auth/login', passport.authenticate('local'), mw.auth.afterLogin)
  app.post('/auth/login-facebook', mw.auth.loginByFacebook, mw.auth.afterLogin)
  app.post('/auth/login-gplus', mw.auth.loginByGPlus, mw.auth.afterLogin)
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
  app.post('/db/article/:handle/watchers', mw.patchable.joinWatchers(Article))
  app.delete('/db/article/:handle/watchers', mw.patchable.leaveWatchers(Article))

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
  app.get('/db/classroom/:handle', mw.auth.checkLoggedIn()) # TODO: Finish migrating route, adding now so 401 is returned
  app.get('/db/classroom/-/users', mw.auth.checkHasPermission(['admin']), mw.classrooms.getUsers)

  CodeLog = require ('../models/CodeLog')
  app.post('/db/codelogs', mw.codelogs.post)
  app.get('/db/codelogs', mw.auth.checkHasPermission(['admin']), mw.rest.get(CodeLog))

  Course = require '../models/Course'
  app.get('/db/course', mw.rest.get(Course))
  app.get('/db/course/:handle', mw.rest.getByHandle(Course))
  app.get('/db/course/:handle/levels/:levelOriginal/next', mw.courses.fetchNextLevel)

  app.get('/db/course_instance/-/non-hoc', mw.auth.checkHasPermission(['admin']), mw.courseInstances.fetchNonHoc)
  app.post('/db/course_instance/-/recent', mw.auth.checkHasPermission(['admin']), mw.courseInstances.fetchRecent)
  app.get('/db/course_instance/:handle/levels/:levelOriginal/sessions/:sessionID/next', mw.courseInstances.fetchNextLevel)
  app.post('/db/course_instance/:handle/members', mw.auth.checkLoggedIn(), mw.courseInstances.addMembers)
  app.get('/db/course_instance/:handle/classroom', mw.auth.checkLoggedIn(), mw.courseInstances.fetchClassroom)

  app.put('/db/user/:handle', mw.users.resetEmailVerifiedFlag)
  app.delete('/db/user/:handle', mw.users.removeFromClassrooms)
  app.get('/db/user', mw.users.fetchByGPlusID, mw.users.fetchByFacebookID)
  app.put('/db/user/-/become-student', mw.users.becomeStudent)
  app.put('/db/user/-/remain-teacher', mw.users.remainTeacher)
  app.post('/db/user/:userID/request-verify-email', mw.users.sendVerificationEmail)
  app.post('/db/user/:userID/verify/:verificationCode', mw.users.verifyEmailAddress) # TODO: Finalize URL scheme
  app.get('/db/level/:handle/session', mw.auth.checkHasUser(), mw.levels.upsertSession)
  app.get('/db/user/-/students', mw.auth.checkHasPermission(['admin']), mw.users.getStudents)
  app.get('/db/user/-/teachers', mw.auth.checkHasPermission(['admin']), mw.users.getTeachers)
  app.post('/db/user/:handle/signup-with-facebook', mw.users.signupWithFacebook)
  app.post('/db/user/:handle/signup-with-gplus', mw.users.signupWithGPlus)
  app.post('/db/user/:handle/signup-with-password', mw.users.signupWithPassword)
  
  app.get('/db/prepaid', mw.auth.checkLoggedIn(), mw.prepaids.fetchByCreator)
  app.post('/db/prepaid', mw.auth.checkHasPermission(['admin']), mw.prepaids.post)
  app.post('/db/prepaid/:handle/redeemers', mw.prepaids.redeem)

  app.get '/db/products', require('./db/product').get

  TrialRequest = require '../models/TrialRequest'
  app.get('/db/trial.request', mw.trialRequests.fetchByApplicant, mw.auth.checkHasPermission(['admin']), mw.rest.get(TrialRequest))
  app.post('/db/trial.request', mw.trialRequests.post)
  app.get('/db/trial.request/:handle', mw.auth.checkHasPermission(['admin']), mw.rest.getByHandle(TrialRequest))
  app.put('/db/trial.request/:handle', mw.auth.checkHasPermission(['admin']), mw.trialRequests.put)
  app.get('/db/trial.request/-/users', mw.auth.checkHasPermission(['admin']), mw.trialRequests.getUsers)

  app.get('/healthcheck', mw.healthcheck)
