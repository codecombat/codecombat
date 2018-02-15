locale = require 'locale/locale'
normalizeViewRoute = (path) -> if not _.string.startsWith(path, 'views/') then "views/#{path}" else path

go = ({path, load}, options) ->
  normedPath = normalizeViewRoute(path)
  f = -> @routeDirectly path, arguments, options
  _.assign(f, {path: normedPath, load})
  return f
  
# views with multiple routes
sharedViews = {
  VerifierView: {path: 'editor/verifier/VerifierView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/verifier/VerifierView')`}
  i18nVerifierView: {path: 'editor/verifier/i18nVerifierView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/verifier/i18nVerifierView')`}
  CommunityView: {path: 'CommunityView', load: -> `import(/* webpackChunkName: "CommunityView" */ 'views/CommunityView')` }
  LadderView: {path: 'ladder/LadderView', load: -> `import(/* webpackChunkName: "ladder" */ 'views/ladder/LadderView')`}
  CampaignView: {path: 'play/CampaignView', load: -> `import(/* webpackChunkName: "play" */ 'views/play/CampaignView')`}
  PremiumFeaturesView: {path: 'PremiumFeaturesView', load: -> `import(/* webpackChunkName: "PremiumFeaturesView" */ 'views/PremiumFeaturesView')`}
  RequestQuoteView: {path: 'teachers/RequestQuoteView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/RequestQuoteView')`}
  HomeView: {path: 'HomeView', load: -> `import(/* webpackChunkName: "HomeView" */ 'views/HomeView')`}
  SubscriptionView: {path: 'account/SubscriptionView', load: -> `import(/* webpackChunkName: "account" */ 'views/account/SubscriptionView')`}
  RestrictedToTeachersView: {path: 'teachers/RestrictedToTeachersView', load: -> `import(/* webpackChunkName: "RestrictedToTeachersView" */ 'views/teachers/RestrictedToTeachersView')`}
  RestrictedToStudentsView: {path: 'teachers/RestrictedToStudentsView', load: -> `import(/* webpackChunkName: "RestrictedToStudentsView" */ 'views/courses/RestrictedToStudentsView')`}
  CreateTeacherAccountView: go({ path: 'teachers/CreateTeacherAccountView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/CreateTeacherAccountView')`},
  ConvertToTeacherAccountView: go({ path: 'teachers/ConvertToTeacherAccountView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/ConvertToTeacherAccountView')`},
}

redirect = (path) -> ->
  delete window.alreadyLoadedView
  @navigate(path + document.location.search, { trigger: true, replace: true })

utils = require './utils'
ViewLoadTimer = require 'core/ViewLoadTimer'

module.exports = class CocoRouter extends Backbone.Router

  initialize: ->
    # http://nerds.airbnb.com/how-to-add-google-analytics-page-tracking-to-57536
    @bind 'route', @_trackPageView
    Backbone.Mediator.subscribe 'router:navigate', @onNavigate, @
    @initializeSocialMediaServices = _.once @initializeSocialMediaServices

  routes:
    '': ->
      if window.serverConfig.picoCTF
        return @routeDirectly 'play/CampaignView', ['picoctf'], {}
      if utils.getQueryVariable 'hour_of_code'
        delete window.alreadyLoadedView
        return @navigate "/play?hour_of_code=true", {trigger: true, replace: true}
      unless me.isAnonymous() or me.isStudent() or me.isTeacher() or me.isAdmin() or me.hasSubscription()
        delete window.alreadyLoadedView
        return @navigate "/premium", {trigger: true, replace: true}
      return @routeDirectly('HomeView', [])

    # AboutView chunk
    'about': go({path: 'AboutView', load: -> `import(/* webpackChunkName: "AboutView" */ 'views/AboutView')`})

    # account chunk
    'account': go({path: 'account/MainAccountView', load: -> `import(/* webpackChunkName: "account" */ 'views/account/MainAccountView')`}),
    'account/settings': go({path: 'account/AccountSettingsRootView', load: -> `import(/* webpackChunkName: "account" */ 'views/account/AccountSettingsRootView')`}),
    'account/unsubscribe': go({path: 'account/UnsubscribeView', load: -> `import(/* webpackChunkName: "account" */ 'views/account/UnsubscribeView')`}),
    'account/payments': go({path: 'account/PaymentsView', load: -> `import(/* webpackChunkName: "account" */ 'views/account/PaymentsView')`}),
    'account/subscription': go(sharedViews.SubscriptionView,  { redirectStudents: true, redirectTeachers: true }),
    'account/invoices': go({path: 'account/InvoicesView', load: -> `import(/* webpackChunkName: "account" */ 'views/account/InvoicesView')`}),
    'account/prepaid': go({path: 'account/PrepaidView', load: -> `import(/* webpackChunkName: "account" */ 'views/account/PrepaidView')`}),
    'il-signup': go({path: 'account/IsraelSignupView', load: -> `import(/* webpackChunkName: "account" */ 'views/account/IsraelSignupView')`}),

    # admin chunk
    'admin': go({path: 'admin/MainAdminView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/MainAdminView')`}),
    'admin/clas': go({path: 'admin/CLAsComponent', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/CLAsComponent')`}),
    'admin/classroom-content': go({path: 'admin/AdminClassroomContentView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/AdminClassroomContentView')`}),
    'admin/classroom-levels': go({path: 'admin/AdminClassroomLevelsComponent', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/AdminClassroomLevelsComponent')`}),
    'admin/classrooms-progress': go({path: 'admin/AdminClassroomsProgressView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/AdminClassroomsProgressView')`}),
    'admin/design-elements': go({path: 'admin/DesignElementsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/DesignElementsView')`}),
    'admin/files': go({path: 'admin/FilesComponent', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/FilesComponent')`}),
    'admin/analytics': go({path: 'admin/AnalyticsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/AnalyticsView')`}),
    'admin/analytics/subscriptions': go({path: 'admin/AnalyticsSubscriptionsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/AnalyticsSubscriptionsView')`}),
    'admin/level-hints': go({path: 'admin/AdminLevelHintsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/AdminLevelHintsView')`}),
    'admin/sub-cancellations': go({path: 'admin/AdminSubCancellationsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/AdminSubCancellationsView')`}),
    'admin/school-counts': go({path: 'admin/SchoolCountsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/SchoolCountsView')`}),
    'admin/school-licenses': go({path: 'admin/SchoolLicensesView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/SchoolLicensesView')`}),
    'admin/base': go({path: 'admin/BaseView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/BaseView')`}),
    'admin/demo-requests': go({path: 'admin/DemoRequestsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/DemoRequestsView')`}),
    'admin/trial-requests': go({path: 'admin/TrialRequestsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/TrialRequestsView')`}),
    'admin/user-code-problems': go({path: 'admin/UserCodeProblemsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/UserCodeProblemsView')`}),
    'admin/pending-patches': go({path: 'admin/PendingPatchesView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/PendingPatchesView')`}),
    'admin/codelogs': go({path: 'admin/CodeLogsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/CodeLogsView')`}),
    'admin/skipped-contacts': go({path: 'admin/SkippedContactsView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/SkippedContactsView')`}),
    'admin/outcomes-report-result': go({path: 'admin/OutcomeReportResultView', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/OutcomeReportResultView')`}),
    'admin/outcomes-report': go({path: 'admin/OutcomesReportComponent', load: -> `import(/* webpackChunkName: "admin" */ 'views/admin/OutcomesReportComponent')`}),

    # artisan chunk
    'artisans': go({path:'artisans/ArtisansView', load: -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/ArtisansView')`}),
    'artisans/level-tasks': go({path:'artisans/LevelTasksView', load: -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/LevelTasksView')`}),
    'artisans/solution-problems': go({path:'artisans/SolutionProblemsView', load: -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/SolutionProblemsView')`}),
    'artisans/level-concepts': go({path:'artisans/LevelConceptMap', load: -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/LevelConceptMap')`}),
    'artisans/level-guides': go({path:'artisans/LevelGuidesView', load: -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/LevelGuidesView')`}),
    'artisans/student-solutions': go({path:'artisans/StudentSolutionsView', load: -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/StudentSolutionsView')`}),
    'artisans/tag-test': go({path:'artisans/TagTestView', load: -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/TagTestView')`}),
    'artisans/thang-tasks': go({path:'artisans/ThangTasksView', load: -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/ThangTasksView')`}),

    'careers': => window.location.href = 'https://jobs.lever.co/codecombat'
    'Careers': => window.location.href = 'https://jobs.lever.co/codecombat'

    # CLAView chunk
    'cla': go({ path: 'CLAView', load: -> `import(/* webpackChunkName: "CLAView" */ 'views/CLAView')`})

    # clans chunk
    'clans': go({path: 'clans/ClansView', load: -> `import(/* webpackChunkName: "clans" */ 'views/clans/ClansView')`}),
    'clans/:clanID': go({path: 'clans/ClanDetailsView', load: -> `import(/* webpackChunkName: "clans" */ 'views/clans/ClanDetailsView')`}),

    # CommunityView chunk  
    'community': go(sharedViews.CommunityView)
    'editor': go(sharedViews.CommunityView)

    # contribute chunk
    'contribute': go({path: 'contribute/MainContributeView', load: -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/MainContributeView')` })
    'contribute/adventurer': go({path: 'contribute/AdventurerView', load: -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/AdventurerView')` })
    'contribute/ambassador': go({path: 'contribute/AmbassadorView', load: -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/AmbassadorView')` })
    'contribute/archmage': go({path: 'contribute/ArchmageView', load: -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/ArchmageView')` })
    'contribute/artisan': go({path: 'contribute/ArtisanView', load: -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/ArtisanView')` })
    'contribute/diplomat': go({path: 'contribute/DiplomatView', load: -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/DiplomatView')` })
    'contribute/scribe': go({path: 'contribute/ScribeView', load: -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/ScribeView')` })

    'courses': redirect('/students') # Redirected 9/3/16
    'Courses': redirect('/students') # Redirected 9/3/16
    'courses/students': redirect('/students') # Redirected 9/3/16
    'courses/teachers': redirect('/teachers/classes')
    'courses/purchase': redirect('/teachers/licenses')
    'courses/enroll(/:courseID)': redirect('/teachers/licenses')
    'courses/update-account': redirect('students/update-account') # Redirected 9/3/16
    'courses/:classroomID': -> @navigate("/students/#{arguments[0]}", {trigger: true, replace: true}) # Redirected 9/3/16
    'courses/:courseID/:courseInstanceID': -> @navigate("/students/#{arguments[0]}/#{arguments[1]}", {trigger: true, replace: true}) # Redirected 9/3/16

    'db/*path': 'routeToServer'

    # docs chunk
    'docs/components': go({path: 'editor/docs/ComponentsDocumentationView', load: -> `import(/* webpackChunkName: "docs" */ 'views/editor/docs/ComponentsDocumentationView')` })
    'docs/systems': go({path: 'editor/docs/SystemsDocumentationView', load: -> `import(/* webpackChunkName: "docs" */ 'views/editor/docs/SystemsDocumentationView')` })

    'editor/achievement': go({path: 'editor/achievement/AchievementSearchView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/achievement/AchievementSearchView')`})
    'editor/achievement/:articleID': go({path: 'editor/achievement/AchievementEditView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/achievement/AchievementEditView')`})
    'editor/article': go({path: 'editor/article/ArticleSearchView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/article/ArticleSearchView')`})
    'editor/article/preview': go({path: 'editor/article/ArticlePreviewView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/article/ArticlePreviewView')`})
    'editor/article/:articleID': go({path: 'editor/article/ArticleEditView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/article/ArticleEditView')`})
    'editor/level': go({path: 'editor/level/LevelSearchView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/level/LevelSearchView')`})
    'editor/level/:levelID': go({path: 'editor/level/LevelEditView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/level/LevelEditView')`})
    'editor/thang': go({path: 'editor/thang/ThangTypeSearchView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/thang/ThangTypeSearchView')`})
    'editor/thang/:thangID': go({path: 'editor/thang/ThangTypeEditView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/thang/ThangTypeEditView')`})
    'editor/campaign/:campaignID': go({path: 'editor/campaign/CampaignEditorView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/campaign/CampaignEditorView')`})
    'editor/poll': go({path: 'editor/poll/PollSearchView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/poll/PollSearchView')`})
    'editor/poll/:articleID': go({path: 'editor/poll/PollEditView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/poll/PollEditView')`})
    'editor/verifier': go(sharedViews.VerifierView)
    'editor/verifier/:levelID': go(sharedViews.VerifierView)
    'editor/i18n-verifier/:levelID': go(sharedViews.i18nVerifierView)
    'editor/i18n-verifier': go(sharedViews.i18nVerifierView)
    'editor/course': go({path: 'editor/course/CourseSearchView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/course/CourseSearchView')`})
    'editor/course/:courseID': go({path: 'editor/course/CourseEditView', load: -> `import(/* webpackChunkName: "editor" */ 'views/editor/course/CourseEditView')`})
    
    'file/*path': 'routeToServer'

    'github/*path': 'routeToServer'

    'hoc': -> @navigate "/play?hour_of_code=true", {trigger: true, replace: true}
    'home': go(sharedViews.HomeView)

    # i18n chunk
    'i18n': go({path: 'i18n/I18NHomeView', load: -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NHomeView')` })
    'i18n/thang/:handle': go({path: 'i18n/I18NEditThangTypeView', load: -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditThangTypeView')` })
    'i18n/component/:handle': go({path: 'i18n/I18NEditComponentView', load: -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditComponentView')` })
    'i18n/level/:handle': go({path: 'i18n/I18NEditLevelView', load: -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditLevelView')` })
    'i18n/achievement/:handle': go({path: 'i18n/I18NEditAchievementView', load: -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditAchievementView')` })
    'i18n/campaign/:handle': go({path: 'i18n/I18NEditCampaignView', load: -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditCampaignView')` })
    'i18n/poll/:handle': go({path: 'i18n/I18NEditPollView', load: -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditPollView')` })
    'i18n/course/:handle': go({path: 'i18n/I18NEditCourseView', load: -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditCourseView')` })
    'i18n/product/:handle': go({path: 'i18n/I18NEditProductView', load: -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditProductView')` })

    # LegalView chunk
    'legal': go({path: 'LegalView', load: -> `import(/* webpackChunkName: "LegalView" */ 'views/LegalView')`})

    'logout': 'logout'

    'paypal/subscribe-callback': go(sharedViews.CampaignView)
    'paypal/cancel-callback': go(sharedViews.SubscriptionView)

    # ladder chunk
    'play/ladder/:levelID/:leagueType/:leagueID': go(sharedViews.LadderView)
    'play/ladder/:levelID': go(sharedViews.LadderView)
    'play/ladder': go({path: 'ladder/MainLadderView', load: -> `import(/* webpackChunkName: "ladder" */ 'views/ladder/MainLadderView')`})

    # play chunk
    'play(/)': go(sharedViews.CampaignView, { redirectStudents: true, redirectTeachers: true }) # extra slash is to get Facebook app to work
    'play/level/:levelID': go({path: 'play/level/PlayLevelView', load: -> `import(/* webpackChunkName: "play" */ 'views/play/level/PlayLevelView')` })
    'play/game-dev-level/:sessionID': go({path: 'play/level/PlayGameDevLevelView', load: -> `import(/* webpackChunkName: "play" */ 'views/play/level/PlayGameDevLevelView')` })
    'play/web-dev-level/:sessionID': go({path: 'play/level/PlayWebDevLevelView', load: -> `import(/* webpackChunkName: "play" */ 'views/play/level/PlayWebDevLevelView')` })
    'play/game-dev-level/:levelID/:sessionID': (levelID, sessionID) ->
      @navigate("play/game-dev-level/#{sessionID}", { trigger: true, replace: true })
    'play/web-dev-level/:levelID/:sessionID': (levelID, sessionID) ->
      @navigate("play/web-dev-level/#{sessionID}", { trigger: true, replace: true })
    'play/spectate/:levelID': go({path: 'play/SpectateView', load: -> `import(/* webpackChunkName: "play" */ 'views/play/SpectateView')` })
    'play/:map': go(sharedViews.CampaignView)

    # PremiumFeaturesView chunk
    'premium': go(sharedViews.PremiumFeaturesView)
    'Premium': go(sharedViews.PremiumFeaturesView)

    'preview': go(sharedViews.HomeView)

    # PrivacyView chunk
    'privacy': go({path: 'PrivacyView', load: -> `import(/* webpackChunkName: "PrivacyView" */ 'views/PrivacyView')`})

    'schools': go(sharedViews.HomeView)
    'seen': go(sharedViews.HomeView)
    'SEEN': go(sharedViews.HomeView)

    # courses chunk
    'students': go({path: 'courses/CoursesView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/CoursesView')`}, { redirectTeachers: true })
    'students/update-account': go({path: 'courses/CoursesUpdateAccountView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/CoursesUpdateAccountView')`}, { redirectTeachers: true })
    'students/project-gallery/:courseInstanceID': go({path: 'courses/ProjectGalleryView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/ProjectGalleryView')`})
    'students/assessments/:classroomID': go({path: 'courses/StudentAssessmentsView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/StudentAssessmentsView')`})
    'students/:classroomID': go({path: 'courses/ClassroomView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/ClassroomView')`}, { redirectTeachers: true, studentsOnly: true })
    'students/:courseID/:courseInstanceID': go({path: 'courses/CourseDetailsView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/CourseDetailsView')`}, { redirectTeachers: true, studentsOnly: true })
    'teachers': redirect('/teachers/classes')
    'teachers/classes': go({path: 'courses/TeacherClassesView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/TeacherClassesView')`}, { redirectStudents: true, teachersOnly: true })
    'teachers/classes/:classroomID': go({path: 'courses/TeacherClassView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/TeacherClassView')`}, { redirectStudents: true, teachersOnly: true })
    'teachers/courses': go({path: 'courses/TeacherCoursesView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/TeacherCoursesView')`}, { redirectStudents: true })
    'teachers/enrollments': redirect('/teachers/licenses')
    'teachers/licenses': go({path: 'courses/EnrollmentsView', load: -> `import(/* webpackChunkName: "courses" */ 'views/courses/EnrollmentsView')`}, { redirectStudents: true, teachersOnly: true })

    # teachers chunk
    'teachers/classes/:classroomID/:studentID': go({path: 'teachers/TeacherStudentView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/TeacherStudentView')`}, { redirectStudents: true, teachersOnly: true })
    'teachers/course-solution/:courseID/:language': go({path: 'teachers/TeacherCourseSolutionView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/TeacherCourseSolutionView')`}, { redirectStudents: true })
    'teachers/demo': go(sharedViews.RequestQuoteView, { redirectStudents: true })
    'teachers/freetrial': go(sharedViews.RequestQuoteView, { redirectStudents: true })
    'teachers/quote': redirect('/teachers/demo')
    'teachers/resources': go({path: 'teachers/ResourceHubView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/ResourceHubView')`}, { redirectStudents: true })
    'teachers/resources/ap-cs-principles': go({path: 'teachers/ApCsPrinciplesView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/ApCsPrinciplesView')`}, { redirectStudents: true })
    'teachers/resources/:name': go({path: 'teachers/MarkdownResourceView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/MarkdownResourceView')`}, { redirectStudents: true })
    'teachers/signup': ->
      return @routeDirectly('teachers/CreateTeacherAccountView', []) if me.isAnonymous()
      return @navigate('/students', {trigger: true, replace: true}) if me.isStudent() and not me.isAdmin()
      @navigate('/teachers/update-account', {trigger: true, replace: true})
    'teachers/starter-licenses': go({path: 'teachers/StarterLicenseUpsellView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/StarterLicenseUpsellView')`}, { redirectStudents: true, teachersOnly: true })
    'teachers/update-account': ->
      return @navigate('/teachers/signup', {trigger: true, replace: true}) if me.isAnonymous()
      return @navigate('/students', {trigger: true, replace: true}) if me.isStudent() and not me.isAdmin()
      @routeDirectly('teachers/ConvertToTeacherAccountView', [])
    'apcsp(/*subpath)': go({path: 'teachers/DynamicAPCSPView', load: -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/DynamicAPCSPView')`})

    # TestView chunk
    'test(/*subpath)': go({path: 'TestView', load: -> `import(/* webpackChunkName: "TestView" */ 'views/TestView')`,})

    'identify': go({path: 'user/IdentifyView', load: -> `import(/* webpackChunkName: "user" */ 'views/user/IdentifyView')` })
    'user/:slugOrID': go({path: 'user/MainUserView', load: -> `import(/* webpackChunkName: "user" */ 'views/user/MainUserView')` })
    'user/:userID/verify/:verificationCode': go({path: 'user/EmailVerifiedView', load: -> `import(/* webpackChunkName: "user" */ 'views/user/EmailVerifiedView')` })

    '*name/': 'removeTrailingSlash'
    
    # NotFoundView chunk
    '*name': go({path: 'NotFoundView', load: -> `import(/* webpackChunkName: "NotFoundView" */ 'views/NotFoundView')`})

  routeToServer: (e) ->
    window.location.href = window.location.href

  removeTrailingSlash: (e) ->
    @navigate e, {trigger: true}
    
  loadPath: (path) ->
    path = normalizeViewRoute(path)
    allRoutes = _.assign({}, _.values(@routes), _.values(sharedViews))
    route = _.find(allRoutes, { path }) # TODO: Make sure this works
    if not route
      throw new Error('route not found', { path, route })
    console.log 'found route', route, route.path, route.load
    return route.load()

  routeDirectly: (path, args=[], options={}) ->
    if window.alreadyLoadedView
      path = window.alreadyLoadedView

    @viewLoad = new ViewLoadTimer() unless options.recursive
    if options.redirectStudents and me.isStudent() and not me.isAdmin()
      return @redirectHome()
    if options.redirectTeachers and me.isTeacher() and not me.isAdmin()
      return @redirectHome()
    if options.teachersOnly and not (me.isTeacher() or me.isAdmin())
      return @routeDirectly('teachers/RestrictedToTeachersView')
    if options.studentsOnly and not (me.isStudent() or me.isAdmin())
      return @routeDirectly('courses/RestrictedToStudentsView')
    leavingMessage = _.result(window.currentView, 'onLeaveMessage')
    if leavingMessage
      if not confirm(leavingMessage)
        return @navigate(this.path, {replace: true})
      else
        window.currentView.onLeaveMessage = _.noop # to stop repeat confirm calls

    # TODO: Combine these two?
    if features.playViewsOnly and not (_.string.startsWith(document.location.pathname, '/play') or document.location.pathname is '/admin')
      delete window.alreadyLoadedView
      return @navigate('/play', { trigger: true, replace: true })
    if features.playOnly and not /^(views)?\/?play/.test(path)
      delete window.alreadyLoadedView
      path = 'views/play/CampaignView'

    Promise.all([
      @loadPath(path), # Load the view file
      # The locale load is already initialized by `application`, just need the promise
      locale.load(me.get('preferredLanguage', true))
    ]).then ([ViewClass]) =>
      if _.isFunction(ViewClass.default)
        ViewClass = @wrapVueComponent(ViewClass.default)
      return go('NotFoundView') if not ViewClass
      view = new ViewClass(options, args...)  # options, then any path fragment args
      view.render()
      if window.alreadyLoadedView
        console.log "Need to merge view"
        delete window.alreadyLoadedView
        @mergeView(view)
      else
        @openView(view)

      @viewLoad.setView(view)
      @viewLoad.record()
    .catch (err) ->
      console.log err

  wrapVueComponent: (VueComponent) ->
    RootComponent = require 'views/core/RootComponent'
    baseFlatTemplate = require 'templates/base-flat'
    class ComponentWrapper extends RootComponent
      template: baseFlatTemplate
      VueComponent: VueComponent
    return ComponentWrapper

  redirectHome: ->
    delete window.alreadyLoadedView
    homeUrl = switch
      when me.isStudent() then '/students'
      when me.isTeacher() then '/teachers'
      else '/'
    @navigate(homeUrl, {trigger: true, replace: true})

  openView: (view) ->
    @closeCurrentView()
    $('#page-container').empty().append view.el
    @activateTab()
    @didOpenView view

  mergeView: (view) ->
    unless view.mergeWithPrerendered?
      return @openView(view)

    target = $('#page-container>div')
    view.mergeWithPrerendered target
    view.setElement target[0]
    @didOpenView view

  didOpenView: (view) ->
    window.currentView = view
    view.afterInsert()
    view.didReappear()
    @path = document.location.pathname + document.location.search
    console.log "Did-Load-Route"
    @trigger 'did-load-route'

  closeCurrentView: ->
    if window.currentView?.reloadOnClose
      return document.location.reload()
    window.currentModal?.hide?()
    return unless window.currentView?
    window.currentView.modalClosed()
    window.currentView.destroy()
    $('.popover').popover 'hide'
    $('#flying-focus').css({top: 0, left: 0}) # otherwise it might make the page unnecessarily tall
    _.delay (->
      $('html')[0].scrollTop = 0
      $('body')[0].scrollTop = 0
    ), 10

  initializeSocialMediaServices: ->
    return if application.testing or application.demoing
    application.facebookHandler.loadAPI()
    application.gplusHandler.loadAPI()
    require('core/services/twitter')()

  renderSocialButtons: =>
    # TODO: Refactor remaining services to Handlers, use loadAPI success callback
    @initializeSocialMediaServices()
    $('.share-buttons, .partner-badges').addClass('fade-in').delay(10000).removeClass('fade-in', 5000)
    application.facebookHandler.renderButtons()
    application.gplusHandler.renderButtons()
    twttr?.widgets?.load?()

  activateTab: ->
    base = _.string.words(document.location.pathname[1..], '/')[0]
    $("ul.nav li.#{base}").addClass('active')

  _trackPageView: ->
    window.tracker?.trackPageView()

  onNavigate: (e, recursive=false) ->
    @viewLoad = new ViewLoadTimer() unless recursive
    if _.isString e.viewClass
      @loadPath(e.viewClass).then (viewClass) =>
        @onNavigate(_.assign({}, e, {viewClass}), true)
      return

    manualView = e.view or e.viewClass
    if (e.route is document.location.pathname) and not manualView
      return document.location.reload()
    @navigate e.route, {trigger: not manualView}
    @_trackPageView()
    return unless manualView
    if e.viewClass
      args = e.viewArgs or []
      view = new e.viewClass(args...)
      view.render()
      @openView view
      @viewLoad.setView(view)
    else
      @openView e.view
      @viewLoad.setView(e.view)
    @viewLoad.record()

  navigate: (fragment, options) ->
    super fragment, options
    Backbone.Mediator.publish 'router:navigated', route: fragment

  reload: ->
    document.location.reload()

  logout: ->
    me.logout()
    @navigate('/', { trigger: true })
