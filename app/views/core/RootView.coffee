# A root view is one that replaces everything else on the screen when it
# comes into being, as opposed to sub-views which get inserted into other views.

CocoView = require './CocoView'

{logoutUser, me} = require('core/auth')
locale = require 'locale/locale'

Achievement = require 'models/Achievement'
AchievementPopup = require 'views/core/AchievementPopup'
utils = require 'core/utils'

# TODO remove

filterKeyboardEvents = (allowedEvents, func) ->
  return (splat...) ->
    e = splat[0]
    return unless e.keyCode in allowedEvents or not e.keyCode
    return func(splat...)

module.exports = class RootView extends CocoView
  showBackground: true

  events:
    'click #logout-button': 'logoutAccount'
    'change .language-dropdown': 'onLanguageChanged'
    'click .toggle-fullscreen': 'toggleFullscreen'
    'click .signup-button': 'onClickSignupButton'
    'click .login-button': 'onClickLoginButton'
    'click a': 'onClickAnchor'
    'click button': 'toggleModal'
    'click li': 'toggleModal'

  subscriptions:
    'achievements:new': 'handleNewAchievements'
    'modal:open-modal-view': 'onOpenModalView'

  showNewAchievement: (achievement, earnedAchievement) ->
    earnedAchievement.set('notified', true)
    earnedAchievement.patch()
    return if achievement.get('collection') is 'level.sessions'
    #return if @isIE()  # Some bugs in IE right now, TODO fix soon!  # Maybe working now with not caching achievement fetches in CocoModel?
    new AchievementPopup achievement: achievement, earnedAchievement: earnedAchievement

  handleNewAchievements: (e) ->
    _.each e.earnedAchievements.models, (earnedAchievement) =>
      achievement = new Achievement(_id: earnedAchievement.get('achievement'))
      achievement.fetch
        success: (achievement) => @showNewAchievement?(achievement, earnedAchievement)
        cache: false

  logoutAccount: ->
    window?.webkit?.messageHandlers?.notification?.postMessage(name: "signOut") if window.application.isIPadApp
    Backbone.Mediator.publish("auth:logging-out", {})
    window.tracker?.trackEvent 'Log Out', category:'Homepage', ['Google Analytics'] if @id is 'home-view'
    logoutUser($('#login-email').val())

  onClickSignupButton: ->
    AuthModal = require 'views/core/AuthModal'
    switch @id
      when 'home-view'
        window.tracker?.trackEvent 'Started Signup', category: 'Homepage', label: 'Homepage'
      when 'world-map-view'
        # TODO: add campaign data
        window.tracker?.trackEvent 'Started Signup', category: 'World Map', label: 'World Map'
      else
        window.tracker?.trackEvent 'Started Signup', label: @id
    @openModalView new AuthModal {mode: 'signup'}

  onClickLoginButton: ->
    AuthModal = require 'views/core/AuthModal'
    window.tracker?.trackEvent 'Login', category: 'Homepage', ['Google Analytics'] if @id is 'home-view'
    @openModalView new AuthModal {mode: 'login'}

  onClickAnchor: (e) ->
    return if @destroyed
    anchorText = e?.currentTarget?.text
    window.tracker?.trackEvent anchorText, category: 'Homepage', ['Google Analytics'] if @id is 'home-view' and anchorText
    @toggleModal e

  onOpenModalView: (e) ->
    return console.error "Couldn't find modalPath #{e.modalPath}" unless e.modalPath and ModalClass = require e.modalPath
    @openModalView new ModalClass {}

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

  getRenderData: ->
    c = super()
    c.usesSocialMedia = @usesSocialMedia
    c

  afterRender: ->
    if @$el.find('#site-nav').length # hack...
      @$el.addClass('site-chrome')
      if @showBackground
        @$el.addClass('show-background')

    super(arguments...)
    @chooseTab(location.hash.replace('#', '')) if location.hash
    @buildLanguages()
    $('body').removeClass('is-playing')

    if application.isProduction()
      title = 'CodeCombat - ' + (@getTitle() or 'Learn how to code by playing a game')
    else
      title = @getTitle() or @constructor.name

    $('title').text(title)

  getTitle: -> ''

  chooseTab: (category) ->
    $("a[href='##{category}']", @$el).tab('show')

  # TODO: automate tabs to put in hashes when they are clicked

  buildLanguages: ->
    $select = @$el.find('.language-dropdown').empty()
    preferred = me.get('preferredLanguage', true)
    @addLanguagesToSelect($select, preferred)
    $('body').attr('lang', preferred)

  addLanguagesToSelect: ($select, initialVal) ->
    initialVal ?= me.get('preferredLanguage', true)
    codes = _.keys(locale)
    genericCodes = _.filter codes, (code) ->
      _.find(codes, (code2) ->
        code2 isnt code and code2.split('-')[0] is code)
    for code, localeInfo of locale when code isnt 'update' and (not (code in genericCodes) or code is initialVal)
      $select.append(
        $('<option></option>').val(code).text(localeInfo.nativeDescription))
      if code is 'fr'
        $select.append(
          $('<option class="select-dash" disabled="disabled"></option>').text('----------------------------------'))
    $select.val(initialVal)

  onLanguageChanged: ->
    newLang = $('.language-dropdown').val()
    $.i18n.setLng(newLang, {})
    @saveLanguage(newLang)

    loading = application.moduleLoader.loadLanguage(me.get('preferredLanguage', true))
    if loading
      @listenToOnce application.moduleLoader, 'load-complete', @onLanguageLoaded
    else
      @onLanguageLoaded()

  onLanguageLoaded: ->
    @render()
    unless me.get('preferredLanguage').split('-')[0] is 'en'
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
