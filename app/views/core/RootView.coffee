# A root view is one that replaces everything else on the screen when it
# comes into being, as opposed to sub-views which get inserted into other views.

merge = require('lodash').merge

CocoView = require './CocoView'

{logoutUser, me} = require('core/auth')
locale = require 'locale/locale'

Achievement = require 'models/Achievement'
AchievementPopup = require 'views/core/AchievementPopup'
errors = require 'core/errors'
utils = require 'core/utils'
userUtils = require '../../lib/user-utils'

BackboneVueMetaBinding = require('app/core/BackboneVueMetaBinding').default
Navigation = require('app/components/common/Navigation.vue').default
Footer = require('app/components/common/Footer.vue').default
store = require 'core/store'

filterKeyboardEvents = (allowedEvents, func) ->
  return (splat...) ->
    e = splat[0]
    return unless e.keyCode in allowedEvents or not e.keyCode
    return func(splat...)

module.exports = class RootView extends CocoView
  showBackground: true

  events:
    'click #logout-button': 'logoutAccount'
    'click #nav-stop-spying-button': 'stopSpying'
    'click #nav-stop-switching-button': 'stopSwitching'
    'click #nav-student-mode': 'switchToStudentMode'
    'change .language-dropdown': 'onLanguageChanged'
    'click .language-dropdown li': 'onLanguageChanged'
    'click .toggle-fullscreen': 'toggleFullscreen'
    'click .signup-button': 'onClickSignupButton'
    'click .login-button': 'onClickLoginButton'
    'treema-error': 'onTreemaError'
    'click [data-i18n]': 'onClickTranslatedElement'
    'click .track-click-event': 'onTrackClickEvent'
    'click .dashboard-toggle-link': 'onClickDashboardToggleLink'

  subscriptions:
    'achievements:new': 'handleNewAchievements'

  shortcuts:
    'ctrl+shift+a': 'navigateToAdmin'

  initialize: (options) ->
    super(options)

    try
      @initializeMetaBinding()
    catch e
      console.error 'Failed to initialize meta binding', e

  showNewAchievement: (achievement, earnedAchievement) ->
    earnedAchievement.set('notified', true)
    earnedAchievement.patch()
    return if achievement.get('collection') is 'level.sessions' and not achievement.get('query')?.team
    #return if @isIE()  # Some bugs in IE right now, TODO fix soon!  # Maybe working now with not caching achievement fetches in CocoModel?
    return if window.serverConfig.picoCTF
    return if achievement.get('hidden')

    return if utils.isOzaria # Hiding legacy achievement popups in Ozaria
    new AchievementPopup achievement: achievement, earnedAchievement: earnedAchievement

  handleNewAchievements: (e) ->
    _.each e.earnedAchievements.models, (earnedAchievement) =>
      achievement = new Achievement(_id: earnedAchievement.get('achievement'))
      achievement.fetch
        success: (achievement) => @showNewAchievement?(achievement, earnedAchievement)
        cache: false

  logoutAccount: ->
    window?.webkit?.messageHandlers?.notification?.postMessage(name: "signOut") if application.isIPadApp
    Backbone.Mediator.publish("auth:logging-out", {})
    category = if utils.isCodeCombat then 'Homepage' else 'Home'
    window.tracker?.trackEvent 'Log Out', category: category if @id is 'home-view'
    if me.isTarena()
      logoutUser({
        success: ->
          window.location = "http://kidtts.tmooc.cn/ttsPage/login.html"
      })
    else
      logoutUser()

  stopSpying: ->
    me.stopSpying({
      success: -> document.location.reload()
      error: ->
        errors.showNotyNetworkError(arguments...)
    })

  stopSwitching: ->
    text = 'Switching to teacher account..'
    noty({ text, type: 'success', timeout: 5000, killer: true })
    me.switchToTeacherMode()
      .then(() -> document.location.reload())
      .catch((err) -> errors.showNotyNetworkError(err))

  switchToStudentMode: ->
    text = 'Switching to test student account..'
    noty({ text, type: 'success', timeout: 5000, killer: true })
    me.switchToStudentMode()
      .then(() -> window.location.reload())
      .catch((err) -> errors.showNotyNetworkError(err))

  onClickSignupButton: (e) ->
    CreateAccountModal = require 'views/core/CreateAccountModal'
    switch @id
      when 'home-view'
        properties = {
          category: if utils.isCodeCombat then 'Homepage' else 'Home'
        }
        window.tracker?.trackEvent('Started Signup', properties)
        eventAction = $(e.target)?.data('event-action')
        window.tracker?.trackEvent(eventAction, properties) if eventAction
      when 'world-map-view'
        # TODO: add campaign data
        window.tracker?.trackEvent 'Started Signup', category: 'World Map', label: 'World Map'
      else
        window.tracker?.trackEvent 'Started Signup', label: @id
    options = {}
    if userUtils.isInLibraryNetwork()
      options.startOnPath = 'individual'
    @openModalView new CreateAccountModal(options)

  onClickLoginButton: (e) ->
    loginMessage = e.target.dataset.loginMessage
    nextUrl = e.target.dataset.nextUrl
    AuthModal = require 'views/core/AuthModal'
    if @id is 'home-view'
      properties = { category: if utils.isCodeCombat then 'Homepage' else 'Home' }
      window.tracker?.trackEvent 'Login', properties

      eventAction = $(e.target)?.data('event-action')
      window.tracker?.trackEvent(eventAction, properties) if eventAction
    @openModalView new AuthModal({loginMessage, nextUrl})

  onTrackClickEvent: (e) ->
    eventAction = $(e.target)?.closest('a')?.data('event-action')
    if eventAction
      window.tracker?.trackEvent eventAction, { category: 'Teachers' }

  onClickDashboardToggleLink: (e) ->
    $(e.target)?.parent('.dashboard-button')?.addClass('active')
    $(e.target)?.parent('.dashboard-button')?.siblings('.dashboard-button')?.removeClass('active')

  showLoading: ($el) ->
    $el ?= @$el.find('#site-content-area')
    super($el)

  afterInsert: ->
    # force the browser to scroll to the hash
    # also messes with the browser history, so perhaps come up with a better solution
    super()
    #hash = location.hash
    #location.hash = ''
    #location.hash = hash
    @renderScrollbar()

    # Ensure navigation displays when visting SingletonAppVueComponentView.
    @initializeNavigation()

  afterRender: ->
    if @$el.find('#main-nav.legacy').length # hack...
      @$el.addClass('site-chrome')
      if @showBackground
        @$el.addClass('show-background')

    super(arguments...)
    @chooseTab(location.hash.replace('#', '')) if location.hash
    @buildLanguages()
    $('body').removeClass('is-playing')
    @initializeNavigation()

  chooseTab: (category) ->
    $("a[href='##{category}']", @$el).tab('show')

  # TODO: automate tabs to put in hashes when they are clicked

  buildLanguages: ->
    $select = @$el.find('.language-dropdown').empty()
    preferred = me.get('preferredLanguage', true)
    @addLanguagesToSelect($select, preferred)
    $('body').attr('lang', preferred)

  addLanguagesToSelect: ($select, initialVal) ->
    # For now, we only want to support a few languages for Ozaria that we have people working to translate.
    filteredLocale = locale
    codes = _.keys(filteredLocale)

    # Because we only support a few languages, we force English as the default here:
    initialVal ?= me.get('preferredLanguage', true)
    if utils.isOzaria and initialVal not in codes
      initialVal = 'en-US'

    if $select.is('ul') # base-flat
      @$el.find('.language-dropdown-current')?.text(locale[initialVal].nativeDescription)

    genericCodes = _.filter codes, (code) ->
      _.find(codes, (code2) ->
        code2 isnt code and code2.split('-')[0] is code)
    for code, localeInfo of filteredLocale when (not (code in genericCodes) or code is initialVal)
      if $select.is('ul') # base-flat template
        $select.append(
          $('<li data-code="' + code + '"><a class="language-dropdown-item" href="#">' + localeInfo.nativeDescription + '</a></li>'))
        if utils.isCodeCombat and code is 'pt-BR'
          $select.append($('<li role="separator" class="divider"</li>'))
      else # base template
        $select.append($('<option></option>').val(code).text(localeInfo.nativeDescription))
        if utils.isCodeCombat and code is 'pt-BR'
          $select.append(
            $('<option class="select-dash" disabled="disabled"></option>').text('----------------------------------'))
        $select.val(initialVal)

  onLanguageChanged: (event)->
    targetElem = $(event.currentTarget)
    if targetElem.is('li') # base-flat template
      newLang = targetElem.data('code')
      @$el.find('.language-dropdown-current')?.text(locale[newLang].nativeDescription)
    else # base template
      newLang = $('.language-dropdown').val()
    $.i18n.changeLanguage newLang, =>
      @saveLanguage(newLang)
      locale.load(me.get('preferredLanguage', true)).then =>
        @onLanguageLoaded()

  onLanguageLoaded: ->
    @render()
    unless utils.isOzaria or me.get('preferredLanguage').split('-')[0] is 'en' or me.hideDiplomatModal()
      DiplomatModal = require 'views/core/DiplomatSuggestionModal'
      @openModalView(new DiplomatModal())

  saveLanguage: (newLang) ->
    me.set('preferredLanguage', newLang)
    res = me.patch()
    return unless res
    res.error ->
      errors = JSON.parse(res.responseText)
      console.warn 'Error saving language:', errors
    res.success (model, response, options) ->
      #console.log 'Saved language:', newLang

  isOldBrowser: utils.isOldBrowser

  isChinaOldBrowser: utils.isChinaOldBrowser

  logoutRedirectURL: '/'

  navigateToAdmin: ->
    if window.serverSession.amActually or me.isAdmin()
      application.router.navigate('/admin', {trigger: true})

  onTreemaError: (e) ->
    noty text: e.message, layout: 'topCenter', type: 'error', killer: false, timeout: 5000, dismissQueue: true

  # Initialize the binding to vue-meta by initializing a Vue component that sets the head tags
  # on render.  This binding will be destroyed via the Vue component's $destory method when
  # this view is destroyed.  Views can specify @skipMetaBinding = true when they want to manage
  # head tags in their own way.  This is useful for legacy Vue components that eventually inherit
  # from RootView (ie RootComponent and VueComponentView).  These views can use vue-meta directly
  # within their Vue components.
  initializeMetaBinding: ->
    if @metaBinding
      return @metaBinding

    # Set a noop meta binding object when the view opts to skip meta binding
    if @skipMetaBinding
      return @metaBinding = {
        $destroy: ->
        setMeta: ->
      }

    legacyTitle = @getTitle()
    if localStorage?.showViewNames
      legacyTitle = @constructor.name

    # Create an empty, mounted element so that the vue component actually renders and runs vue-meta
    @metaBinding = new BackboneVueMetaBinding({
      el: document.createElement('div'),
      propsData: {
        baseMeta: @getMeta(),
        legacyTitle: legacyTitle
      }
    })

  # Attach the navigation Vue component to the page
  initializeNavigation: ->
    if staticNav = document.querySelector('#main-nav')
      if @navigation
        staticNav.replaceWith(@navigation.$el)
      else
        @navigation = new Navigation { el: staticNav, store }
        # Hack - It would be better for the Navigation component to manage the language dropdown.
        _.defer => @buildLanguages?()
    if staticFooter = document.querySelector('#site-footer')
      if @footer
        staticFooter.replaceWith(@footer.$el)
      else
        @footer = new Footer { el: staticFooter, store }

  # Set the page title when the view is loaded.  This value is merged into the
  # result of getMeta.  It will override any title specified in getMeta.  Kept
  # for backwards compatibility
  getTitle: -> ''

  # Head tag configuration used to configure vue-meta when the View is loaded.
  # See https://vue-meta.nuxtjs.org/ for available configuration options.  This
  # can be later modified by calling setMeta
  getMeta: -> {
    title: $.i18n.t ('new_home.title' + if features?.chinaHome then '_cn_home' else '_coco')
  }

  # Allow async updates of the view's meta configuration.  This can be used in addition to getMeta
  # to update meta configuration when the meta configuration is computed asynchronously
  setMeta: (meta) ->
    @metaBinding.setMeta(meta)

  destroy: ->
    @metaBinding?.$destroy()
    @navigation?.$destroy()
    @footer?.$destroy()
    super()
