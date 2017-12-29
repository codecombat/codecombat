locale = require 'locale/locale'

go = (path, options) -> -> @routeDirectly path, arguments, options

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

    'about': go('AboutView')

    'account': go('account/MainAccountView')
    'account/settings': go('account/AccountSettingsRootView')
    'account/unsubscribe': go('account/UnsubscribeView')
    'account/payments': go('account/PaymentsView')
    'account/subscription': go('account/SubscriptionView', { redirectStudents: true, redirectTeachers: true })
    'account/invoices': go('account/InvoicesView')
    'account/prepaid': go('account/PrepaidView')

    'admin': go('admin/MainAdminView')
    'admin/clas': go('admin/CLAsComponent')
    'admin/classroom-content': go('admin/AdminClassroomContentView')
    'admin/classroom-levels': go('admin/AdminClassroomLevelsComponent')
    'admin/classrooms-progress': go('admin/AdminClassroomsProgressView')
    'admin/design-elements': go('admin/DesignElementsView')
    'admin/files': go('admin/FilesComponent')
    'admin/analytics': go('admin/AnalyticsView')
    'admin/analytics/subscriptions': go('admin/AnalyticsSubscriptionsView')
    'admin/level-hints': go('admin/AdminLevelHintsView')
    'admin/level-sessions': go('admin/LevelSessionsView')
    'admin/school-counts': go('admin/SchoolCountsView')
    'admin/school-licenses': go('admin/SchoolLicensesView')
    'admin/base': go('admin/BaseView')
    'admin/demo-requests': go('admin/DemoRequestsView')
    'admin/trial-requests': go('admin/TrialRequestsView')
    'admin/user-code-problems': go('admin/UserCodeProblemsView')
    'admin/pending-patches': go('admin/PendingPatchesView')
    'admin/codelogs': go('admin/CodeLogsView')
    'admin/skipped-contacts': go('admin/SkippedContactsView')
    'admin/outcomes-report-result': go('admin/OutcomeReportResultView')
    'admin/outcomes-report': go('admin/OutcomesReportComponent')

    'apcsp(/*subpath)': go('teachers/DynamicAPCSPView')

    'artisans': go('artisans/ArtisansView')

    'artisans/level-tasks': go('artisans/LevelTasksView')
    'artisans/solution-problems': go('artisans/SolutionProblemsView')
    'artisans/thang-tasks': go('artisans/ThangTasksView')
    'artisans/level-concepts': go('artisans/LevelConceptMap')
    'artisans/level-guides': go('artisans/LevelGuidesView')
    'artisans/student-solutions': go('artisans/StudentSolutionsView')
    'artisans/tag-test': go('artisans/TagTestView')

    'careers': => window.location.href = 'https://jobs.lever.co/codecombat'
    'Careers': => window.location.href = 'https://jobs.lever.co/codecombat'

    'cla': go('CLAView')

    'clans': go('clans/ClansView')
    'clans/:clanID': go('clans/ClanDetailsView')

    'community': go('CommunityView')

    'contribute': go('contribute/MainContributeView')
    'contribute/adventurer': go('contribute/AdventurerView')
    'contribute/ambassador': go('contribute/AmbassadorView')
    'contribute/archmage': go('contribute/ArchmageView')
    'contribute/artisan': go('contribute/ArtisanView')
    'contribute/diplomat': go('contribute/DiplomatView')
    'contribute/scribe': go('contribute/ScribeView')

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
    'docs/components': go('docs/ComponentsDocumentationView')
    'docs/systems': go('docs/SystemsDocumentationView')

    'editor': go('CommunityView')

    'editor/achievement': go('editor/achievement/AchievementSearchView')
    'editor/achievement/:articleID': go('editor/achievement/AchievementEditView')
    'editor/article': go('editor/article/ArticleSearchView')
    'editor/article/preview': go('editor/article/ArticlePreviewView')
    'editor/article/:articleID': go('editor/article/ArticleEditView')
    'editor/level': go('editor/level/LevelSearchView')
    'editor/level/:levelID': go('editor/level/LevelEditView')
    'editor/thang': go('editor/thang/ThangTypeSearchView')
    'editor/thang/:thangID': go('editor/thang/ThangTypeEditView')
    'editor/campaign/:campaignID': go('editor/campaign/CampaignEditorView')
    'editor/poll': go('editor/poll/PollSearchView')
    'editor/poll/:articleID': go('editor/poll/PollEditView')
    'editor/thang-tasks': go('editor/ThangTasksView')
    'editor/verifier': go('editor/verifier/VerifierView')
    'editor/verifier/:levelID': go('editor/verifier/VerifierView')
    'editor/i18n-verifier/:levelID': go('editor/verifier/i18nVerifierView')
    'editor/i18n-verifier': go('editor/verifier/i18nVerifierView')
    'editor/course': go('editor/course/CourseSearchView')
    'editor/course/:courseID': go('editor/course/CourseEditView')

    'file/*path': 'routeToServer'

    'github/*path': 'routeToServer'

    'hoc': -> @navigate "/play?hour_of_code=true", {trigger: true, replace: true}
    'home': go('HomeView')

    'i18n': go('i18n/I18NHomeView')
    'i18n/thang/:handle': go('i18n/I18NEditThangTypeView')
    'i18n/component/:handle': go('i18n/I18NEditComponentView')
    'i18n/level/:handle': go('i18n/I18NEditLevelView')
    'i18n/achievement/:handle': go('i18n/I18NEditAchievementView')
    'i18n/campaign/:handle': go('i18n/I18NEditCampaignView')
    'i18n/poll/:handle': go('i18n/I18NEditPollView')
    'i18n/course/:handle': go('i18n/I18NEditCourseView')
    'i18n/product/:handle': go('i18n/I18NEditProductView')

    'identify': go('user/IdentifyView')
    'il-signup': go('account/IsraelSignupView')

    'legal': go('LegalView')

    'logout': 'logout'

    'paypal/subscribe-callback': go('play/CampaignView')
    'paypal/cancel-callback': go('account/SubscriptionView')

    'play(/)': go('play/CampaignView', { redirectStudents: true, redirectTeachers: true }) # extra slash is to get Facebook app to work
    'play/ladder/:levelID/:leagueType/:leagueID': go('ladder/LadderView')
    'play/ladder/:levelID': go('ladder/LadderView')
    'play/ladder': go('ladder/MainLadderView')
    'play/level/:levelID': go('play/level/PlayLevelView')
    'play/game-dev-level/:sessionID': go('play/level/PlayGameDevLevelView')
    'play/web-dev-level/:sessionID': go('play/level/PlayWebDevLevelView')
    'play/game-dev-level/:levelID/:sessionID': (levelID, sessionID) ->
      @navigate("play/game-dev-level/#{sessionID}", { trigger: true, replace: true })
    'play/web-dev-level/:levelID/:sessionID': (levelID, sessionID) ->
      @navigate("play/web-dev-level/#{sessionID}", { trigger: true, replace: true })
    'play/spectate/:levelID': go('play/SpectateView')
    'play/:map': go('play/CampaignView')

    'premium': go('PremiumFeaturesView')
    'Premium': go('PremiumFeaturesView')

    'preview': go('HomeView')

    'privacy': go('PrivacyView')

    'schools': go('HomeView')
    'seen': go('HomeView')
    'SEEN': go('HomeView')

    'sunburst': go('HomeView')

    'students': go('courses/CoursesView', { redirectTeachers: true })
    'students/update-account': go('courses/CoursesUpdateAccountView', { redirectTeachers: true })
    'students/project-gallery/:courseInstanceID': go('courses/ProjectGalleryView')
    'students/assessments/:classroomID': go('courses/StudentAssessmentsView')
    'students/:classroomID': go('courses/ClassroomView', { redirectTeachers: true, studentsOnly: true })
    'students/:courseID/:courseInstanceID': go('courses/CourseDetailsView', { redirectTeachers: true, studentsOnly: true })
    'teachers': redirect('/teachers/classes')
    'teachers/classes': go('courses/TeacherClassesView', { redirectStudents: true, teachersOnly: true })
    'teachers/classes/:classroomID/:studentID': go('teachers/TeacherStudentView', { redirectStudents: true, teachersOnly: true })
    'teachers/classes/:classroomID': go('courses/TeacherClassView', { redirectStudents: true, teachersOnly: true })
    'teachers/courses': go('courses/TeacherCoursesView', { redirectStudents: true })
    'teachers/course-solution/:courseID/:language': go('teachers/TeacherCourseSolutionView', { redirectStudents: true })
    'teachers/demo': go('teachers/RequestQuoteView', { redirectStudents: true })
    'teachers/enrollments': redirect('/teachers/licenses')
    'teachers/licenses': go('courses/EnrollmentsView', { redirectStudents: true, teachersOnly: true })
    'teachers/freetrial': go('teachers/RequestQuoteView', { redirectStudents: true })
    'teachers/quote': redirect('/teachers/demo')
    'teachers/resources': go('teachers/ResourceHubView', { redirectStudents: true })
    'teachers/resources/ap-cs-principles': go('teachers/ApCsPrinciplesView', { redirectStudents: true })
    'teachers/resources/:name': go('teachers/MarkdownResourceView', { redirectStudents: true })
    'teachers/signup': ->
      return @routeDirectly('teachers/CreateTeacherAccountView', []) if me.isAnonymous()
      return @navigate('/students', {trigger: true, replace: true}) if me.isStudent() and not me.isAdmin()
      @navigate('/teachers/update-account', {trigger: true, replace: true})
    'teachers/starter-licenses': go('teachers/StarterLicenseUpsellView', { redirectStudents: true, teachersOnly: true })
    'teachers/update-account': ->
      return @navigate('/teachers/signup', {trigger: true, replace: true}) if me.isAnonymous()
      return @navigate('/students', {trigger: true, replace: true}) if me.isStudent() and not me.isAdmin()
      @routeDirectly('teachers/ConvertToTeacherAccountView', [])

    'test(/*subpath)': go('TestView')

    'user/:slugOrID': go('user/MainUserView')
    'user/:userID/verify/:verificationCode': go('user/EmailVerifiedView')

    '*name/': 'removeTrailingSlash'
    '*name': go('NotFoundView')

  routeToServer: (e) ->
    window.location.href = window.location.href

  removeTrailingSlash: (e) ->
    @navigate e, {trigger: true}

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
      path = 'play/CampaignView'

    path = "views/#{path}" if not _.string.startsWith(path, 'views/')
    Promise.all([
      viewMap[path](), # Load the view file
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
      viewMap[e.viewClass]().then (viewClass) =>
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


# Chunks
# TODO: automatically chunk by folder?
viewMap = {
  'views/AboutView': -> `import(/* webpackChunkName: "AboutView" */ 'views/AboutView')`,

  'views/HomeView': -> `import(/* webpackChunkName: "HomeView" */ 'views/HomeView')`,

  'views/account/MainAccountView': -> `import(/* webpackChunkName: "account" */ 'views/account/MainAccountView')`,
  'views/account/AccountSettingsRootView': -> `import(/* webpackChunkName: "account" */ 'views/account/AccountSettingsRootView')`,
  'views/account/UnsubscribeView': -> `import(/* webpackChunkName: "account" */ 'views/account/UnsubscribeView')`,
  'views/account/PaymentsView': -> `import(/* webpackChunkName: "account" */ 'views/account/PaymentsView')`,
  'views/account/SubscriptionView': -> `import(/* webpackChunkName: "account" */ 'views/account/SubscriptionView')`,
  'views/account/InvoicesView': -> `import(/* webpackChunkName: "account" */ 'views/account/InvoicesView')`,
  'views/account/PrepaidView': -> `import(/* webpackChunkName: "account" */ 'views/account/PrepaidView')`,
  'views/account/IsraelSignupView': -> `import(/* webpackChunkName: "account" */ 'views/account/IsraelSignupView')`,

  'views/admin/MainAdminView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/MainAdminView')`,
  'views/admin/CLAsComponent': -> `import(/* webpackChunkName: "admin" */ 'views/admin/CLAsComponent')`,
  'views/admin/AdminClassroomContentView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/AdminClassroomContentView')`,
  'views/admin/AdminClassroomLevelsComponent': -> `import(/* webpackChunkName: "admin" */ 'views/admin/AdminClassroomLevelsComponent')`,
  'views/admin/AdminClassroomsProgressView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/AdminClassroomsProgressView')`,
  'views/admin/FilesComponent': -> `import(/* webpackChunkName: "admin" */ 'views/admin/FilesComponent')`,
  'views/admin/AnalyticsView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/AnalyticsView')`,
  'views/admin/AnalyticsSubscriptionsView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/AnalyticsSubscriptionsView')`,
  'views/admin/AdminLevelHintsView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/AdminLevelHintsView')`,
  'views/admin/SchoolCountsView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/SchoolCountsView')`,
  'views/admin/SchoolLicensesView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/SchoolLicensesView')`,
  'views/admin/BaseView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/BaseView')`,
  'views/admin/DemoRequestsView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/DemoRequestsView')`,
  'views/admin/TrialRequestsView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/TrialRequestsView')`,
  'views/admin/UserCodeProblemsView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/UserCodeProblemsView')`,
  'views/admin/PendingPatchesView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/PendingPatchesView')`,
  'views/admin/CodeLogsView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/CodeLogsView')`,
  'views/admin/SkippedContactsView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/SkippedContactsView')`,
  'views/admin/OutcomeReportResultView': -> `import(/* webpackChunkName: "admin" */ 'views/admin/OutcomeReportResultView')`,
  'views/admin/OutcomesReportComponent': -> `import(/* webpackChunkName: "admin" */ 'views/admin/OutcomesReportComponent')`,

  'views/artisans/ArtisansView': -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/ArtisansView')`,
  'views/artisans/LevelTasksView': -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/LevelTasksView')`,
  'views/artisans/SolutionProblemsView': -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/SolutionProblemsView')`,
  'views/artisans/LevelConceptMap': -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/LevelConceptMap')`,
  'views/artisans/LevelGuidesView': -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/LevelGuidesView')`,
  'views/artisans/StudentSolutionsView': -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/StudentSolutionsView')`,
  'views/artisans/TagTestView': -> `import(/* webpackChunkName: "artisans" */ 'views/artisans/TagTestView')`,

  'views/CLAView': -> `import(/* webpackChunkName: "CLAView" */ 'views/CLAView')`,

  'views/clans/ClansView': -> `import(/* webpackChunkName: "clans" */ 'views/clans/ClansView')`,
  'views/clans/ClanDetailsView': -> `import(/* webpackChunkName: "clans" */ 'views/clans/ClanDetailsView')`,

  'views/CommunityView': -> `import(/* webpackChunkName: "CommunityView" */ 'views/CommunityView')`,

  'views/contribute/MainContributeView': -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/MainContributeView')`,
  'views/contribute/AdventurerView': -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/AdventurerView')`,
  'views/contribute/AmbassadorView': -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/AmbassadorView')`,
  'views/contribute/ArchmageView': -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/ArchmageView')`,
  'views/contribute/ArtisanView': -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/ArtisanView')`,
  'views/contribute/DiplomatView': -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/DiplomatView')`,
  'views/contribute/ScribeView': -> `import(/* webpackChunkName: "contribute" */ 'views/contribute/ScribeView')`,

  'views/courses/CoursesView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/CoursesView')`,
  'views/courses/CoursesUpdateAccountView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/CoursesUpdateAccountView')`,
  'views/courses/ProjectGalleryView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/ProjectGalleryView')`,
  'views/courses/StudentAssessmentsView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/StudentAssessmentsView')`,
  'views/courses/ClassroomView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/ClassroomView')`,
  'views/courses/CourseDetailsView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/CourseDetailsView')`,
  'views/courses/TeacherClassesView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/TeacherClassesView')`,
  'views/courses/TeacherClassView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/TeacherClassView')`,
  'views/courses/TeacherCoursesView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/TeacherCoursesView')`,
  'views/courses/EnrollmentsView': -> `import(/* webpackChunkName: "courses" */ 'views/courses/EnrollmentsView')`,

  'views/editor/achievement/AchievementSearchView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/achievement/AchievementSearchView')`,
  'views/editor/achievement/AchievementEditView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/achievement/AchievementEditView')`,
  'views/editor/article/ArticleSearchView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/article/ArticleSearchView')`,
  'views/editor/article/ArticlePreviewView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/article/ArticlePreviewView')`,
  'views/editor/article/ArticleEditView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/article/ArticleEditView')`,
  'views/editor/level/LevelSearchView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/level/LevelSearchView')`,
  'views/editor/level/LevelEditView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/level/LevelEditView')`,
  'views/editor/thang/ThangTypeSearchView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/thang/ThangTypeSearchView')`,
  'views/editor/thang/ThangTypeEditView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/thang/ThangTypeEditView')`,
  'views/editor/campaign/CampaignEditorView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/campaign/CampaignEditorView')`,
  'views/editor/poll/PollSearchView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/poll/PollSearchView')`,
  'views/editor/poll/PollEditView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/poll/PollEditView')`,
  'views/editor/verifier/VerifierView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/verifier/VerifierView')`,
  'views/editor/verifier/i18nVerifierView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/verifier/i18nVerifierView')`,
  'views/editor/course/CourseSearchView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/course/CourseSearchView')`,
  'views/editor/course/CourseEditView': -> `import(/* webpackChunkName: "editor" */ 'views/editor/course/CourseEditView')`,

  'views/i18n/I18NHomeView': -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NHomeView')`,
  'views/i18n/I18NEditThangTypeView': -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditThangTypeView')`,
  'views/i18n/I18NEditComponentView': -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditComponentView')`,
  'views/i18n/I18NEditLevelView': -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditLevelView')`,
  'views/i18n/I18NEditAchievementView': -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditAchievementView')`,
  'views/i18n/I18NEditCampaignView': -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditCampaignView')`,
  'views/i18n/I18NEditPollView': -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditPollView')`,
  'views/i18n/I18NEditCourseView': -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditCourseView')`,
  'views/i18n/I18NEditProductView': -> `import(/* webpackChunkName: "i18n" */ 'views/i18n/I18NEditProductView')`,

  'views/LegalView': -> `import(/* webpackChunkName: "LegalView" */ 'views/LegalView')`,

  'views/ladder/LadderView': -> `import(/* webpackChunkName: "ladder" */ 'views/ladder/LadderView')`,
  'views/ladder/MainLadderView': -> `import(/* webpackChunkName: "ladder" */ 'views/ladder/MainLadderView')`,

  'views/NotFoundView': -> `import(/* webpackChunkName: "NotFoundView" */ 'views/NotFoundView')`,

  'views/play/CampaignView': -> `import(/* webpackChunkName: "play" */ 'views/play/CampaignView')`,
  'views/play/level/PlayLevelView': -> `import(/* webpackChunkName: "play" */ 'views/play/level/PlayLevelView')`,
  'views/play/level/PlayGameDevLevelView': -> `import(/* webpackChunkName: "play" */ 'views/play/level/PlayGameDevLevelView')`,
  'views/play/level/PlayWebDevLevelView': -> `import(/* webpackChunkName: "play" */ 'views/play/level/PlayWebDevLevelView')`,
  'views/play/SpectateView': -> `import(/* webpackChunkName: "play" */ 'views/play/SpectateView')`,

  'views/PremiumFeaturesView': -> `import(/* webpackChunkName: "PremiumFeaturesView" */ 'views/PremiumFeaturesView')`,

  'views/PrivacyView': -> `import(/* webpackChunkName: "PrivacyView" */ 'views/PrivacyView')`,

  'views/teachers/RestrictedToTeachersView': -> `import(/* webpackChunkName: "RestrictedToTeachersView" */ 'views/teachers/RestrictedToTeachersView')`,

  'views/courses/RestrictedToStudentsView': -> `import(/* webpackChunkName: "RestrictedToStudentsView" */ 'views/courses/RestrictedToStudentsView')`,

  'views/teachers/TeacherStudentView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/TeacherStudentView')`,
  'views/teachers/TeacherCourseSolutionView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/TeacherCourseSolutionView')`,
  'views/teachers/RequestQuoteView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/RequestQuoteView')`,
  'views/teachers/ResourceHubView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/ResourceHubView')`,
  'views/teachers/ApCsPrinciplesView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/ApCsPrinciplesView')`,
  'views/teachers/MarkdownResourceView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/MarkdownResourceView')`,
  'views/teachers/CreateTeacherAccountView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/CreateTeacherAccountView')`,
  'views/teachers/StarterLicenseUpsellView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/StarterLicenseUpsellView')`,
  'views/teachers/ConvertToTeacherAccountView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/ConvertToTeacherAccountView')`,
  'views/teachers/DynamicAPCSPView': -> `import(/* webpackChunkName: "teachers" */ 'views/teachers/DynamicAPCSPView')`,

  'views/TestView': -> `import(/* webpackChunkName: "TestView" */ 'views/TestView')`,

  'views/user/IdentifyView': -> `import(/* webpackChunkName: "user" */ 'views/user/IdentifyView')`,
  'views/user/MainUserView': -> `import(/* webpackChunkName: "user" */ 'views/user/MainUserView')`,
  'views/user/EmailVerifiedView': -> `import(/* webpackChunkName: "user" */ 'views/user/EmailVerifiedView')`,
}


# //      # when 'views/admin/DesignElementsView' then require.ensure(['views/admin/DesignElementsView'], ((require) -> accept(require('views/admin/DesignElementsView'))), reject, 'admin')
# //      # when 'views/admin/LevelSessionsView' then require.ensure(['views/admin/LevelSessionsView'], ((require) -> accept(require('views/admin/LevelSessionsView'))), reject, 'admin')
# //      # when 'views/artisans/ThangTasksView' then require.ensure(['views/artisans/ThangTasksView'], ((require) -> accept(require('views/artisans/ThangTasksView'))), reject, 'artisans')
# //      # when 'views/docs/ComponentsDocumentationView' then require.ensure(['views/docs/ComponentsDocumentationView'], ((require) -> accept(require('views/docs/ComponentsDocumentationView'))), reject, 'docs')
# //      # when 'views/docs/SystemsDocumentationView' then require.ensure(['views/docs/SystemsDocumentationView'], ((require) -> accept(require('views/docs/SystemsDocumentationView'))), reject, 'docs')
# //      # when 'views/editor/ThangTasksView' then require.ensure(['views/editor/ThangTasksView'], ((require) -> accept(require('views/editor/ThangTasksView'))), reject, 'editor')
