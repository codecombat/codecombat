gplusClientID = '800329290710-j9sivplv2gpcdgkrsis9rff3o417mlfa.apps.googleusercontent.com'
# TODO: Move to GPlusHandler

go = (path) -> -> @routeDirectly path, arguments

module.exports = class CocoRouter extends Backbone.Router

  initialize: ->
    # http://nerds.airbnb.com/how-to-add-google-analytics-page-tracking-to-57536
    @bind 'route', @_trackPageView
    Backbone.Mediator.subscribe 'auth:gplus-api-loaded', @onGPlusAPILoaded, @
    Backbone.Mediator.subscribe 'router:navigate', @onNavigate, @
    @initializeSocialMediaServices = _.once @initializeSocialMediaServices

  routes:
    '': ->
      if window.serverConfig.picoCTF
        return @routeDirectly 'play/CampaignView', ['picoctf'], {}
      # Testing new home page
      group = me.getHomepageGroup()
      return @routeDirectly('HomeView', [], { withTeacherNote: true }) if group is 'home-with-note'
      return @routeDirectly('NewHomeView', [], { jumbotron: 'student' }) if group is 'new-home-student'
      return @routeDirectly('NewHomeView', [], { jumbotron: 'characters' }) if group is 'new-home-characters'
      return @routeDirectly('HomeView', [])

    'about': go('AboutView')

    'account': go('account/MainAccountView')
    'account/settings': go('account/AccountSettingsRootView')
    'account/unsubscribe': go('account/UnsubscribeView')
    'account/payments': go('account/PaymentsView')
    'account/subscription': go('account/SubscriptionView')
    'account/invoices': go('account/InvoicesView')
    'account/prepaid': go('account/PrepaidView')

    'admin': go('admin/MainAdminView')
    'admin/clas': go('admin/CLAsView')
    'admin/design-elements': go('admin/DesignElementsView')
    'admin/files': go('admin/FilesView')
    'admin/analytics': go('admin/AnalyticsView')
    'admin/analytics/subscriptions': go('admin/AnalyticsSubscriptionsView')
    'admin/level-sessions': go('admin/LevelSessionsView')
    'admin/users': go('admin/UsersView')
    'admin/base': go('admin/BaseView')
    'admin/trial-requests': go('admin/TrialRequestsView')
    'admin/user-code-problems': go('admin/UserCodeProblemsView')
    'admin/pending-patches': go('admin/PendingPatchesView')

    'beta': go('HomeView')

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

    'courses': go('courses/CoursesView')
    'Courses': go('courses/CoursesView')
    'courses/students': go('courses/StudentCoursesView')
    'courses/teachers': go('courses/TeacherCoursesView')
    'courses/purchase': go('courses/PurchaseCoursesView')
    'courses/enroll(/:courseID)': go('courses/CourseEnrollView')
    'courses/:classroomID': go('courses/ClassroomView')
    'courses/:courseID/:courseInstanceID': go('courses/CourseDetailsView')

    'db/*path': 'routeToServer'
    'demo(/*subpath)': go('DemoView')
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

    'file/*path': 'routeToServer'

    'github/*path': 'routeToServer'

    'hoc': go('courses/HourOfCodeView')
    'home': go('NewHomeView')

    'i18n': go('i18n/I18NHomeView')
    'i18n/thang/:handle': go('i18n/I18NEditThangTypeView')
    'i18n/component/:handle': go('i18n/I18NEditComponentView')
    'i18n/level/:handle': go('i18n/I18NEditLevelView')
    'i18n/achievement/:handle': go('i18n/I18NEditAchievementView')
    'i18n/campaign/:handle': go('i18n/I18NEditCampaignView')
    'i18n/poll/:handle': go('i18n/I18NEditPollView')

    'identify': go('user/IdentifyView')

    'legal': go('LegalView')

    'multiplayer': go('MultiplayerView')

    'play(/)': go('play/CampaignView') # extra slash is to get Facebook app to work
    'play/ladder/:levelID/:leagueType/:leagueID': go('ladder/LadderView')
    'play/ladder/:levelID': go('ladder/LadderView')
    'play/ladder': go('ladder/MainLadderView')
    'play/level/:levelID': go('play/level/PlayLevelView')
    'play/spectate/:levelID': go('play/SpectateView')
    'play/:map': go('play/CampaignView')

    'preview': go('HomeView')

    'privacy': go('PrivacyView')

    'schools': go('NewHomeView')

    'teachers': go('NewHomeView')
    'teachers/freetrial': go('RequestQuoteView')
    'teachers/quote': go('RequestQuoteView')

    'test(/*subpath)': go('TestView')

    'user/:slugOrID': go('user/MainUserView')

    '*name/': 'removeTrailingSlash'
    '*name': go('NotFoundView')

  routeToServer: (e) ->
    window.location.href = window.location.href

  removeTrailingSlash: (e) ->
    @navigate e, {trigger: true}

  routeDirectly: (path, args, options={}) ->
    path = 'play/CampaignView' if window.serverConfig.picoCTF and not /^(views)?\/?play/.test(path)
    path = "views/#{path}" if not _.string.startsWith(path, 'views/')
    ViewClass = @tryToLoadModule path
    if not ViewClass and application.moduleLoader.load(path)
      @listenToOnce application.moduleLoader, 'load-complete', ->
        @routeDirectly(path, args, options)
      return
    return @openView @notFoundView() if not ViewClass
    view = new ViewClass(options, args...)  # options, then any path fragment args
    view.render()
    @openView(view)

  tryToLoadModule: (path) ->
    try
      return require(path)
    catch error
      if error.toString().search('Cannot find module "' + path + '" from') is -1
        throw error

  openView: (view) ->
    @closeCurrentView()
    $('#page-container').empty().append view.el
    window.currentView = view
    @activateTab()
    @renderLoginButtons() if view.usesSocialMedia
    view.afterInsert()
    view.didReappear()

  closeCurrentView: ->
    if window.currentView?.reloadOnClose
      return document.location.reload()
    window.currentModal?.hide?()
    return unless window.currentView?
    window.currentView.destroy()
    $('.popover').popover 'hide'
    $('#flying-focus').css({top: 0, left: 0}) # otherwise it might make the page unnecessarily tall
    _.delay (-> 
      $('html')[0].scrollTop = 0
      $('body')[0].scrollTop = 0
    ), 10

  onGPlusAPILoaded: =>
    @renderLoginButtons()

  initializeSocialMediaServices: ->
    return if application.testing or application.demoing
    require('core/services/facebook')()
    require('core/services/google')()
    require('core/services/twitter')()

  renderLoginButtons: =>
    @initializeSocialMediaServices()
    $('.share-buttons, .partner-badges').addClass('fade-in').delay(10000).removeClass('fade-in', 5000)
    setTimeout(FB.XFBML.parse, 10) if FB?.XFBML?.parse  # Handles FB login and Like
    twttr?.widgets?.load?()

    return unless gapi?.plusone?
    gapi.plusone.go?()  # Handles +1 button
    for gplusButton in $('.gplus-login-button')
      params = {
        callback: 'signinCallback',
        clientid: gplusClientID,
        cookiepolicy: 'single_host_origin',
        scope: 'https://www.googleapis.com/auth/plus.login email',
        height: 'short',
      }
      if gapi.signin?.render
        gapi.signin.render(gplusButton, params)
      else
        console.warn 'Didn\'t have gapi.signin to render G+ login button. (DoNotTrackMe extension?)'

  activateTab: ->
    base = _.string.words(document.location.pathname[1..], '/')[0]
    $("ul.nav li.#{base}").addClass('active')

  _trackPageView: ->
    window.tracker?.trackPageView()

  onNavigate: (e) ->
    if _.isString e.viewClass
      ViewClass = @tryToLoadModule e.viewClass
      if not ViewClass and application.moduleLoader.load(e.viewClass)
        @listenToOnce application.moduleLoader, 'load-complete', ->
          @onNavigate(e)
        return
      e.viewClass = ViewClass

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
    else
      @openView e.view

  navigate: (fragment, options) ->
    super fragment, options
    Backbone.Mediator.publish 'router:navigated', route: fragment
