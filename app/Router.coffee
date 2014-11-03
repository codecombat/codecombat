gplusClientID = '800329290710-j9sivplv2gpcdgkrsis9rff3o417mlfa.apps.googleusercontent.com'
# TODO: Move to GPlusHandler

NotFoundView = require('views/NotFoundView')

go = (path) -> -> @routeDirectly path, arguments

module.exports = class CocoRouter extends Backbone.Router

  initialize: ->
    # http://nerds.airbnb.com/how-to-add-google-analytics-page-tracking-to-57536
    @bind 'route', @_trackPageView
    Backbone.Mediator.subscribe 'auth:gplus-api-loaded', @onGPlusAPILoaded, @
    Backbone.Mediator.subscribe 'router:navigate', @onNavigate, @
    @initializeSocialMediaServices = _.once @initializeSocialMediaServices

  routes:
    '': go('HomeView')  # This will go somewhere deprecated when FrontView is done.
    'front': go('FrontView')  # This will become '' when it is done.

    'about': go('AboutView')

    'account': go('account/MainAccountView')
    'account/settings': go('account/AccountSettingsView')
    'account/unsubscribe': go('account/UnsubscribeView')
    'account/profile': go('user/JobProfileView')  # legacy URL, sent in emails
    #'account/payment'

    'admin': go('admin/MainAdminView')
    'admin/candidates': go('admin/CandidatesView')
    'admin/clas': go('admin/CLAsView')
    'admin/employers': go('admin/EmployersListView')
    'admin/files': go('admin/FilesView')
    'admin/level-sessions': go('admin/LevelSessionsView')
    'admin/users': go('admin/UsersView')
    'admin/base': go('admin/BaseView')
    'admin/user-code-problems': go('admin/UserCodeProblemsView')

    'beta': go('HomeView')

    'cla': go('CLAView')
    'community': go('CommunityView')

    'contribute': go('contribute/MainContributeView')
    'contribute/adventurer': go('contribute/AdventurerView')
    'contribute/ambassador': go('contribute/AmbassadorView')
    'contribute/archmage': go('contribute/ArchmageView')
    'contribute/artisan': go('contribute/ArtisanView')
    'contribute/diplomat': go('contribute/DiplomatView')
    'contribute/scribe': go('contribute/ScribeView')

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

    'employers': go('EmployersView')

    'file/*path': 'routeToServer'

    'github/*path': 'routeToServer'

    'i18n': go('i18n/I18NHomeView')
    'i18n/thang/:handle': go('i18n/I18NEditThangTypeView')
    'i18n/component/:handle': go('i18n/I18NEditComponentView')
    'i18n/level/:handle': go('i18n/I18NEditLevelView')
    'i18n/achievement/:handle': go('i18n/I18NEditAchievementView')

    'legal': go('LegalView')

    'multiplayer': go('MultiplayerView')

    'play-old': go('play/MainPlayView')  # This used to be 'play'.
    'play': go('play/WorldMapView')
    'play-hero': go('play/WorldMapView')  # Legacy URL for /play; leave up until start of 2015, I guess.
    'play/ladder/:levelID': go('play/ladder/LadderView')
    'play/ladder': go('play/ladder/MainLadderView')
    'play/level/:levelID': go('play/level/PlayLevelView')
    'play/spectate/:levelID': go('play/SpectateView')
    'play/:map': go('play/WorldMapView')

    'preview': go('HomeView')

    'teachers': go('TeachersView')

    'test(/*subpath)': go('TestView')

    'user/:slugOrID': go('user/MainUserView')
    'user/:slugOrID/stats': go('user/AchievementsView')
    'user/:slugOrID/profile': go('user/JobProfileView')
    #'user/:slugOrID/code': go('user/CodeView')

    '*name': 'showNotFoundView'

  routeToServer: (e) ->
    window.location.href = window.location.href

  routeDirectly: (path, args) ->
    path = "views/#{path}"
    ViewClass = @tryToLoadModule path
    return @openView @notFoundView() if not ViewClass
    view = new ViewClass({}, args...)  # options, then any path fragment args
    view.render()
    @openView(view)

  tryToLoadModule: (path) ->
    try
      return require(path)
    catch error
      if error.toString().search('Cannot find module "' + path + '" from') is -1
        throw error

  showNotFoundView: ->
    @openView @notFoundView()

  notFoundView: ->
    view = new NotFoundView()
    view.render()

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

  onGPlusAPILoaded: =>
    @renderLoginButtons()

  initializeSocialMediaServices: ->
    return if application.testing or application.demoing
    services = [
      './lib/services/facebook'
      './lib/services/google'
      './lib/services/twitter'
      './lib/services/linkedin'
    ]

    for service in services
      service = require service
      service()

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
        scope: 'https://www.googleapis.com/auth/plus.login https://www.googleapis.com/auth/userinfo.email',
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
    manualView = e.view or e.viewClass
    @navigate e.route, {trigger: not manualView}
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
