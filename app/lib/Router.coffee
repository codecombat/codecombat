gplusClientID = '800329290710-j9sivplv2gpcdgkrsis9rff3o417mlfa.apps.googleusercontent.com'
# TODO: Move to GPlusHandler

NotFoundView = require('views/NotFoundView')

go = (path) -> -> @routeDirectly path, arguments

module.exports = class CocoRouter extends Backbone.Router
  subscribe: ->
    Backbone.Mediator.subscribe 'gapi-loaded', @onGPlusAPILoaded, @
    Backbone.Mediator.subscribe 'router:navigate', @onNavigate, @

  routes:
    '': go('HomeView')

    'about': go('AboutView')
    'admin': go('AdminView')

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

    'demo(/*subpath)': go('DemoView')
    
    'editor': go('editor/MainEditorView')
    'employers': go('EmployersView')
    
    'legal': go('LegalView')
    
    'multiplayer': go('MultiplayerView')

    'play': go('play/MainPlayView')
    'preview': go('HomeView')

    'teachers': go('TeachersView')
    'test(/*subpath)': go('TestView')


    # editor views tend to have the same general structure
    'editor/:model(/:slug_or_id)(/:subview)': 'editorModelView'

    # Direct links


    'play/ladder/:levelID': go('play/ladder/ladder_view')
    'play/ladder': go('play/ladder_home')

    # db and file urls call the server directly
    'db/*path': 'routeToServer'
    'file/*path': 'routeToServer'

    # most go through here
    '*name': 'general'

  home:           -> @openRoute('home')
  general: (name) ->
    @openRoute(name)

  editorModelView: (modelName, slugOrId, subview) ->
    modulePrefix = "views/editor/#{modelName}/"
    suffix = subview or (if slugOrId then 'edit' else 'home')
    ViewClass = @tryToLoadModule(modulePrefix + suffix)
    unless ViewClass
      #console.log('could not hack it', modulePrefix + suffix)
      args = (a for a in arguments when a)
      args.splice(0, 0, 'editor')
      return @openRoute(args.join('/'))
    view = new ViewClass({}, slugOrId)
    view.render()
    @openView if view then view else @notFoundView()

  cache: {}
  openRoute: (route) ->
    route = route.split('?')[0]
    route = route.split('#')[0]
    view = @getViewFromCache(route)
    @openView(view)

  openView: (view) ->
    @closeCurrentView()
    $('#page-container').empty().append view.el
    window.currentView = view
    @activateTab()
    @renderLoginButtons()
    window.scrollTo(0, view.scrollY) if view.scrollY?
    view.afterInsert()
    view.didReappear() if view.fromCache

  onGPlusAPILoaded: =>
    @renderLoginButtons()

  renderLoginButtons: ->
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

  getViewFromCache: (route) ->
    if route of @cache
      @cache[route].fromCache = true
      return @cache[route]
    view = @getView(route)
    @cache[route] = view if view?.cache
    return view

  routeDirectly: (path, args) ->
    if window.currentView?.reloadOnClose
      return document.location.reload()
    path = "views/#{path}"
    ViewClass = @tryToLoadModule path
    return @openView @notFoundView() if not ViewClass
    view = new ViewClass({}, args...)  # options, then any path fragment args
    view.render()
    @openView(view)

  getView: (route, suffix='_view') ->
    # iteratively breaks down the url pieces looking for the view
    # passing the broken off pieces as args. This way views like 'resource/14394893'
    # will get passed to the resource view with arg '14394893'
    pieces = _.string.words(route, '/')
    split = Math.max(1, pieces.length-1)
    while split > -1
      sub_route = _.string.join('/', pieces[0..split]...)
      path = "views/#{sub_route}#{suffix}"
      ViewClass = @tryToLoadModule(path)
      break if ViewClass
      split -= 1

    return @notFoundView() if not ViewClass
    args = pieces[split+1..]
    view = new ViewClass({}, args...)  # options, then any path fragment args
    view.render()

  tryToLoadModule: (path) ->
    try
      return require(path)
    catch error
      if error.toString().search('Cannot find module "' + path + '" from') is -1
        throw error

  notFoundView: ->
    view = new NotFoundView()
    view.render()

  closeCurrentView: ->
    window.currentModal?.hide?()
    return unless window.currentView?
    if window.currentView.cache
      window.currentView.scrollY = window.scrollY
      window.currentView.willDisappear()
    else
      window.currentView.destroy()

  activateTab: ->
    base = _.string.words(document.location.pathname[1..], '/')[0]
    $("ul.nav li.#{base}").addClass('active')

  initialize: ->
    @cache = {}
    # http://nerds.airbnb.com/how-to-add-google-analytics-page-tracking-to-57536
    @bind 'route', @_trackPageView

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

  routeToServer: (e) ->
    window.location.href = window.location.href
